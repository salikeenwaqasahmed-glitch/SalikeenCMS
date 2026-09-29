package com.example.salik_management_system.features.saliks.domain.model

import com.example.salik_management_system.features.saliks.domain.model.kDefaultBazamId

data class Area(
    val areaId: String,
    val areaName: String,
    val bazamId: String = kDefaultBazamId,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "areaId" to areaId,
        "areaName" to areaName,
        "bazamId" to bazamId.ifEmpty { kDefaultBazamId },
    )

    companion object {
        fun fromMap(map: Map<String, Any?>, id: String? = null): Area {
            val areaId = (map["areaId"] as? String) ?: id
            require(!areaId.isNullOrEmpty()) { "Area document missing areaId" }
            val rawBazam = (map["bazamId"] as? String)?.trim().orEmpty()
            val primary = (map["areaName"] as? String).orEmpty()
            val secondary = (map["areaNameUrdu"] as? String).orEmpty()
            val name = when {
                primary.isNotEmpty() && secondary.isNotEmpty() && primary != secondary ->
                    "$primary / $secondary"
                primary.isNotEmpty() -> primary
                else -> secondary
            }
            return Area(
                areaId = areaId,
                areaName = name,
                bazamId = rawBazam.ifEmpty { kDefaultBazamId },
            )
        }
    }
}
