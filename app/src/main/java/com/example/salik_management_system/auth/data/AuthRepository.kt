package com.example.salik_management_system.auth.data

import android.util.Log
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.auth.LocalAuthStore
import com.example.salik_management_system.core.auth.NoLocalUserOfflineException
import com.example.salik_management_system.core.auth.OfflineWrongPasswordException
import com.example.salik_management_system.core.network.ConnectivityService
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.core.utils.AppLog
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeout
import javax.inject.Inject
import javax.inject.Singleton

class ProfileNotFoundException : Exception()
class FirebaseAuthFailedException(val email: String) : Exception("Firebase auth failed for $email")

@Singleton
class AuthRepository @Inject constructor(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore,
    private val localAuth: LocalAuthStore,
    private val connectivity: ConnectivityService,
) {
    private val _session = MutableStateFlow<UserSession?>(null)
    val session: StateFlow<UserSession?> = _session.asStateFlow()

    private val _sessionUpdates = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val sessionUpdates: SharedFlow<Unit> = _sessionUpdates.asSharedFlow()

    @Volatile
    var isOfflineSession: Boolean = false
        private set

    @Volatile
    var isLoginAttemptInProgress: Boolean = false
        private set

    private var pinnedSession: UserSession? = null
    private var stickySession: UserSession? = null

    val currentUser: FirebaseUser?
        get() = auth.currentUser

    fun pinSession(session: UserSession) {
        pinnedSession = session
    }

    fun unpinSession() {
        pinnedSession = null
        notifySessionChanged()
    }

    private fun notifySessionChanged() {
        _sessionUpdates.tryEmit(Unit)
    }

    private fun commitSession(session: UserSession?): UserSession? {
        if (session != null) stickySession = session
        _session.value = session
        return session
    }

    private fun finalizeOnlineSession(profile: UserSession, password: String?): UserSession {
        if (password != null) {
            localAuth.rememberLogin(profile.email, password)
        }
        localAuth.setActiveOfflineUid(profile.uid)
        isOfflineSession = false
        maybeNotifySessionChanged(profile)
        return commitSession(profile)!!
    }

    private fun maybeNotifySessionChanged(profile: UserSession) {
        val prev = stickySession
        if (prev != null && prev.uid == profile.uid && prev.email == profile.email) {
            stickySession = profile
            _session.value = profile
            return
        }
        stickySession = profile
        _session.value = profile
        notifySessionChanged()
    }

    suspend fun fetchSession(): UserSession? {
        return try {
            withTimeout(FETCH_SESSION_TIMEOUT_MS) {
                fetchSessionInternal()
            }
        } catch (e: TimeoutCancellationException) {
            AppLog.w(TAG, "fetchSession timed out; using cached session if any")
            cachedSessionFallback()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            AppLog.e(TAG, "fetchSession failed: ${e.message}", e)
            cachedSessionFallback()
        }
    }

    private fun cachedSessionFallback(): UserSession? {
        pinnedSession?.let { return commitSession(it) }
        stickySession?.let { return it }
        return _session.value
    }

    private suspend fun fetchSessionInternal(): UserSession? {
        pinnedSession?.let { return commitSession(it) }

        if (isOfflineSession) {
            return commitSession(localAuth.getActiveOfflineSession())
        }

        val offlineSession = localAuth.getActiveOfflineSession()
        var firebaseUser = auth.currentUser
        val rememberedEmail = localAuth.getRememberedEmail()

        if (firebaseUser == null &&
            offlineSession == null &&
            rememberedEmail.isNullOrEmpty()
        ) {
            stickySession = null
            _session.value = null
            return null
        }

        if (isLoginAttemptInProgress) {
            stickySession = null
            _session.value = null
            return null
        }

        if (connectivity.isOnline) {
            try {
                if (!rememberedEmail.isNullOrEmpty()) {
                    val firebaseEmail = firebaseUser?.email?.let { LocalAuthStore.normalizeEmail(it) }.orEmpty()
                    if (firebaseEmail != rememberedEmail) {
                        localAuth.refreshFirebaseAuth(auth, preferredEmail = rememberedEmail)
                        firebaseUser = auth.currentUser
                    }
                } else if (firebaseUser != null) {
                    auth.signOut()
                    firebaseUser = null
                }
            } catch (e: Exception) {
                Log.d(TAG, "fetchSession re-auth failed: $e")
                if (firebaseUser != null) {
                    auth.signOut()
                    firebaseUser = null
                }
            }
        }

        if (offlineSession != null) {
            val offlineEmail = LocalAuthStore.normalizeEmail(offlineSession.email)
            val firebaseEmail = firebaseUser?.email?.let { LocalAuthStore.normalizeEmail(it) }.orEmpty()
            if (firebaseUser == null || firebaseEmail != offlineEmail) {
                if (connectivity.isOnline) {
                    val restored = localAuth.refreshFirebaseAuth(
                        auth,
                        preferredEmail = offlineSession.email,
                    )
                    if (restored) {
                        firebaseUser = auth.currentUser
                        if (firebaseUser != null &&
                            LocalAuthStore.normalizeEmail(firebaseUser.email.orEmpty()) == offlineEmail
                        ) {
                            localAuth.clearActiveOfflineUid()
                            isOfflineSession = false
                        }
                    }
                }
                if (firebaseUser == null ||
                    LocalAuthStore.normalizeEmail(firebaseUser.email.orEmpty()) != offlineEmail
                ) {
                    isOfflineSession = true
                    return commitSession(offlineSession)
                }
            }
        }

        if (firebaseUser != null) {
            isOfflineSession = false
            val firebaseUid = firebaseUser.uid
            val local = localAuth.getUserByUid(firebaseUid)
            if (local != null) {
                if (connectivity.isOnline) {
                    val doc = firestore.collection("users").document(firebaseUid).get().await()
                    if (!doc.exists()) {
                        return commitSession(syncUserProfileWithFirebase(local))
                    }
                }
                return commitSession(local)
            }
            if (connectivity.isOnline) {
                val doc = firestore.collection("users").document(firebaseUid).get().await()
                if (doc.exists()) {
                    val data = doc.data.orEmpty()
                    val session = UserSession.fromMap(firebaseUid, data)
                    localAuth.saveUser(session)
                    return commitSession(session)
                }
                val email = LocalAuthStore.normalizeEmail(firebaseUser.email.orEmpty())
                val source = profileSourceForEmail(email)
                if (source != null) {
                    return commitSession(
                        syncUserProfileWithFirebase(
                            UserSession(
                                uid = firebaseUid,
                                name = source.name,
                                email = email,
                                role = source.role,
                                gender = UserSession.normalizeGender(source.gender),
                            ),
                        ),
                    )
                }
            }
        }

        return commitSession(offlineSession)
    }

    private suspend fun clearSessionForLoginAttempt() {
        isOfflineSession = false
        stickySession = null
        pinnedSession = null
        localAuth.clearActiveOfflineUid()
        try {
            auth.signOut()
        } catch (_: Exception) {
        }
        _session.value = null
        notifySessionChanged()
    }

    suspend fun upgradeToFirebaseSession(
        email: String,
        password: String,
        localSession: UserSession,
    ): UserSession {
        val normalizedEmail = LocalAuthStore.normalizeEmail(email)
        val authed = try {
            withTimeout(ONLINE_SIGN_IN_TIMEOUT_MS) {
                localAuth.refreshFirebaseAuth(auth, preferredEmail = normalizedEmail)
            }
        } catch (_: TimeoutCancellationException) {
            false
        }
        if (!authed || auth.currentUser == null) {
            throw FirebaseAuthFailedException(normalizedEmail)
        }

        val uid = auth.currentUser!!.uid
        val source = profileSourceForEmail(normalizedEmail, fallback = localSession)
            ?: run {
                auth.signOut()
                throw ProfileNotFoundException()
            }

        val doc = withTimeout(ONLINE_SIGN_IN_TIMEOUT_MS) {
            firestore.collection("users").document(uid).get().await()
        }

        val seed = if (doc.exists()) {
            UserSession.fromMap(uid, doc.data.orEmpty())
        } else {
            UserSession(
                uid = uid,
                name = source.name,
                email = normalizedEmail,
                role = source.role,
                gender = UserSession.normalizeGender(source.gender),
            )
        }

        return withTimeout(ONLINE_SIGN_IN_TIMEOUT_MS) {
            syncUserProfileWithFirebase(seed, password = password)
        }
    }

    suspend fun signIn(email: String, password: String): UserSession {
        isLoginAttemptInProgress = true
        try {
            clearSessionForLoginAttempt()

            val normalizedEmail = LocalAuthStore.normalizeEmail(email)
            val localSession = localAuth.getUserByEmail(normalizedEmail)
            val localPasswordOk = localAuth.verifyPassword(normalizedEmail, password)

            val session: UserSession = when {
                localPasswordOk && localSession != null -> {
                    localAuth.rememberLogin(normalizedEmail, password)
                    if (connectivity.isOnline) {
                        upgradeToFirebaseSession(normalizedEmail, password, localSession)
                    } else {
                        activateLocalSession(localSession)
                    }
                }
                connectivity.isOnline -> {
                    withTimeout(ONLINE_SIGN_IN_TIMEOUT_MS) {
                        signInOnline(normalizedEmail, password)
                    }
                }
                localSession == null -> throw NoLocalUserOfflineException()
                else -> throw OfflineWrongPasswordException()
            }

            if (connectivity.isOnline) {
                cacheUsersRoster()
            }

            notifySessionChanged()
            return session
        } finally {
            isLoginAttemptInProgress = false
            notifySessionChanged()
        }
    }

    private suspend fun activateLocalSession(session: UserSession): UserSession {
        val firebaseUser = auth.currentUser
        if (firebaseUser != null) {
            val firebaseEmail = LocalAuthStore.normalizeEmail(firebaseUser.email.orEmpty())
            val sessionEmail = LocalAuthStore.normalizeEmail(session.email)
            if (firebaseEmail != sessionEmail) {
                auth.signOut()
            }
        }
        localAuth.setActiveOfflineUid(session.uid)
        isOfflineSession = true
        commitSession(session)
        notifySessionChanged()
        return session
    }

    private suspend fun signInOnline(email: String, password: String): UserSession {
        val cred = auth.signInWithEmailAndPassword(email, password).await()
        val uid = cred.user!!.uid

        val doc = firestore.collection("users").document(uid).get().await()
        if (!doc.exists() || doc.data == null) {
            auth.signOut()
            throw ProfileNotFoundException()
        }

        val session = UserSession.fromMap(uid, doc.data!!)
        return syncUserProfileWithFirebase(session, password = password)
    }

    /**
     * Ensure Firestore users/{firebaseUid} exists and local cache uses same uid.
     *
     * Password field: Firestore wins when set; otherwise seed typed password.
     * Updates local hash + Firebase Auth via [updatePassword].
     */
    suspend fun syncUserProfileWithFirebase(
        session: UserSession,
        password: String? = null,
    ): UserSession {
        val authUser = auth.currentUser ?: return session

        val uid = authUser.uid
        val email = LocalAuthStore.normalizeEmail(authUser.email ?: session.email)
        if (email.isEmpty()) return session

        AppLog.d(TAG, "Syncing user profile for $email ($uid)")

        val source = profileSourceForEmail(email, fallback = session) ?: return session

        val ref = firestore.collection("users").document(uid)
        val doc = ref.get().await()

        val profile: UserSession = if (doc.exists()) {
            val remote = UserSession.fromMap(uid, doc.data.orEmpty())
            when {
                needsProfileRepair(source, remote) -> {
                    val repaired = UserSession(
                        uid = uid,
                        name = source.name.ifEmpty { remote.name },
                        email = email,
                        role = source.role,
                        gender = UserSession.normalizeGender(
                            source.gender.ifEmpty { remote.gender },
                        ),
                        avatar = remote.avatar,
                    )
                    ref.set(repaired.toMap(), SetOptions.merge()).await()
                    localAuth.saveUser(repaired, password = password)
                    AppLog.i(TAG, "Repaired users/$uid → role=${repaired.role.toFirestore()}")
                    finalizeOnlineSession(repaired, password)
                }
                remote.uid != uid -> {
                    val rebound = UserSession(
                        uid = uid,
                        name = remote.name,
                        email = email,
                        role = remote.role,
                        gender = remote.gender,
                        avatar = remote.avatar,
                    )
                    localAuth.saveUser(rebound, password = password)
                    finalizeOnlineSession(rebound, password)
                }
                else -> {
                    localAuth.saveUser(remote, password = password)
                    finalizeOnlineSession(remote, password)
                }
            }
        } else {
            val created = UserSession(
                uid = uid,
                name = source.name,
                email = email,
                role = source.role,
                gender = UserSession.normalizeGender(source.gender),
                avatar = if (session.uid == uid) session.avatar else null,
            )
            ref.set(created.toMap(), SetOptions.merge()).await()
            localAuth.saveUser(created, password = password)
            AppLog.i(TAG, "Synced users/$uid for $email")
            finalizeOnlineSession(created, password)
        }

        if (password != null) {
            reconcilePasswordField(uid, password, profile)
        }
        return profile
    }

    /**
     * Firestore `users/{uid}.password` is source of truth when non-empty;
     * otherwise seed the typed login password so Console edits apply next login.
     */
    private suspend fun reconcilePasswordField(
        uid: String,
        typedPassword: String,
        profile: UserSession,
    ) {
        val ref = firestore.collection("users").document(uid)
        val doc = ref.get().await()
        val remotePassword = (doc.getString("password") ?: "").trim()

        if (remotePassword.isNotEmpty()) {
            localAuth.saveUser(profile, password = remotePassword)
            localAuth.rememberLogin(profile.email, remotePassword)
            try {
                auth.currentUser?.updatePassword(remotePassword)?.await()
            } catch (e: Exception) {
                Log.d(TAG, "updatePassword (Firestore wins) failed: $e")
            }
        } else {
            ref.set(mapOf("password" to typedPassword), SetOptions.merge()).await()
            localAuth.saveUser(profile, password = typedPassword)
            localAuth.rememberLogin(profile.email, typedPassword)
        }
    }

    private fun shouldRepairUserProfile(local: UserSession, remote: UserSession): Boolean {
        if (AccessControl.canApprove(local.role) && !AccessControl.canApprove(remote.role)) {
            return true
        }
        if (remote.gender.trim().isEmpty() && local.gender.trim().isNotEmpty()) {
            return true
        }
        return false
    }

    private fun needsProfileRepair(local: UserSession, remote: UserSession): Boolean {
        if (shouldRepairUserProfile(local, remote)) return true
        if (local.role != remote.role) return true
        val remoteGender = UserSession.normalizeGender(remote.gender)
        val localGender = UserSession.normalizeGender(local.gender)
        return remoteGender != localGender && localGender.isNotEmpty()
    }

    private suspend fun profileSourceForEmail(
        email: String,
        fallback: UserSession? = null,
    ): UserSession? = localAuth.getUserByEmail(email) ?: fallback

    suspend fun cacheUsersRoster() {
        if (!connectivity.isOnline) return
        try {
            val snap = firestore.collection("users").get().await()
            for (doc in snap.documents) {
                val data = doc.data ?: continue
                if (data.isEmpty()) continue
                try {
                    val session = UserSession.fromMap(doc.id, data)
                    localAuth.saveUser(session)
                } catch (e: Exception) {
                    Log.d(TAG, "cacheUsersRoster skip ${doc.id}: $e")
                }
            }
        } catch (e: Exception) {
            Log.d(TAG, "cacheUsersRoster failed: $e")
        }
    }

    suspend fun hasPersistedLoginIntent(): Boolean {
        if (isOfflineSession) return true
        val remembered = localAuth.getRememberedEmail()
        if (!remembered.isNullOrEmpty()) return true
        return localAuth.getActiveOfflineUid() != null
    }

    suspend fun signOut() {
        isOfflineSession = false
        stickySession = null
        pinnedSession = null
        localAuth.clearActiveOfflineUid()
        localAuth.clearRememberedLogin()
        auth.signOut()
        _session.value = null
        notifySessionChanged()
    }

    suspend fun promoteOfflineSessionIfOnline(): Boolean {
        if (!connectivity.isOnline) return false
        if (!hasPersistedLoginIntent()) {
            if (auth.currentUser != null) {
                auth.signOut()
            }
            return false
        }

        val offlineSession = localAuth.getActiveOfflineSession()
        if (offlineSession == null && !isOfflineSession) {
            return auth.currentUser != null
        }

        val hint = offlineSession ?: localAuth.getActiveOfflineSession() ?: return false

        val ok = localAuth.refreshFirebaseAuth(auth, preferredEmail = hint.email)
        if (!ok) {
            Log.d(TAG, "promoteOfflineSession: Firebase re-auth failed for ${hint.email}")
            return false
        }

        val uid = auth.currentUser?.uid ?: return false
        val doc = firestore.collection("users").document(uid).get().await()
        if (!doc.exists()) {
            val email = LocalAuthStore.normalizeEmail(auth.currentUser?.email ?: hint.email)
            val source = profileSourceForEmail(email, fallback = hint) ?: return false
            val bootstrapped = UserSession(
                uid = uid,
                name = source.name,
                email = email,
                role = source.role,
                gender = UserSession.normalizeGender(source.gender),
            )
            syncUserProfileWithFirebase(bootstrapped)
            return true
        }

        syncUserProfileWithFirebase(UserSession.fromMap(uid, doc.data.orEmpty()))
        return true
    }

    companion object {
        private const val TAG = "AuthRepository"
        private const val FETCH_SESSION_TIMEOUT_MS = 12_000L
        private const val ONLINE_SIGN_IN_TIMEOUT_MS = 10_000L
    }
}
