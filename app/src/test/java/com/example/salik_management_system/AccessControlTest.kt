package com.example.salik_management_system

import com.example.salik_management_system.auth.domain.UserRole
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.utils.AccessControl
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AccessControlTest {
    @Test
    fun roleCapabilities() {
        assertTrue(AccessControl.canDelete(UserRole.Admin))
        assertFalse(AccessControl.canDelete(UserRole.Approval))
        assertFalse(AccessControl.canUpdate(UserRole.Editor))
        assertTrue(AccessControl.canCreate(UserRole.Editor))
        assertTrue(AccessControl.canApprove(UserRole.Approval))
        assertFalse(AccessControl.canResolveDuplicates(UserRole.Editor))
    }

    @Test
    fun genderFilter() {
        val admin = UserSession("1", "A", "a@x.com", UserRole.Admin, "Male")
        val editor = UserSession("2", "E", "e@x.com", UserRole.Editor, "Female")
        assertNull(AccessControl.genderFilter(admin))
        assertEquals("Female", AccessControl.genderFilter(editor))
    }

    @Test
    fun roleAliases() {
        assertEquals(UserRole.Approval, UserRole.fromString("genderAdmin"))
        assertEquals(UserRole.Editor, UserRole.fromString("crudUser"))
        assertEquals("editor", UserRole.Editor.toFirestore())
    }
}
