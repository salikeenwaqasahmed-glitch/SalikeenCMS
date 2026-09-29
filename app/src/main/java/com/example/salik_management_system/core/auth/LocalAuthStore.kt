package com.example.salik_management_system.core.auth

import android.content.SharedPreferences
import android.util.Log
import com.example.salik_management_system.auth.domain.UserRole
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.database.LocalUserDao
import com.example.salik_management_system.core.database.LocalUserEntity
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.security.MessageDigest
import javax.inject.Inject
import javax.inject.Singleton

class OfflineWrongPasswordException : Exception()
class NoLocalUserOfflineException : Exception()

@Singleton
class LocalAuthStore @Inject constructor(
    private val userDao: LocalUserDao,
    private val prefs: SharedPreferences,
) {
    suspend fun hashPassword(password: String): String = withContext(Dispatchers.Default) {
        val salt = getOrCreateSalt()
        sha256Hex("$salt$password")
    }

    suspend fun verifyPassword(email: String, password: String): Boolean {
        val user = findUserByEmail(email) ?: return false
        if (user.passwordHash.isEmpty()) return false
        val hash = hashPassword(password)
        return user.passwordHash == hash
    }

    suspend fun ensureLocalUser(
        session: UserSession,
        password: String,
        refreshPassword: Boolean = false,
    ) {
        val email = normalizeEmail(session.email)
        val existing = findUserByEmail(email)
        if (existing == null) {
            saveUser(session, password = password)
            return
        }
        if (existing.passwordHash.isNotEmpty() && !refreshPassword) {
            val existingRole = UserRole.fromString(existing.role)
            if (existing.name != session.name ||
                existingRole != session.role ||
                existing.gender != session.gender
            ) {
                saveUser(
                    UserSession(
                        uid = if (existing.uid.startsWith("local-")) session.uid else existing.uid,
                        name = session.name,
                        email = email,
                        role = session.role,
                        gender = session.gender,
                    ),
                )
            }
            return
        }

        val uid = if (existing.uid.startsWith("local-")) session.uid else existing.uid
        saveUser(
            UserSession(
                uid = uid,
                name = session.name,
                email = email,
                role = session.role,
                gender = session.gender,
            ),
            password = password,
        )
    }

    suspend fun saveUser(session: UserSession, password: String? = null) {
        val email = normalizeEmail(session.email)
        val existing = findUserByEmail(email)

        // Drop placeholder row when binding to real Firebase uid.
        if (existing != null &&
            existing.uid != session.uid &&
            existing.uid.startsWith("local-")
        ) {
            userDao.deleteByUid(existing.uid)
        }

        val passwordHash = when {
            password != null -> hashPassword(password)
            else -> findUserByEmail(email)?.passwordHash.orEmpty()
        }

        userDao.upsert(
            LocalUserEntity(
                uid = session.uid,
                email = email,
                name = session.name,
                role = session.role.toFirestore(),
                gender = session.gender,
                passwordHash = passwordHash,
                lastSyncedAt = System.currentTimeMillis(),
            ),
        )
    }

    fun sessionFromLocal(user: LocalUserEntity): UserSession {
        return UserSession(
            uid = user.uid,
            name = user.name,
            email = user.email,
            role = UserRole.fromString(user.role),
            gender = user.gender,
        )
    }

    suspend fun getUserByEmail(email: String): UserSession? {
        val user = findUserByEmail(email) ?: return null
        return sessionFromLocal(user)
    }

    suspend fun getUserByUid(uid: String): UserSession? {
        val user = userDao.getByUid(uid) ?: return null
        return sessionFromLocal(user)
    }

    fun rememberLogin(email: String, password: String) {
        prefs.edit()
            .putString(LAST_EMAIL_KEY, normalizeEmail(email))
            .putString(LAST_PASSWORD_KEY, password)
            .apply()
    }

    fun clearRememberedLogin() {
        prefs.edit()
            .remove(LAST_EMAIL_KEY)
            .remove(LAST_PASSWORD_KEY)
            .apply()
    }

    fun getRememberedEmail(): String? = prefs.getString(LAST_EMAIL_KEY, null)

    fun getRememberedPassword(): String? = prefs.getString(LAST_PASSWORD_KEY, null)

    suspend fun refreshFirebaseAuth(
        auth: FirebaseAuth,
        preferredEmail: String? = null,
    ): Boolean {
        val preferred = preferredEmail?.let { normalizeEmail(it) }

        val current = auth.currentUser
        if (current != null) {
            val currentEmail = normalizeEmail(current.email.orEmpty())
            if (preferred == null || currentEmail == preferred) {
                return true
            }
            auth.signOut()
        }

        val attempts = mutableListOf<Pair<String, String>>()
        fun addAttempt(email: String, password: String) {
            if (password.isEmpty()) return
            val normalized = normalizeEmail(email)
            if (preferred != null && normalized != preferred) return
            if (attempts.any { it.first == normalized }) return
            attempts += normalized to password
        }

        val rememberedEmail = prefs.getString(LAST_EMAIL_KEY, null)
        val rememberedPassword = prefs.getString(LAST_PASSWORD_KEY, null)
        if (rememberedEmail != null && rememberedPassword != null) {
            addAttempt(rememberedEmail, rememberedPassword)
        }

        for ((email, password) in attempts) {
            try {
                auth.signInWithEmailAndPassword(email, password).await()
                if (auth.currentUser != null) {
                    rememberLogin(email, password)
                    return true
                }
            } catch (e: Exception) {
                Log.d(TAG, "Firebase re-auth failed for $email: $e")
            }
        }
        return false
    }

    fun setActiveOfflineUid(uid: String) {
        prefs.edit().putString(ACTIVE_UID_KEY, uid).apply()
    }

    fun getActiveOfflineUid(): String? = prefs.getString(ACTIVE_UID_KEY, null)

    fun clearActiveOfflineUid() {
        prefs.edit().remove(ACTIVE_UID_KEY).apply()
    }

    suspend fun getActiveOfflineSession(): UserSession? {
        val uid = getActiveOfflineUid() ?: return null
        return getUserByUid(uid)
    }

    private suspend fun findUserByEmail(email: String): LocalUserEntity? {
        val normalized = normalizeEmail(email)
        return userDao.getByEmail(normalized)
            ?: userDao.getAll().firstOrNull { normalizeEmail(it.email) == normalized }
    }

    private fun getOrCreateSalt(): String {
        var salt = prefs.getString(SALT_KEY, null)
        if (salt.isNullOrEmpty()) {
            salt = System.nanoTime().toString(36)
            prefs.edit().putString(SALT_KEY, salt).apply()
        }
        return salt
    }

    companion object {
        private const val TAG = "LocalAuthStore"
        private const val SALT_KEY = "device_password_salt"
        private const val ACTIVE_UID_KEY = "active_offline_uid"
        private const val LAST_EMAIL_KEY = "last_login_email"
        private const val LAST_PASSWORD_KEY = "last_login_password"

        fun normalizeEmail(email: String): String = email.trim().lowercase()

        private fun sha256Hex(input: String): String {
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(input.toByteArray(Charsets.UTF_8))
            return hash.joinToString("") { "%02x".format(it) }
        }
    }
}
