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
        return UserSession.normalizeGender(session.gender)
    }

    /** Matches Firestore rules genderMatches — Male/male and Female/female. */
    fun salikGenderMatches(salikGenderId: String, filterGender: String): Boolean {
        return UserSession.normalizeGender(salikGenderId) ==
            UserSession.normalizeGender(filterGender)
    }

    /** Firestore whereIn values for gender-scoped salik pull. */
    fun salikGenderFirestoreValues(filterGender: String): List<String> {
        return when (UserSession.normalizeGender(filterGender)) {
            "Female" -> listOf("Female", "female")
            else -> listOf("Male", "male")
        }
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
