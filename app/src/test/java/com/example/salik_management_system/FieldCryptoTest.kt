package com.example.salik_management_system

import com.example.salik_management_system.core.crypto.FieldCrypto
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FieldCryptoTest {
    private val crypto = FieldCrypto.fromBase64Key(
        "oseHVKBqsJE6twGWGPl4/51tjxNknNktqe1wU6vT1Ws=",
    )

    @Test
    fun encryptDecryptRoundTrip() {
        val plain = "Ali Khan"
        val enc = crypto.encryptField(plain)
        assertTrue(FieldCrypto.isEncrypted(enc))
        assertTrue(enc!!.startsWith(FieldCrypto.PREFIX))
        assertEquals(plain, crypto.decryptField(enc))
    }

    @Test
    fun plaintextPassthrough() {
        assertEquals("plain", crypto.decryptField("plain"))
        assertFalse(FieldCrypto.isEncrypted("plain"))
    }

    @Test
    fun encryptSalikMapPiiOnly() {
        val map = mapOf(
            "name" to "A",
            "genderId" to "Male",
            "mobileNumber" to "923001234567",
        )
        val enc = crypto.encryptSalikMap(map)
        assertTrue(FieldCrypto.isEncrypted(enc["name"] as String))
        assertEquals("Male", enc["genderId"])
        assertEquals("A", crypto.decryptField(enc["name"] as String))
    }
}
