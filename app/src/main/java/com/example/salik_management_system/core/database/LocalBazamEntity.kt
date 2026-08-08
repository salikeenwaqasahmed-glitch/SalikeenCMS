package com.example.salik_management_system.core.database

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "local_bazams")
data class LocalBazamEntity(
    @PrimaryKey
    @ColumnInfo(name = "bazam_id")
    val bazamId: String,
    @ColumnInfo(name = "bazam_name")
    val bazamName: String,
    @ColumnInfo(name = "sync_status")
    val syncStatus: String = SyncStatus.synced,
)
