package com.example.salik_management_system.core.sync

import android.util.Log
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserRole
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.auth.LocalAuthStore
import com.example.salik_management_system.core.crypto.FieldCryptoKeyStore
import com.example.salik_management_system.core.data.SeedService
import com.example.salik_management_system.core.data.kAreas
import com.example.salik_management_system.core.data.kBazams
import com.example.salik_management_system.core.database.LocalAreaDao
import com.example.salik_management_system.core.database.LocalBazamDao
import com.example.salik_management_system.core.database.LocalSalikDao
import com.example.salik_management_system.core.database.SyncQueueDao
import com.example.salik_management_system.core.database.SyncQueueEntity
import com.example.salik_management_system.core.database.SyncStatus
import com.example.salik_management_system.core.database.decodeSyncPayload
import com.example.salik_management_system.core.network.ConnectivityService
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.core.utils.AppLog
import com.example.salik_management_system.features.saliks.data.mapper.toDomain
import com.example.salik_management_system.features.saliks.data.mapper.toEntity
import com.example.salik_management_system.features.saliks.domain.model.Area
import com.example.salik_management_system.features.saliks.domain.model.Bazam
import com.example.salik_management_system.features.saliks.domain.model.Salik
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

data class SyncResult(
    val ok: Boolean,
    val message: String,
)

