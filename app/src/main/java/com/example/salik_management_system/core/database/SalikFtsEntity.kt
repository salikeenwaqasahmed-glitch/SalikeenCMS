package com.example.salik_management_system.core.database

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Fts4

@Fts4(contentEntity = LocalSalikEntity::class)
@Entity(tableName = "saliks_fts")
data class SalikFtsEntity(
    @ColumnInfo(name = "name")
    val name: String,
    @ColumnInfo(name = "mobile_number")
    val mobileNumber: String,
    @ColumnInfo(name = "father_name")
    val fatherName: String,
    @ColumnInfo(name = "date_of_baith")
    val dateOfBaith: String,
)
