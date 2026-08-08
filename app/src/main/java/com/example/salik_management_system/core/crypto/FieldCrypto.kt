package com.example.salik_management_system.core.crypto

import java.security.SecureRandom
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Client-side AES-256-GCM field encryption for Firestore PII.
 *
 * Ciphertext format: `enc:v1:` + base64(nonce[12] + cipher+tag).
 * Legacy plaintext (no prefix) passes through decrypt unchanged.
 */
class FieldCrypto(private val keyBytes: ByteArray) {
    init {
        require(keyBytes.size == KEY_LENGTH) {
            "Field crypto key must be $KEY_LENGTH bytes"
        }
    }

    fun encryptField(plain: String?): String? {
        if (plain == null) return null
        if (plain.isEmpty()) return plain
        if (isEncrypted(plain)) return plain

        val nonce = ByteArray(NONCE_LENGTH).also { SecureRandom().nextBytes(it) }
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(
            Cipher.ENCRYPT_MODE,
            SecretKeySpec(keyBytes, "AES"),
            GCMParameterSpec(TAG_LENGTH_BITS, nonce),
        )
        val cipherAndTag = cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
        val packed = ByteArray(nonce.size + cipherAndTag.size)
        System.arraycopy(nonce, 0, packed, 0, nonce.size)
        System.arraycopy(cipherAndTag, 0, packed, nonce.size, cipherAndTag.size)
        return PREFIX + Base64.getEncoder().encodeToString(packed)
    }

    fun decryptField(value: String?): String? {
        if (value == null) return null
        if (value.isEmpty()) return value
        if (!isEncrypted(value)) return value

        return try {
            val packed = Base64.getDecoder().decode(value.substring(PREFIX.length))
            if (packed.size <= NONCE_LENGTH) return value

            val nonce = packed.copyOfRange(0, NONCE_LENGTH)
            val cipherAndTag = packed.copyOfRange(NONCE_LENGTH, packed.size)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(
                Cipher.DECRYPT_MODE,
                SecretKeySpec(keyBytes, "AES"),
                GCMParameterSpec(TAG_LENGTH_BITS, nonce),
            )
            String(cipher.doFinal(cipherAndTag), Charsets.UTF_8)
        } catch (_: Exception) {
            // Wrong key or corrupt ciphertext — return as-is for graceful degrade.
            value
        }
    }

    fun encryptSalikMap(map: Map<String, Any?>): MutableMap<String, Any?> {
        val out = map.toMutableMap()
        for (key in PII_KEYS) {
            val value = out[key]
            if (value is String) {
                out[key] = encryptField(value)
            }
        }
        return out
    }

    fun decryptSalikMap(map: Map<String, Any?>): MutableMap<String, Any?> {
        val out = map.toMutableMap()
        for (key in PII_KEYS) {
            val value = out[key]
            if (value is String) {
                out[key] = decryptField(value)
            }
        }
        return out
    }

    fun encryptSalikPii(
        name: String,
        fatherName: String,
        mobileNumber: String,
        whatsappNumber: String,
        address: String,
        referenceName: String,
        referenceMobile: String,
    ): SalikPiiBundle {
        return SalikPiiBundle(
            name = encryptField(name).orEmpty(),
            fatherName = encryptField(fatherName).orEmpty(),
            mobileNumber = encryptField(mobileNumber).orEmpty(),
            whatsappNumber = encryptField(whatsappNumber).orEmpty(),
            address = encryptField(address).orEmpty(),
            referenceName = encryptField(referenceName).orEmpty(),
            referenceMobile = encryptField(referenceMobile).orEmpty(),
        )
    }

    companion object {
        const val PREFIX = "enc:v1:"
        const val KEY_LENGTH = 32
        private const val NONCE_LENGTH = 12
        private const val TAG_LENGTH_BITS = 128
        private const val TRANSFORMATION = "AES/GCM/NoPadding"

        val PII_KEYS: Set<String> = setOf(
            "name",
            "fatherName",
            "mobileNumber",
            "whatsappNumber",
            "address",
            "referenceName",
            "referenceMobile",
        )

        fun fromBase64Key(keyBase64: String): FieldCrypto {
            val bytes = Base64.getDecoder().decode(keyBase64)
            return FieldCrypto(bytes)
        }

        fun generateKeyBase64(): String {
            val bytes = ByteArray(KEY_LENGTH).also { SecureRandom().nextBytes(it) }
            return Base64.getEncoder().encodeToString(bytes)
        }

        fun isEncrypted(value: String?): Boolean {
            if (value == null) return false
            return value.startsWith(PREFIX)
        }
    }
}

data class SalikPiiBundle(
    val name: String,
    val fatherName: String,
    val mobileNumber: String,
    val whatsappNumber: String,
    val address: String,
    val referenceName: String,
    val referenceMobile: String,
)
