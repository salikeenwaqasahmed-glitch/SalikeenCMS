package com.example.salik_management_system.features.saliks.data.repository

import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserRole
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.auth.LocalAuthStore
import com.example.salik_management_system.core.database.LocalSalikDao
import com.example.salik_management_system.core.database.SyncQueueDao
import com.example.salik_management_system.core.database.SyncStatus
import com.example.salik_management_system.core.database.enqueueSync
import com.example.salik_management_system.core.network.ConnectivityService
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.core.utils.AppLog
import com.example.salik_management_system.features.saliks.data.mapper.toDomain
import com.example.salik_management_system.features.saliks.data.mapper.toEntity
import com.example.salik_management_system.features.saliks.domain.model.ApprovalStatus
import com.example.salik_management_system.features.saliks.domain.model.DuplicateSalikException
import com.example.salik_management_system.features.saliks.domain.model.DuplicateSalikReason
import com.example.salik_management_system.features.saliks.domain.model.Salik
import com.example.salik_management_system.features.saliks.domain.model.SalikDuplicateGroup
import com.example.salik_management_system.features.saliks.domain.model.SalikPermissionException
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.tasks.await
import java.time.LocalDate
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SalikRepository @Inject constructor(
    private val salikDao: LocalSalikDao,
    private val syncQueueDao: SyncQueueDao,
    private val connectivity: ConnectivityService,
    private val authRepository: AuthRepository,
    private val firestore: FirebaseFirestore,
) {
    fun watchAll(
        session: UserSession?,
        approvalStatus: String? = null,
    ): Flow<List<Salik>> {
        val gender = AccessControl.genderFilter(session)
        return salikDao.watchAll(
            genderFilter = gender,
            approvalStatus = approvalStatus,
        ).map { rows -> rows.map { it.toDomain() } }
    }

    fun watchApproved(session: UserSession?): Flow<List<Salik>> =
        watchAll(session, approvalStatus = "approved")

    fun watchPending(session: UserSession?): Flow<List<Salik>> {
        if (session == null || !AccessControl.canViewPending(session.role)) {
            return kotlinx.coroutines.flow.flowOf(emptyList())
        }
        val gender = AccessControl.genderFilter(session)
        return salikDao.watchAll(genderFilter = gender).map { rows ->
            val saliks = rows.map { it.toDomain() }
            if (AccessControl.isEditor(session.role)) {
                // Editors only see their own pending/rejected records
                saliks.filter { (it.isPending || it.isRejected) && editorOwnsSalik(it, session) }
            } else {
                // Approvers and Admins see all pending records in their scope
                saliks.filter { it.isPending }
            }
        }
    }

    fun watchDirectory(session: UserSession?): Flow<List<Salik>> {
        if (session == null) return watchApproved(null)
        if (AccessControl.isEditor(session.role)) {
            return watchAll(session).map { list ->
                list.filter {
                    it.isApproved || (it.isPending && editorOwnsSalik(it, session)) || (it.isRejected && editorOwnsSalik(it, session))
                }.sortedWith(compareByDescending { it.isPending })
            }
        }
        return watchAll(session)
    }

    suspend fun searchDirectory(query: String): List<Salik> {
        val q = query.trim()
        if (q.isEmpty()) return emptyList()
        // Simple FTS formatting: append * for prefix search
        val ftsQuery = q.split(" ").filter { it.isNotBlank() }.joinToString(" ") { "$it*" }
        return try {
            salikDao.search(ftsQuery).map { it.toDomain() }
        } catch (e: Exception) {
            AppLog.e("SalikRepo", "FTS Search failed: ${e.message}")
            emptyList()
        }
    }

    suspend fun getById(id: String): Salik? {
        val row = salikDao.getById(id) ?: return null
        if (row.syncStatus == SyncStatus.pendingDelete) return null
        return row.toDomain()
    }

    fun watchById(id: String): Flow<Salik?> =
        salikDao.watchById(id).map { row ->
            if (row == null || row.syncStatus == SyncStatus.pendingDelete) null
            else row.toDomain()
        }

    suspend fun create(salik: Salik, session: UserSession?): String {
        if (session != null && !AccessControl.canCreate(session.role)) {
            throw SalikPermissionException("Cannot create salik")
        }
        findDuplicate(salik)?.let { throw DuplicateSalikException(it) }

        val id = salik.salikId.ifEmpty { UUID.randomUUID().toString() }
        val creatorName = session?.name?.trim()?.ifEmpty { null } ?: salik.addedByName
        val isEditor = session != null && AccessControl.isEditor(session.role)
        val now = LocalDate.now().toString()
        
        val saved = salik.copy(
            salikId = id,
            addedByUid = session?.uid ?: salik.addedByUid,
            addedByName = creatorName,
            // Editors create in Pending status, Approval/Admin create in Approved status
            approvalStatus = if (isEditor) ApprovalStatus.Pending else ApprovalStatus.Approved,
            isActive = !isEditor,
            approvedByUid = if (isEditor) "" else (session?.uid ?: ""),
            approvedByName = if (isEditor) "" else creatorName,
            approvedAt = if (isEditor) "" else now,
            createdDate = salik.createdDate.ifEmpty { now },
            modifiedDate = now,
        )
        persist(saved, SyncStatus.pendingCreate)
        return id
    }

    suspend fun update(salik: Salik, session: UserSession?) {
        AppLog.d("SalikRepository", "Updating salik: ${salik.salikId} (${salik.name})")
        
        val existingRow = salikDao.getById(salik.salikId)
        if (existingRow == null) {
            AppLog.e("SalikRepository", "Update failed: Salik ${salik.salikId} not found in DB")
            return
        }
        val existing = existingRow.toDomain()

        // Check Permissions
        if (session != null) {
            val gender = AccessControl.genderFilter(session)
            if (gender != null && existing.genderId != gender) {
                throw SalikPermissionException("Cannot edit record of different gender")
            }

            if (AccessControl.isEditor(session.role)) {
                // Editor can only edit their own records that are not yet approved
                if (!editorOwnsSalik(existing, session)) {
                    throw SalikPermissionException("Cannot edit records you didn't add")
                }
                if (existing.isApproved) {
                    throw SalikPermissionException("Cannot edit already approved record")
                }
            } else if (!AccessControl.canUpdate(session.role)) {
                throw SalikPermissionException("Permission denied")
            }
        }
        
        val duplicate = findDuplicate(salik, excludeSalikId = salik.salikId)
        if (duplicate != null) {
            AppLog.w("SalikRepository", "Update blocked: Duplicate found ($duplicate) for ${salik.salikId}")
            throw DuplicateSalikException(duplicate)
        }
        
        val status =
            if (existingRow.syncStatus == SyncStatus.pendingCreate) SyncStatus.pendingCreate
            else SyncStatus.pendingUpdate
            
        val updated = existing.copy(
            name = salik.name,
            fatherName = salik.fatherName,
            mobileNumber = salik.mobileNumber,
            whatsappNumber = salik.whatsappNumber,
            areaId = salik.areaId,
            address = salik.address,
            genderId = salik.genderId,
            bazamId = salik.bazamId,
            dateOfBaith = salik.dateOfBaith,
            referenceName = salik.referenceName,
            isNafiAsbat = salik.isNafiAsbat,
            isSahibEMehfil = salik.isSahibEMehfil,
            modifiedDate = LocalDate.now().toString(),
            // If an editor updates a rejected record, move it back to pending
            approvalStatus = if (session != null && AccessControl.isEditor(session.role) && existing.isRejected) 
                ApprovalStatus.Pending else existing.approvalStatus
        )
        persist(updated, status)
        AppLog.i("SalikRepository", "Successfully persisted update for ${salik.salikId}")
    }

    suspend fun approve(id: String, session: UserSession) {
        if (!AccessControl.canApprove(session.role)) {
            throw SalikPermissionException("Cannot approve salik")
        }
        val existing = salikDao.getById(id) ?: throw SalikPermissionException("Salik not found")
        val salik = existing.toDomain()
        
        if (!salik.isPending) throw SalikPermissionException("Salik is not pending")
        
        val gender = AccessControl.genderFilter(session)
        if (gender != null && salik.genderId != gender) {
            throw SalikPermissionException("Gender scope mismatch")
        }
        
        findDuplicate(salik, excludeSalikId = id)?.let {
            throw DuplicateSalikException(it)
        }
        
        val approved = salik.copy(
            approvalStatus = ApprovalStatus.Approved,
            isActive = true,
            approvedByUid = session.uid,
            approvedByName = displayName(session),
            approvedAt = LocalDate.now().toString(),
            modifiedDate = LocalDate.now().toString(),
        )
        val wasNeverSynced = existing.syncStatus == SyncStatus.pendingCreate
        val syncStatus = if (wasNeverSynced) SyncStatus.pendingCreate else SyncStatus.pendingUpdate
        val operation = if (wasNeverSynced) "create" else "update"
        
        syncQueueDao.deleteForDoc("saliks", id)
        salikDao.upsert(approved.toEntity(syncStatus))
        syncQueueDao.enqueueSync("saliks", operation, id, approved.toMap())
    }

    suspend fun reject(id: String, session: UserSession) {
        if (!AccessControl.canApprove(session.role)) {
            throw SalikPermissionException("Cannot reject salik")
        }
        val existing = salikDao.getById(id) ?: throw SalikPermissionException("Salik not found")
        val salik = existing.toDomain()
        
        if (!salik.isPending) throw SalikPermissionException("Salik is not pending")
        
        val gender = AccessControl.genderFilter(session)
        if (gender != null && salik.genderId != gender) {
            throw SalikPermissionException("Gender scope mismatch")
        }
        
        val rejected = salik.copy(
            approvalStatus = ApprovalStatus.Rejected,
            isActive = false,
            approvedByUid = session.uid,
            approvedByName = displayName(session),
            approvedAt = LocalDate.now().toString(),
            modifiedDate = LocalDate.now().toString(),
        )
        val wasNeverSynced = existing.syncStatus == SyncStatus.pendingCreate
        val syncStatus = if (wasNeverSynced) SyncStatus.pendingCreate else SyncStatus.pendingUpdate
        val operation = if (wasNeverSynced) "create" else "update"
        
        syncQueueDao.deleteForDoc("saliks", id)
        salikDao.upsert(rejected.toEntity(syncStatus))
        syncQueueDao.enqueueSync("saliks", operation, id, rejected.toMap())
    }

    suspend fun delete(
        id: String,
        session: UserSession?,
        duplicateCleanup: Boolean = false,
    ) {
        if (session != null) {
            val allowed = if (duplicateCleanup) {
                AccessControl.canResolveDuplicates(session.role)
            } else {
                AccessControl.canDelete(session.role)
            }
            if (!allowed) throw SalikPermissionException("Cannot delete salik")
        }
        val existing = salikDao.getById(id) ?: return

        if (existing.syncStatus == SyncStatus.pendingCreate) {
            salikDao.deleteById(id)
            syncQueueDao.deleteForDoc("saliks", id)
            return
        }
        salikDao.upsert(existing.toDomain().toEntity(SyncStatus.pendingDelete))
        syncQueueDao.enqueueSync("saliks", "delete", id, mapOf("salikId" to id))
    }

    suspend fun toggleActive(id: String, isActive: Boolean, session: UserSession?) {
        if (session != null && !AccessControl.canUpdate(session.role)) {
            throw SalikPermissionException("Cannot update salik")
        }
        val existing = salikDao.getById(id) ?: return
        if (existing.approvalStatus != ApprovalStatus.Approved.toFirestore()) {
            throw SalikPermissionException("Cannot toggle inactive pending salik")
        }
        update(
            existing.toDomain().copy(
                isActive = isActive,
                modifiedDate = LocalDate.now().toString(),
            ),
            session,
        )
    }

    suspend fun findDuplicate(
        candidate: Salik,
        excludeSalikId: String? = null,
    ): DuplicateSalikReason? {
        val mobile = normalizePhone(candidate.mobileNumber)
        val name = candidate.name.trim().lowercase()
        val father = candidate.fatherName.trim().lowercase()
        val checkName = name.isNotEmpty() && father.isNotEmpty()

        // Load the record we are currently editing to see what it looked like before
        val existing = excludeSalikId?.let { salikDao.getById(it)?.toDomain() }

        AppLog.d("SalikRepository", "findDuplicate: Name='$name', Mobile='$mobile' (Exclude ID: $excludeSalikId)")

        val rows = salikDao.getAll()
        for (row in rows) {
            // Skip the record being edited
            if (excludeSalikId != null && row.salikId == excludeSalikId) continue
            // Skip records marked for deletion
            if (row.syncStatus == SyncStatus.pendingDelete) continue

            val other = row.toDomain()
            val otherMobile = normalizePhone(other.mobileNumber)
            val otherName = other.name.trim().lowercase()
            val otherFather = other.fatherName.trim().lowercase()
            
            // 1. Check Mobile Collision
            if (mobile.isNotEmpty() && otherMobile == mobile) {
                val isMobileUnchanged = existing != null && normalizePhone(existing.mobileNumber) == mobile
                if (!isMobileUnchanged) {
                    AppLog.w("SalikRepository", "Mobile collision found with ID=${row.salikId} (Name: ${other.name})")
                    return DuplicateSalikReason.Mobile
                }
            }
            
            // 2. Check Name + Father Collision
            if (checkName && otherName == name && otherFather == father) {
                val isNameUnchanged = existing != null && 
                        existing.name.trim().lowercase() == name && 
                        existing.fatherName.trim().lowercase() == father
                
                if (!isNameUnchanged) {
                    AppLog.w("SalikRepository", "Name/Father collision found with ID=${row.salikId} (Mobile: ${other.mobileNumber})")
                    return DuplicateSalikReason.Name
                }
            }
        }
        return null
    }

    fun watchDuplicateGroups(session: UserSession?): Flow<List<SalikDuplicateGroup>> {
        if (session == null || !AccessControl.canResolveDuplicates(session.role)) {
            return kotlinx.coroutines.flow.flowOf(emptyList())
        }
        return watchAll(session).map { saliks ->
            findDuplicateGroups(saliks.filter { !it.isRejected })
        }
    }

    suspend fun mergeDuplicates(
        session: UserSession,
        keepSalikId: String,
        removeSalikIds: List<String>,
    ) {
        if (!AccessControl.canResolveDuplicates(session.role)) {
            throw SalikPermissionException("Cannot resolve duplicates")
        }
        val keeper = getById(keepSalikId) ?: throw SalikPermissionException("Salik not found")
        val gender = AccessControl.genderFilter(session)
        if (gender != null && keeper.genderId != gender) {
            throw SalikPermissionException("Gender scope mismatch")
        }
        var merged = keeper
        val toRemove = mutableListOf<String>()
        for (id in removeSalikIds) {
            if (id == keepSalikId) continue
            val other = getById(id) ?: continue
            if (gender != null && other.genderId != gender) continue
            merged = mergeRecords(merged, other)
            toRemove += id
        }
        if (toRemove.isEmpty()) return
        update(merged, session)
        for (id in toRemove) {
            delete(id, session, duplicateCleanup = true)
        }
    }

    private suspend fun persist(salik: Salik, syncStatus: String) {
        syncQueueDao.deleteForDoc("saliks", salik.salikId)
        salikDao.upsert(salik.toEntity(syncStatus))
        val operation = if (syncStatus == SyncStatus.pendingCreate) "create" else "update"
        syncQueueDao.enqueueSync("saliks", operation, salik.salikId, salik.toMap())
    }

    private suspend fun ensureLocal(id: String) {
        if (salikDao.getById(id) != null) return
        if (!connectivity.isOnline) return
        try {
            val snap = firestore.collection("saliks").document(id).get().await()
            if (!snap.exists()) return
            val data = snap.data ?: return
            val salik = Salik.fromMap(firestoreMap(data), id = id)
            salikDao.upsert(salik.toEntity(SyncStatus.pendingUpdate))
        } catch (_: Exception) {
        }
    }

    private fun displayName(session: UserSession): String {
        session.name.trim().ifEmpty { null }?.let { return it }
        val local = LocalAuthStore.normalizeEmail(session.email).substringBefore("@")
        return local.ifEmpty { "Approver" }
    }

    companion object {
        fun normalizePhone(phone: String): String =
            phone.replace(Regex("[^0-9]"), "")

        fun editorOwnsSalik(salik: Salik, session: UserSession): Boolean {
            val email = LocalAuthStore.normalizeEmail(session.email)
            val localUid = "local-$email"
            if (salik.addedByUid == session.uid || salik.addedByUid == localUid) return true
            val addedByName = salik.addedByName.trim()
            return addedByName.isNotEmpty() && addedByName == session.name.trim()
        }

        fun firestoreMap(data: Map<String, Any>): Map<String, Any?> =
            data.mapValues { (_, v) -> v }

        fun mergeRecords(keep: Salik, other: Salik): Salik = keep.copy(
            name = keep.name.ifBlank { other.name },
            fatherName = keep.fatherName.ifBlank { other.fatherName },
            mobileNumber = keep.mobileNumber.ifBlank { other.mobileNumber },
            whatsappNumber = keep.whatsappNumber.ifBlank { other.whatsappNumber },
            areaId = keep.areaId.ifBlank { other.areaId },
            address = keep.address.ifBlank { other.address },
            referenceName = keep.referenceName.ifBlank { other.referenceName },
            dateOfBaith = keep.dateOfBaith.ifBlank { other.dateOfBaith },
            bazamId = keep.bazamId.ifBlank { other.bazamId },
            isNafiAsbat = keep.isNafiAsbat || other.isNafiAsbat,
            isSahibEMehfil = keep.isSahibEMehfil || other.isSahibEMehfil,
        )

        fun findDuplicateGroups(saliks: List<Salik>): List<SalikDuplicateGroup> {
            if (saliks.size < 2) return emptyList()
            val byMobile = saliks
                .filter { normalizePhone(it.mobileNumber).isNotEmpty() }
                .groupBy { normalizePhone(it.mobileNumber) }
                .filter { it.value.size >= 2 }
            return byMobile.map { (mobile, members) ->
                val sorted = members.sortedBy { it.createdDate }
                SalikDuplicateGroup(
                    id = sorted.joinToString("|") { it.salikId },
                    reasons = setOf(DuplicateSalikReason.Mobile),
                    label = mobile,
                    saliks = sorted,
                )
            }.sortedBy { it.label }
        }
    }
}
