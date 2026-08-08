package com.example.salik_management_system.features.saliks.data

import com.example.salik_management_system.core.database.LocalAreaEntity
import com.example.salik_management_system.core.database.LocalBazamEntity
import com.example.salik_management_system.core.database.LocalSalikEntity
import com.example.salik_management_system.core.database.SyncStatus
import com.example.salik_management_system.features.saliks.domain.ApprovalStatus
import com.example.salik_management_system.features.saliks.domain.Area
import com.example.salik_management_system.features.saliks.domain.Bazam
import com.example.salik_management_system.features.saliks.domain.Salik
import com.example.salik_management_system.features.saliks.domain.kDefaultBazamId

fun LocalSalikEntity.toDomain(): Salik = Salik(
    salikId = salikId,
    name = name,
    fatherName = fatherName,
    mobileNumber = mobileNumber,
    whatsappNumber = whatsappNumber,
    areaId = areaId,
    address = address,
    genderId = genderId,
    bazamId = bazamId,
    khanqahId = khanqahId,
    salikCategoryId = salikCategoryId,
    dateOfBaith = dateOfBaith,
    referenceName = referenceName,
    referenceMobile = referenceMobile,
    isNafiAsbat = isNafiAsbat,
    isSahibEMehfil = isSahibEMehfil,
    nafiZikrId = nafiZikrId,
    profilePicture = profilePicture,
    createdDate = createdDate,
    modifiedDate = modifiedDate,
    isActive = isActive,
    notes = notes,
    addedByUid = addedByUid,
    addedByName = addedByName,
    approvalStatus = ApprovalStatus.fromString(approvalStatus),
    approvedByUid = approvedByUid,
    approvedByName = approvedByName,
    approvedAt = approvedAt,
)

fun Salik.toEntity(syncStatus: String = SyncStatus.synced): LocalSalikEntity = LocalSalikEntity(
    salikId = salikId,
    name = name,
    fatherName = fatherName,
    mobileNumber = mobileNumber,
    whatsappNumber = whatsappNumber,
    areaId = areaId,
    address = address,
    genderId = genderId,
    bazamId = bazamId,
    khanqahId = khanqahId,
    salikCategoryId = salikCategoryId,
    dateOfBaith = dateOfBaith,
    referenceName = referenceName,
    referenceMobile = referenceMobile,
    isNafiAsbat = isNafiAsbat,
    isSahibEMehfil = isSahibEMehfil,
    nafiZikrId = nafiZikrId,
    profilePicture = profilePicture,
    createdDate = createdDate,
    modifiedDate = modifiedDate,
    isActive = isActive,
    notes = notes,
    addedByUid = addedByUid,
    addedByName = addedByName,
    approvalStatus = approvalStatus.toFirestore(),
    approvedByUid = approvedByUid,
    approvedByName = approvedByName,
    approvedAt = approvedAt,
    syncStatus = syncStatus,
    localUpdatedAt = System.currentTimeMillis(),
)

fun LocalAreaEntity.toDomain(): Area = Area(
    areaId = areaId,
    areaName = areaName,
    bazamId = bazamId.trim().ifEmpty { kDefaultBazamId },
)

fun Area.toEntity(syncStatus: String = SyncStatus.synced): LocalAreaEntity = LocalAreaEntity(
    areaId = areaId,
    areaName = areaName,
    bazamId = bazamId.ifEmpty { kDefaultBazamId },
    syncStatus = syncStatus,
)

fun LocalBazamEntity.toDomain(): Bazam = Bazam(
    bazamId = bazamId,
    bazamName = bazamName,
)

fun Bazam.toEntity(syncStatus: String = SyncStatus.synced): LocalBazamEntity = LocalBazamEntity(
    bazamId = bazamId,
    bazamName = bazamName,
    syncStatus = syncStatus,
)
