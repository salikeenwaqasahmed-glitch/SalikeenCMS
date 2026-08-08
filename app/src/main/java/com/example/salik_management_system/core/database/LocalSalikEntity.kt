package com.example.salik_management_system.core.database

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "local_saliks")
data class LocalSalikEntity(
    @PrimaryKey
    @ColumnInfo(name = "salik_id")
    val salikId: String,
    @ColumnInfo(name = "name")
    val name: String,
    @ColumnInfo(name = "father_name")
    val fatherName: String,
    @ColumnInfo(name = "mobile_number")
    val mobileNumber: String,
    @ColumnInfo(name = "whatsapp_number")
    val whatsappNumber: String,
    @ColumnInfo(name = "area_id")
    val areaId: String,
    @ColumnInfo(name = "address")
    val address: String = "",
    @ColumnInfo(name = "gender_id")
    val genderId: String,
    @ColumnInfo(name = "bazam_id")
    val bazamId: String = "",
    @ColumnInfo(name = "khanqah_id")
    val khanqahId: String = "",
    @ColumnInfo(name = "salik_category_id")
    val salikCategoryId: String = "",
    @ColumnInfo(name = "date_of_baith")
    val dateOfBaith: String,
    @ColumnInfo(name = "reference_name")
    val referenceName: String,
    @ColumnInfo(name = "reference_mobile")
    val referenceMobile: String = "",
    @ColumnInfo(name = "is_nafi_asbat")
    val isNafiAsbat: Boolean = false,
    @ColumnInfo(name = "is_sahib_e_mehfil")
    val isSahibEMehfil: Boolean = false,
    @ColumnInfo(name = "nafi_zikr_id")
    val nafiZikrId: String = "",
    @ColumnInfo(name = "profile_picture")
    val profilePicture: String = "",
    @ColumnInfo(name = "created_date")
    val createdDate: String,
    @ColumnInfo(name = "modified_date")
    val modifiedDate: String,
    @ColumnInfo(name = "is_active")
    val isActive: Boolean = true,
    @ColumnInfo(name = "notes")
    val notes: String? = null,
    @ColumnInfo(name = "added_by_uid")
    val addedByUid: String = "",
    @ColumnInfo(name = "added_by_name")
    val addedByName: String = "",
    @ColumnInfo(name = "approval_status")
    val approvalStatus: String = "approved",
    @ColumnInfo(name = "approved_by_uid")
    val approvedByUid: String = "",
    @ColumnInfo(name = "approved_by_name")
    val approvedByName: String = "",
    @ColumnInfo(name = "approved_at")
    val approvedAt: String = "",
    @ColumnInfo(name = "sync_status")
    val syncStatus: String = SyncStatus.synced,
    @ColumnInfo(name = "local_updated_at")
    val localUpdatedAt: Long = System.currentTimeMillis(),
)