@Singleton
class SyncService @Inject constructor(
    private val connectivity: ConnectivityService,
    private val authRepo: AuthRepository,
    private val localAuth: LocalAuthStore,
    private val keyStore: FieldCryptoKeyStore,
    private val seedService: SeedService,
    private val salikDao: LocalSalikDao,
    private val areaDao: LocalAreaDao,
    private val bazamDao: LocalBazamDao,
    private val syncQueueDao: SyncQueueDao,
    private val firestore: FirebaseFirestore,
    private val auth: FirebaseAuth,
) {
    private val mutex = Mutex()

    @Volatile
    var lastSyncError: String? = null
        private set

    val pendingCount: Flow<Int> = syncQueueDao.watchPendingCount()

    suspend fun syncNow(sessionOverride: UserSession? = null): SyncResult = mutex.withLock {
        if (!connectivity.isOnline) {
            AppLog.w(TAG, "Sync aborted: Device offline")
            return SyncResult(false, "Offline — connect to sync")
        }
        AppLog.i(TAG, "Starting sync...")
        lastSyncError = null
        return try {
            purgeLocalStaleQueue()
            authRepo.promoteOfflineSessionIfOnline()

            val sessionHint = sessionOverride ?: currentSession()
            if (sessionHint == null) {
                AppLog.w(TAG, "Sync aborted: No active session")
                return SyncResult(false, "No local session")
            }

            val authed = localAuth.refreshFirebaseAuth(auth, preferredEmail = sessionHint.email)
            if (!authed) {
                AppLog.e(TAG, "Sync aborted: Firebase re-auth failed")
                return SyncResult(false, "Firebase login failed")
            }

            val session = ensureUserProfile(sessionHint)
                ?: return SyncResult(false, "User profile missing")

            keyStore.ensureKey(session)
            adoptRemoteApprovals()
            pushQueue(session)
            finalizeSyncQueue()
            pullFromFirestore(session)
            finalizeSyncQueue()

            if (session.role == UserRole.Admin) {
                runCatching { seedService.seedIfNeeded() }
                    .onFailure { AppLog.e(TAG, "Seed failed", it) }
            }

            val remaining = syncQueueDao.pendingCount()
            if (remaining > 0) {
                val pendingItems = syncQueueDao.pendingItems()
                val details = pendingItems.joinToString { "${it.collection}/${it.operation}/${it.docId}" }
                lastSyncError = "syncQueue: $remaining item(s) still pending [$details]"
                AppLog.w(TAG, "Sync finished with pending items: $remaining. Details: $details")
                SyncResult(false, lastSyncError!!)
            } else {
                AppLog.i(TAG, "Sync completed successfully")
                SyncResult(true, "Sync complete")
            }
        } catch (e: Exception) {
            lastSyncError = e.message ?: e.toString()
            AppLog.e(TAG, "Sync failed: $lastSyncError", e)
            SyncResult(false, lastSyncError ?: "Sync failed")
        } finally {
            purgeLocalStaleQueue()
        }
    }

    private suspend fun ensureUserProfile(session: UserSession?): UserSession? {
        if (auth.currentUser == null) return session
        val email = LocalAuthStore.normalizeEmail(
            auth.currentUser?.email ?: session?.email.orEmpty(),
        )
        val hint = session ?: localAuth.getUserByEmail(email) ?: return null
        return try {
            authRepo.syncUserProfileWithFirebase(hint)
        } catch (e: Exception) {
            Log.d(TAG, "Profile sync failed: $e")
            null
        }
    }

    private suspend fun pushQueue(session: UserSession) {
        val priority = mapOf("bazams" to 0, "areas" to 1, "saliks" to 2)
        val items = syncQueueDao.pendingItems().sortedWith(
            compareBy<SyncQueueEntity> { priority[it.collection] ?: 9 }
                .thenBy { it.id },
        )
        for (item in items) {
            try {
                when (item.collection) {
                    "saliks" -> {
                        if (!canPushSalik(item, session)) {
                            AppLog.d(TAG, "Skipping salik push for ${item.docId} (permission/gender filter)")
                            if (AccessControl.isEditor(session.role)) {
                                syncQueueDao.deleteById(item.id)
                            }
                            continue
                        }
                        AppLog.d(TAG, "Attempting push for salik ${item.docId}")
                        val pushed = pushSalikFromLocal(item, session)
                        if (!pushed) {
                            AppLog.d(TAG, "Salik ${item.docId} already synced or not found, deleting from queue")
                            val local = salikDao.getById(item.docId)
                            if (local == null || local.syncStatus == SyncStatus.synced) {
                                syncQueueDao.deleteById(item.id)
                            }
                        }
                    }
                    "areas" -> {
                        val payload = item.payloadJson.decodeSyncPayload()
                        pushArea(item.operation, item.docId, payload)
                        syncQueueDao.deleteById(item.id)
                    }
                    "bazams" -> {
                        val payload = item.payloadJson.decodeSyncPayload()
                        pushBazam(item.operation, item.docId, payload)
                        syncQueueDao.deleteById(item.id)
                    }
                }
            } catch (e: Exception) {
                AppLog.e(TAG, "Push failed ${item.collection}/${item.operation}/${item.docId}: ${e.message}", e)
                syncQueueDao.updateError(item.id, e.toString(), item.retryCount + 1)
            }
        }
    }

    private suspend fun canPushSalik(item: SyncQueueEntity, session: UserSession): Boolean {
        val local = salikDao.getById(item.docId) ?: return false
        val salik = local.toDomain()
        val gender = AccessControl.genderFilter(session)
        if (gender != null && salik.genderId != gender) return false
        if (AccessControl.isEditor(session.role)) {
            return salik.isPending && item.operation == "create"
        }
        if (item.operation == "delete" && !AccessControl.canDelete(session.role)) return false
        return AccessControl.canApprove(session.role) || AccessControl.canUpdate(session.role)
    }

    private suspend fun pushSalikFromLocal(item: SyncQueueEntity, session: UserSession): Boolean {
        val local = salikDao.getById(item.docId) ?: return false
        if (local.syncStatus == SyncStatus.synced) return false
        val localSalik = local.toDomain()
        if (AccessControl.isEditor(session.role) && !localSalik.isPending) {
            syncQueueDao.deleteById(item.id)
            return false
        }
        if (localSalik.isPending) {
            if (adoptServerApproval(item.docId)) return false
        }
        var operation = when (local.syncStatus) {
            SyncStatus.pendingCreate -> "create"
            SyncStatus.pendingDelete -> "delete"
            else -> "update"
        }
        if (operation == "create" && !AccessControl.isEditor(session.role)) {
            val exists = firestore.collection("saliks").document(item.docId).get().await()
            if (exists.exists()) operation = "update"
        }
        if (AccessControl.isEditor(session.role) && operation != "create") {
            syncQueueDao.deleteById(item.id)
            return false
        }
        pushSalik(operation, item.docId, salikPayloadForPush(localSalik))
        syncQueueDao.deleteById(item.id)
        return true
    }

    private fun salikPayloadForPush(salik: Salik): Map<String, Any?> {
        var push = salik
        val authUid = auth.currentUser?.uid
        if (!authUid.isNullOrEmpty()) {
            push = when {
                salik.isPending -> salik.copy(addedByUid = authUid)
                salik.approvedByUid.isEmpty() || salik.approvedByUid.startsWith("local-") ->
                    salik.copy(approvedByUid = authUid)
                else -> salik
            }
        }
        val map = push.toMap().filterValues { it != null }.toMutableMap()
        val crypto = keyStore.current ?: return map
        return crypto.encryptSalikMap(map)
    }

    private fun salikFromFirestore(data: Map<String, Any?>, id: String): Salik {
        val crypto = keyStore.current
        val map = if (crypto == null) data else crypto.decryptSalikMap(data)
        return Salik.fromMap(map, id = id)
    }

    private suspend fun pushSalik(operation: String, docId: String, payload: Map<String, Any?>) {
        val clean = payload.filterValues { it != null }
        val ref = firestore.collection("saliks").document(docId)
        AppLog.d(TAG, "Pushing salik ($operation): $docId")
        
        try {
            when (operation) {
                "create" -> {
                    val existing = ref.get().await()
                    if (existing.exists()) {
                        val server = salikFromFirestore(existing.data.orEmpty().toAnyMap(), docId)
                        if (server.isPending) {
                            AppLog.i(TAG, "Salik $docId exists on server but is pending. Caching server version.")
                            cacheSalik(server)
                            return
                        }
                        AppLog.w(TAG, "Critical: Attempted to CREATE salik $docId but it already exists on server.")
                        // If it exists and is approved, just sync it locally
                        cacheSalik(server)
                        return
                    }
                    ref.set(clean).await()
                    cacheSalik(salikFromFirestore(clean, docId))
                }
                "update" -> {
                    ref.set(clean, SetOptions.merge()).await()
                    cacheSalik(salikFromFirestore(clean, docId))
                }
                "delete" -> {
                    val archive = clean.toMutableMap()
                    if (archive.isEmpty()) {
                        val existing = ref.get().await()
                        if (existing.exists()) {
                            archive.putAll(existing.data.orEmpty().toAnyMap())
                        }
                    }
                    archive["salikId"] = docId
                    archive["deletedAt"] = Timestamp.now()
                    auth.currentUser?.uid?.let { archive["deletedByUid"] = it }
                    firestore.collection("delete_saliks").document(docId).set(archive).await()
                    ref.delete().await()
                    salikDao.deleteById(docId)
                    syncQueueDao.deleteForDoc("saliks", docId)
                    AppLog.i(TAG, "Salik $docId deleted from server and local.")
                }
            }
        } catch (e: Exception) {
            AppLog.e(TAG, "Firestore push failed for $docId: ${e.message}", e)
            throw e
        }
    }

    private suspend fun pushArea(operation: String, docId: String, payload: Map<String, Any?>) {
        val ref = firestore.collection("areas").document(docId)
        when (operation) {
            "create" -> {
                ref.set(payload).await()
                areaDao.upsert(Area.fromMap(payload, docId).toEntity(SyncStatus.synced))
            }
            "update" -> {
                ref.set(payload, SetOptions.merge()).await()
                areaDao.upsert(Area.fromMap(payload, docId).toEntity(SyncStatus.synced))
            }
            "delete" -> ref.delete().await()
        }
    }

    private suspend fun pushBazam(operation: String, docId: String, payload: Map<String, Any?>) {
        val ref = firestore.collection("bazams").document(docId)
        when (operation) {
            "create" -> {
                ref.set(payload).await()
                bazamDao.upsert(Bazam.fromMap(payload, docId).toEntity(SyncStatus.synced))
            }
            "update" -> {
                ref.set(payload, SetOptions.merge()).await()
                bazamDao.upsert(Bazam.fromMap(payload, docId).toEntity(SyncStatus.synced))
            }
            "delete" -> {
                ref.delete().await()
                bazamDao.deleteById(docId)
            }
        }
    }

    private suspend fun pullFromFirestore(session: UserSession) {
        pullBazams()
        pullAreas()
        pullSaliks(session)
    }

    private suspend fun pullBazams() {
        val snapshot = firestore.collection("bazams").get().await()
        val serverIds = mutableSetOf<String>()
        if (snapshot.isEmpty) {
            for (bazam in kBazams) {
                bazamDao.upsert(bazam.toEntity())
            }
            return
        }
        for (doc in snapshot.documents) {
            val data = doc.data.orEmpty().toAnyMap()
            if (data["isActive"] == false) continue
            serverIds += doc.id
            runCatching {
                val bazam = Bazam.fromMap(data, id = doc.id)
                bazamDao.upsert(bazam.toEntity())
            }.onFailure { Log.d(TAG, "Skip bazam ${doc.id}: $it") }
        }
        for (row in bazamDao.getAll()) {
            if (row.syncStatus != SyncStatus.synced) continue
            if (row.bazamId !in serverIds) bazamDao.deleteById(row.bazamId)
        }
    }

    private suspend fun pullAreas() {
        val snapshot = firestore.collection("areas").get().await()
        val serverIds = mutableSetOf<String>()
        if (snapshot.isEmpty) {
            for (area in kAreas) areaDao.upsert(area.toEntity())
            return
        }
        for (doc in snapshot.documents) {
            val data = doc.data.orEmpty().toAnyMap()
            if (data["isActive"] == false) continue
            serverIds += doc.id
            runCatching {
                areaDao.upsert(Area.fromMap(data, id = doc.id).toEntity())
            }.onFailure { Log.d(TAG, "Skip area ${doc.id}: $it") }
        }
        for (row in areaDao.getAll()) {
            if (row.syncStatus != SyncStatus.synced) continue
            if (row.areaId !in serverIds) areaDao.deleteById(row.areaId)
        }
    }

    private suspend fun pullSaliks(session: UserSession) {
        val gender = AccessControl.genderFilter(session)
        val snapshot = if (gender != null) {
            firestore.collection("saliks").whereEqualTo("genderId", gender).get().await()
        } else {
            firestore.collection("saliks").get().await()
        }
        val serverIds = mutableSetOf<String>()
        for (doc in snapshot.documents) {
            serverIds += doc.id
            val server = salikFromFirestore(doc.data.orEmpty().toAnyMap(), doc.id)
            mergeSalikFromServer(server)
        }
        for (row in salikDao.getAll(genderFilter = gender)) {
            if (row.syncStatus != SyncStatus.synced) continue
            if (row.salikId !in serverIds) salikDao.deleteById(row.salikId)
        }
    }

    private suspend fun mergeSalikFromServer(server: Salik) {
        val local = salikDao.getById(server.salikId)
        if (local != null && local.syncStatus != SyncStatus.synced) {
            val localSalik = local.toDomain()
            if (!localSalik.isPending && server.isPending) return
            if (localSalik.isPending && !server.isPending) cacheSalik(server)
            return
        }
        cacheSalik(server)
    }

    private suspend fun cacheSalik(salik: Salik) {
        salikDao.upsert(salik.toEntity(SyncStatus.synced))
        syncQueueDao.deleteForDoc("saliks", salik.salikId)
    }

    private suspend fun adoptRemoteApprovals() {
        val pending = salikDao.getAll(approvalStatus = "pending")
        for (row in pending) adoptServerApproval(row.salikId)
    }

    private suspend fun adoptServerApproval(salikId: String): Boolean {
        val local = salikDao.getById(salikId) ?: return false
        if (!local.toDomain().isPending) return false
        return try {
            val snap = firestore.collection("saliks").document(salikId).get().await()
            if (!snap.exists()) return false
            val server = salikFromFirestore(snap.data.orEmpty().toAnyMap(), salikId)
            if (server.isPending) return false
            cacheSalik(server)
            true
        } catch (e: Exception) {
            Log.d(TAG, "Adopt approval $salikId: $e")
            false
        }
    }

    private suspend fun purgeLocalStaleQueue() {
        for (row in salikDao.getAll()) {
            if (row.syncStatus == SyncStatus.synced) {
                syncQueueDao.deleteForDoc("saliks", row.salikId)
            }
        }
        for (row in areaDao.getAll()) {
            if (row.syncStatus == SyncStatus.synced) {
                syncQueueDao.deleteForDoc("areas", row.areaId)
            }
        }
        for (row in bazamDao.getAll()) {
            if (row.syncStatus == SyncStatus.synced) {
                syncQueueDao.deleteForDoc("bazams", row.bazamId)
            }
        }
    }

    private suspend fun finalizeSyncQueue() {
        purgeLocalStaleQueue()
        for (item in syncQueueDao.pendingItems()) {
            when (item.collection) {
                "saliks" -> {
                    val local = salikDao.getById(item.docId)
                    if (local == null || local.syncStatus == SyncStatus.synced) {
                        syncQueueDao.deleteForDoc("saliks", item.docId)
                    }
                }
                "areas" -> {
                    val local = areaDao.getById(item.docId)
                    if (local?.syncStatus == SyncStatus.synced) {
                        syncQueueDao.deleteForDoc("areas", item.docId)
                    }
                }
                "bazams" -> {
                    val local = bazamDao.getById(item.docId)
                    if (local?.syncStatus == SyncStatus.synced) {
                        syncQueueDao.deleteForDoc("bazams", item.docId)
                    }
                }
                else -> syncQueueDao.deleteById(item.id)
            }
        }
    }

    private suspend fun currentSession(): UserSession? {
        val user = auth.currentUser
        if (user != null) {
            localAuth.getUserByUid(user.uid)?.let { return it }
            user.email?.let { localAuth.getUserByEmail(it)?.let { s -> return s } }
        }
        return localAuth.getActiveOfflineSession() ?: authRepo.session.value
    }

    companion object {
        private const val TAG = "SyncService"
    }
}

@Suppress("UNCHECKED_CAST")
private fun Map<String, Any>.toAnyMap(): Map<String, Any?> =
    mapValues { (_, v) -> v as Any? }
