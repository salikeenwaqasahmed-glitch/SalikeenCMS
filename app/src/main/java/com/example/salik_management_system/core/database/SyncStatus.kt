package com.example.salik_management_system.core.database

object SyncStatus {
    const val synced = "synced"
    const val pendingCreate = "pendingCreate"
    const val pendingUpdate = "pendingUpdate"
    const val pendingDelete = "pendingDelete"

    /** Lookup-only row mapping a remote doc id to canonical area names. */
    const val alias = "alias"
}
