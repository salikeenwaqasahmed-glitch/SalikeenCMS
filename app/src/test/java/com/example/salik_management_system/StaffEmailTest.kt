package com.example.salik_management_system

import com.example.salik_management_system.core.auth.LocalAuthStore
import com.example.salik_management_system.core.auth.staffEmailLocalPartError
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class StaffEmailTest {
    @Test
    fun normalizeLowercases() {
        assertEquals("a@b.com", LocalAuthStore.normalizeEmail("  A@B.com "))
    }

    @Test
    fun localPartValidation() {
        assertNotNull(staffEmailLocalPartError(null))
        assertNotNull(staffEmailLocalPartError(""))
        assertNotNull(staffEmailLocalPartError("bad name"))
        assertNull(staffEmailLocalPartError("madmin"))
        assertNull(staffEmailLocalPartError("user@cms.com"))
    }
}
