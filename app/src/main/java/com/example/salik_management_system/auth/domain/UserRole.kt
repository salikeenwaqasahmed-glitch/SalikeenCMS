package com.example.salik_management_system.auth.domain

enum class UserRole {
    Admin,
    Approval,
    Editor;

    val label: String
        get() = when (this) {
            Admin -> "Super Admin"
            Approval -> "Approval"
            Editor -> "Editor"
        }

    fun toFirestore(): String = when (this) {
        Admin -> "admin"
        Approval -> "approval"
        Editor -> "editor"
    }

    companion object {
        fun fromString(value: String): UserRole {
            val normalized = value.trim().lowercase().replace(Regex("[\\s_-]"), "")
            return when (normalized) {
                "admin", "globaladmin" -> Admin
                "approval", "genderadmin" -> Approval
                "editor", "cruduser" -> Editor
                else -> Editor
            }
        }
    }
}
