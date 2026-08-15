package com.example.salik_management_system.features.saliks.domain.model

enum class ApprovalStatus {
    Pending,
    Approved,
    Rejected;

    fun toFirestore(): String = when (this) {
        Pending -> "pending"
        Approved -> "approved"
        Rejected -> "rejected"
    }

    companion object {
        fun fromString(value: String?): ApprovalStatus {
            return when (value?.trim()?.lowercase()) {
                "pending" -> Pending
                "rejected" -> Rejected
                else -> Approved
            }
        }
    }
}
