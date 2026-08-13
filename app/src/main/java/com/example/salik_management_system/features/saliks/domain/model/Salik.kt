package com.example.salik_management_system.features.saliks.domain.model

import java.time.LocalDate

data class Salik(
    val salikId: String,
    val name: String,
    val fatherName: String,
    val mobileNumber: String,
    val whatsappNumber: String,
    val areaId: String,
    val address: String = "",
    val genderId: String,
    val bazamId: String = "",
    val dateOfBaith: String,
    val referenceName: String,
    val isNafiAsbat: Boolean = false,
    val isSahibEMehfil: Boolean = false,
    val createdDate: String,
    val modifiedDate: String,
    val isActive: Boolean = true,
    val addedByUid: String = "",
    val addedByName: String = "",
    val approvalStatus: ApprovalStatus = ApprovalStatus.Approved,
    val approvedByUid: String = "",
    val approvedByName: String = "",
    val approvedAt: String = "",
) {
    val isApproved: Boolean get() = approvalStatus == ApprovalStatus.Approved
    val isPending: Boolean get() = approvalStatus == ApprovalStatus.Pending
    val isRejected: Boolean get() = approvalStatus == ApprovalStatus.Rejected

    fun calculateAge(): Int? {
        val date = dateOfBaith.ifBlank { return null }
        return try {
            val baithDate = LocalDate.parse(dateOnly(date))
            val now = LocalDate.now()
            java.time.Period.between(baithDate, now).years
        } catch (e: Exception) {
            null
        }
    }

    private fun dateOnly(fullDate: String): String {
        return if (fullDate.contains("T")) {
            fullDate.substringBefore("T")
        } else if (fullDate.contains(" ")) {
            fullDate.substringBefore(" ")
        } else {
            fullDate
        }
    }

    fun toMap(): Map<String, Any?> = mapOf(
        "salikId" to salikId,
        "name" to name,
        "fatherName" to fatherName,
        "mobileNumber" to mobileNumber,
        "whatsappNumber" to whatsappNumber,
        "areaId" to areaId,
        "address" to address,
        "genderId" to genderId,
        "bazamId" to bazamId,
        "dateOfBaith" to dateOfBaith,
        "referenceName" to referenceName,
        "isNafiAsbat" to isNafiAsbat,
        "isSahibEMehfil" to isSahibEMehfil,
        "createdDate" to createdDate,
        "modifiedDate" to modifiedDate,
        "isActive" to isActive,
        "addedByUid" to addedByUid,
        "addedByName" to addedByName,
        "approvalStatus" to approvalStatus.toFirestore(),
        "approvedByUid" to approvedByUid,
        "approvedByName" to approvedByName,
        "approvedAt" to approvedAt,
    )

    companion object {
        fun fromMap(map: Map<String, Any?>, id: String? = null): Salik {
            fun text(key: String, legacyPrimary: String? = null, legacySecondary: String? = null): String {
                val primary = (map[key] as? String)?.trim().orEmpty()
                if (primary.isNotEmpty()) return primary
                val a = legacyPrimary?.let { (map[it] as? String)?.trim().orEmpty() }.orEmpty()
                val b = legacySecondary?.let { (map[it] as? String)?.trim().orEmpty() }.orEmpty()
                return when {
                    a.isNotEmpty() && b.isNotEmpty() && a != b -> "$a / $b"
                    a.isNotEmpty() -> a
                    else -> b
                }
            }

            fun bool(key: String): Boolean = when (val v = map[key]) {
                is Boolean -> v
                is String -> v.equals("true", ignoreCase = true)
                else -> false
            }

            fun dateOnly(fullDate: String): String {
                return if (fullDate.contains("T")) {
                    fullDate.substringBefore("T")
                } else if (fullDate.contains(" ")) {
                    fullDate.substringBefore(" ")
                } else {
                    fullDate
                }
            }

            return Salik(
                salikId = id ?: (map["salikId"] as? String).orEmpty(),
                name = text("name", "nameEnglish", "nameUrdu"),
                fatherName = text("fatherName", "fatherNameEnglish", "fatherNameUrdu"),
                mobileNumber = (map["mobileNumber"] as? String).orEmpty(),
                whatsappNumber = (map["whatsappNumber"] as? String).orEmpty(),
                areaId = ((map["areaId"] as? String) ?: (map["cityId"] as? String))?.trim().orEmpty(),
                address = (map["address"] as? String).orEmpty(),
                genderId = (map["genderId"] as? String) ?: "Male",
                bazamId = (map["bazamId"] as? String).orEmpty(),
                dateOfBaith = dateOnly((map["dateOfBaith"] as? String).orEmpty()),
                referenceName = (map["referenceName"] as? String).orEmpty(),
                isNafiAsbat = bool("isNafiAsbat"),
                isSahibEMehfil = bool("isSahibEMehfil"),
                createdDate = dateOnly((map["createdDate"] as? String).orEmpty()),
                modifiedDate = dateOnly((map["modifiedDate"] as? String).orEmpty()),
                isActive = map["isActive"]?.let {
                    when (it) {
                        is Boolean -> it
                        is String -> it.equals("true", ignoreCase = true)
                        else -> true
                    }
                } ?: true,
                addedByUid = (map["addedByUid"] as? String).orEmpty(),
                addedByName = (map["addedByName"] as? String).orEmpty(),
                approvalStatus = ApprovalStatus.fromString(map["approvalStatus"] as? String),
                approvedByUid = (map["approvedByUid"] as? String).orEmpty(),
                approvedByName = (map["approvedByName"] as? String).orEmpty(),
                approvedAt = dateOnly((map["approvedAt"] as? String).orEmpty()),
            )
        }
    }
}

enum class DuplicateSalikReason { Mobile, Name }

class DuplicateSalikException(val reason: DuplicateSalikReason) : Exception("Duplicate: $reason")

class SalikPermissionException(message: String) : Exception(message)

data class SalikDuplicateGroup(
    val id: String,
    val reasons: Set<DuplicateSalikReason>,
    val label: String,
    val saliks: List<Salik>,
)
