package com.example.salik_management_system.features.saliks.data

import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.auth.LocalAuthStore
import com.example.salik_management_system.core.database.LocalSalikDao
import com.example.salik_management_system.core.database.SyncQueueDao
import com.example.salik_management_system.core.database.SyncStatus
import com.example.salik_management_system.core.database.enqueueSync
import com.example.salik_management_system.core.network.ConnectivityService
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.features.saliks.domain.ApprovalStatus
import com.example.salik_management_system.features.saliks.domain.DuplicateSalikException
import com.example.salik_management_system.features.saliks.domain.DuplicateSalikReason
import com.example.salik_management_system.features.saliks.domain.Salik
import com.example.salik_management_system.features.saliks.domain.SalikDuplicateGroup
import com.example.salik_management_system.features.saliks.domain.SalikPermissionException
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
    private val auth: AuthRepository,
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
        watchAll(session).map { list -> list.filter { it.isApproved } }

    fun watchPending(session: UserSession?): Flow<List<Salik>> {
        if (session == null || !AccessControl.canViewPending(session.role)) {
            return kotlinx.coroutines.flow.flowOf(emptyList())
        }
        val gender = AccessControl.genderFilter(session)
        return salikDao.watchAll(genderFilter = gender).map { rows ->
            val saliks = rows.map { it.toDomain() }
            if (AccessControl.isEditor(session.role)) {
                saliks.filter { (it.isPending || it.isRejected) && editorOwnsSalik(it, session) }
            } else {
                saliks.filter { it.isPending }
            }
        }
    }

    fun watchDirectory(session: UserSession?): Flow<List<Salik>> {
        if (session == null) return watchApproved(null)
        if (AccessControl.isEditor(session.role)) {
            return watchAll(session).map { list ->
                list.filter {
                    it.isApproved || (it.isPending && editorOwnsSalik(it, session))
                }.sortedWith(compareByDescending { it.isPending })
            }
        }
        return watchApproved(session)
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
        findDuplicate(salik, session)?.let { throw DuplicateSalikException(it) }

        val id = salik.salikId.ifEmpty { UUID.randomUUID().toString() }
        val creatorName = session?.name?.trim()?.ifEmpty { null } ?: salik.addedByName
        val isEditor = session != null && AccessControl.isEditor(session.role)
        val now = LocalDate.now().toString()
        val saved = salik.copy(
            salikId = id,
            addedByUid = session?.uid ?: salik.addedByUid,
            addedByName = creatorName,
            approvalStatus = if (isEditor) ApprovalStatus.Pending else ApprovalStatus.Approved,
            isActive = !isEditor,
            approvedByUid = if (isEditor) "" else (session?.uid ?: ""),
            approvedByName = if (isEditor) "" else creatorName,
            approvedAt = if (isEditor) "" else java.time.Instant.now().toString(),
            createdDate = salik.createdDate.ifEmpty { now },
            modifiedDate = now,
        )
        persist(saved, SyncStatus.pendingCreate)
        return id
    }

    suspend fun update(salik: Salik, session: UserSession?) {
        if (session != null && !AccessControl.canUpdate(session.role)) {
            throw SalikPermissionException("Cannot update salik")
        }
        ensureLocal(salik.salikId)
        val existing = salikDao.getById(salik.salikId) ?: return
        if (existing.approvalStatus == ApprovalStatus.Pending.toFirestore() &&
            session != null &&
            !AccessControl.canApprove(session.role)
        ) {
            throw SalikPermissionException("Cannot edit pending salik")
        }
        findDuplicate(salik, session, excludeSalikId = salik.salikId)?.let {
            throw DuplicateSalikException(it)
        }
        val status =
            if (existing.syncStatus == SyncStatus.pendingCreate) SyncStatus.pendingCreate
            else SyncStatus.pendingUpdate
        val preserved = salik.copy(
            addedByUid = existing.addedByUid,
            addedByName = existing.addedByName,
            approvalStatus = ApprovalStatus.fromString(existing.approvalStatus),
            approvedByUid = existing.approvedByUid,
            approvedByName = existing.approvedByName,
            approvedAt = existing.approvedAt,
            modifiedDate = LocalDate.now().toString(),
        )
        persist(preserved, status)
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
        findDuplicate(salik, session, excludeSalikId = id)?.let {
            throw DuplicateSalikException(it)
        }
        val approved = salik.copy(
            approvalStatus = ApprovalStatus.Approved,
            isActive = true,
            approvedByUid = session.uid,
            approvedByName = displayName(session),
            approvedAt = java.time.Instant.now().toString(),
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
            approvedAt = java.time.Instant.now().toString(),
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
        var existing = salikDao.getById(id)
        if (existing == null) {
            ensureLocal(id)
            existing = salikDao.getById(id) ?: return
        }
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
        ensureLocal(id)
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
        session: UserSession?,
        excludeSalikId: String? = null,
    ): DuplicateSalikReason? {
        val mobile = normalizePhone(candidate.mobileNumber)
        val name = candidate.name.trim().lowercase()
        val father = candidate.fatherName.trim().lowercase()
        val checkName = name.isNotEmpty() && father.isNotEmpty()
        val rows = salikDao.getAll(
            genderFilter = AccessControl.genderFilter(session),
            approvalStatus = ApprovalStatus.Approved.toFirestore(),
        )
        for (row in rows) {
            if (excludeSalikId != null && row.salikId == excludeSalikId) continue
            val salik = row.toDomain()
            if (mobile.isNotEmpty() && normalizePhone(salik.mobileNumber) == mobile) {
                return DuplicateSalikReason.Mobile
            }
            if (checkName &&
                salik.name.trim().lowercase() == name &&
                salik.fatherName.trim().lowercase() == father
            ) {
                return DuplicateSalikReason.Name
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

        fun genderFilterHelper(session: UserSession?): String? =
            AccessControl.genderFilter(session)

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
            referenceMobile = keep.referenceMobile.ifBlank { other.referenceMobile },
            dateOfBaith = keep.dateOfBaith.ifBlank { other.dateOfBaith },
            bazamId = keep.bazamId.ifBlank { other.bazamId },
            isNafiAsbat = keep.isNafiAsbat || other.isNafiAsbat,
            isSahibEMehfil = keep.isSahibEMehfil || other.isSahibEMehfil,
            notes = keep.notes ?: other.notes,
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
