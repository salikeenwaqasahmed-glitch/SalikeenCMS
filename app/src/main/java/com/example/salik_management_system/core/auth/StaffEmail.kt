package com.example.salik_management_system.core.auth

import com.example.salik_management_system.core.config.AppConfig

/**
 * Builds Firebase Auth email from username local-part only.
 * Domain is never shown in the login UI — append happens here.
 */
fun composeStaffEmail(input: String): String {
    val trimmed = input.trim().lowercase()
    if (trimmed.isEmpty()) return ""
    // Username-only: ignore accidental @domain (validation should reject first).
    val local = trimmed.substringBefore("@")
    if (local.isEmpty()) return ""
    return local + AppConfig.staffEmailDomain
}

/** Strips env domain suffix for remembered username display. */
fun localPartFromStaffEmail(email: String): String {
    val normalized = LocalAuthStore.normalizeEmail(email)
    if (normalized.isEmpty()) return ""

    val domain = AppConfig.staffEmailDomain
    return if (normalized.endsWith(domain)) {
        normalized.substring(0, normalized.length - domain.length)
    } else {
        normalized.substringBefore("@")
    }
}

/** Username field validation — local part only, no email. */
fun staffEmailLocalPartError(value: String?): String? {
    if (value == null || value.trim().isEmpty()) {
        return "Required"
    }
    val trimmed = value.trim()
    if (trimmed.contains("@")) {
        return "Username only"
    }
    if (trimmed.contains(" ")) {
        return "Invalid username"
    }
    return null
}
