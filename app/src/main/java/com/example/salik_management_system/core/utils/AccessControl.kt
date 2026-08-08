package com.example.salik_management_system.core.utils

import com.example.salik_management_system.auth.domain.UserRole
import com.example.salik_management_system.auth.domain.UserSession

object AccessControl {
    fun canCreate(role: UserRole): Boolean =
        role == UserRole.Admin || role == UserRole.Approval || role == UserRole.Editor

    fun canUpdate(role: UserRole): Boolean =
        role == UserRole.Admin || role == UserRole.Approval

    fun canDelete(role: UserRole): Boolean = role == UserRole.Admin

    fun canResolveDuplicates(role: UserRole): Boolean =
        role == UserRole.Admin || role == UserRole.Approval

    fun canApprove(role: UserRole): Boolean =
        role == UserRole.Admin || role == UserRole.Approval

    fun canViewPending(role: UserRole): Boolean =
        role == UserRole.Admin || role == UserRole.Approval || role == UserRole.Editor

    fun isEditor(role: UserRole): Boolean = role == UserRole.Editor

    fun isApprovalRole(role: UserRole): Boolean = role == UserRole.Approval

    fun canViewAllGenders(role: UserRole): Boolean = role == UserRole.Admin

    fun genderFilter(session: UserSession?): String? {
        if (session == null) return null
        if (canViewAllGenders(session.role)) return null
        return session.gender
    }

    fun canSetGender(session: UserSession): Boolean = session.role == UserRole.Admin

    fun effectiveGender(session: UserSession, selectedGender: String): String {
        return if (session.role == UserRole.Admin) {
            UserSession.normalizeGender(selectedGender)
        } else {
            UserSession.normalizeGender(session.gender)
        }
    }
}
