package com.example.salik_management_system.core.database

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "local_areas")
data class LocalAreaEntity(
    @PrimaryKey
    @ColumnInfo(name = "area_id")
    val areaId: String,
    @ColumnInfo(name = "area_name")
    val areaName: String,
    @ColumnInfo(name = "bazam_id")
    val bazamId: String = "i-10",
    @ColumnInfo(name = "sync_status")
    val syncStatus: String = SyncStatus.synced,
)
