package com.example.salik_management_system.features.saliks.data.mapper

import com.example.salik_management_system.core.database.LocalAreaEntity
import com.example.salik_management_system.core.database.LocalBazamEntity
import com.example.salik_management_system.core.database.LocalSalikEntity
import com.example.salik_management_system.core.database.SyncStatus
import com.example.salik_management_system.features.saliks.domain.model.ApprovalStatus
import com.example.salik_management_system.features.saliks.domain.model.Area
import com.example.salik_management_system.features.saliks.domain.model.Bazam
import com.example.salik_management_system.features.saliks.domain.model.Salik
import com.example.salik_management_system.features.saliks.domain.model.kDefaultBazamId

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
    dateOfBaith = dateOfBaith,
    referenceName = referenceName,
    isNafiAsbat = isNafiAsbat,
    isSahibEMehfil = isSahibEMehfil,
    createdDate = createdDate,
    modifiedDate = modifiedDate,
    isActive = isActive,
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
    dateOfBaith = dateOfBaith,
    referenceName = referenceName,
    isNafiAsbat = isNafiAsbat,
    isSahibEMehfil = isSahibEMehfil,
    createdDate = createdDate,
    modifiedDate = modifiedDate,
    isActive = isActive,
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
