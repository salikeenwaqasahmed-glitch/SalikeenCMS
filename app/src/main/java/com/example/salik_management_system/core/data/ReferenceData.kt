package com.example.salik_management_system.core.data

import com.example.salik_management_system.features.saliks.domain.model.Area
import com.example.salik_management_system.features.saliks.domain.model.Bazam
import com.example.salik_management_system.features.saliks.domain.model.kDefaultBazamId

import com.example.salik_management_system.features.saliks.domain.model.isDefaultBazam

val kBazams: List<Bazam> = listOf(
    Bazam(bazamId = kDefaultBazamId, bazamName = "i-10 / آئی ٹین"),
)

val kAreas: List<Area> = emptyList()

fun findBazam(bazamId: String): Bazam? =
    kBazams.firstOrNull { it.bazamId.equals(bazamId, ignoreCase = true) || (isDefaultBazam(bazamId) && isDefaultBazam(it.bazamId)) }

fun findBazamInList(bazamId: String, bazams: List<Bazam>): Bazam? =
    bazams.firstOrNull { it.bazamId.equals(bazamId, ignoreCase = true) || (isDefaultBazam(bazamId) && isDefaultBazam(it.bazamId)) } ?: findBazam(bazamId)

fun findArea(areaId: String): Area? =
    kAreas.firstOrNull { it.areaId == areaId }

fun findAreaInList(areaId: String, areas: List<Area>): Area? =
    areas.firstOrNull { it.areaId == areaId } ?: findArea(areaId)

fun resolveSalikBazamId(
    salikBazamId: String,
    areaId: String,
    areas: List<Area>? = null,
): String {
    val explicit = salikBazamId.trim()
    if (explicit.isNotEmpty()) return explicit
    val area = if (areas != null) findAreaInList(areaId, areas) else findArea(areaId)
    val fromArea = area?.bazamId?.trim().orEmpty()
    if (fromArea.isNotEmpty()) return fromArea
    return kDefaultBazamId
}
