package com.example.salik_management_system.core.auth

import com.example.salik_management_system.core.config.AppConfig

/** Composes a full staff email from local part or passes through full addresses. */
fun composeStaffEmail(input: String): String {
    val trimmed = input.trim()
    if (trimmed.isEmpty()) return ""

    val normalized = LocalAuthStore.normalizeEmail(trimmed)
    if (normalized.contains("@")) return normalized

    return normalized + AppConfig.staffEmailDomain
}

/** Strips env domain suffix for display in the login local-part field. */
fun localPartFromStaffEmail(email: String): String {
    val normalized = LocalAuthStore.normalizeEmail(email)
    if (normalized.isEmpty()) return ""

    val domain = AppConfig.staffEmailDomain
    return if (normalized.endsWith(domain)) {
        normalized.substring(0, normalized.length - domain.length)
    } else {
        normalized
    }
}

fun staffEmailLocalPartError(value: String?): String? {
    if (value == null || value.trim().isEmpty()) {
        return "Required"
    }
    val trimmed = value.trim()
    if (trimmed.contains(" ")) {
        return "Invalid username"
    }
    if (trimmed.contains("@")) {
        if (trimmed.startsWith("@") || trimmed.endsWith("@") || !trimmed.contains(".")) {
            return "Invalid email"
        }
        return null
    }
    return null
}
