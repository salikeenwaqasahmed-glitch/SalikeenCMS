package com.example.salik_management_system.core.crypto

import android.util.Log
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.config.AppConfig
import com.example.salik_management_system.core.database.LocalAppKvDao
import com.example.salik_management_system.core.database.LocalAppKvEntity
import javax.inject.Inject
import javax.inject.Singleton

/**
 * AES field-crypto key stored in Room `local_app_kv` only (never Firestore).
 * Prefers [AppConfig.fieldCryptoKeyBase64] when set (shared org key).
 */
@Singleton
class FieldCryptoKeyStore @Inject constructor(
    private val kvDao: LocalAppKvDao,
) {
    @Volatile
    private var cached: FieldCrypto? = null

    val current: FieldCrypto? get() = cached

    suspend fun ensureKey(session: UserSession? = null): FieldCrypto? {
        cached?.let { return it }

        val fromConfig = AppConfig.fieldCryptoKeyBase64.trim()
        if (fromConfig.isNotEmpty()) {
            val existing = kvDao.get(KV_KEY)
            if (existing != fromConfig) {
                kvDao.upsert(LocalAppKvEntity(KV_KEY, fromConfig))
            }
            return cacheFromBase64(fromConfig)
        }

        val fromKv = kvDao.get(KV_KEY)
        if (!fromKv.isNullOrEmpty()) {
            return cacheFromBase64(fromKv)
        }

        val generated = FieldCrypto.generateKeyBase64()
        kvDao.upsert(LocalAppKvEntity(KV_KEY, generated))
        Log.d(TAG, "Field crypto: generated local key")
        return cacheFromBase64(generated)
    }

    private fun cacheFromBase64(keyBase64: String): FieldCrypto? {
        return try {
            FieldCrypto.fromBase64Key(keyBase64).also { cached = it }
        } catch (e: Exception) {
            Log.d(TAG, "Invalid field crypto key: $e")
            null
        }
    }

    companion object {
        const val KV_KEY = "field_crypto_key_v1"
        private const val TAG = "FieldCryptoKeyStore"
    }
}
