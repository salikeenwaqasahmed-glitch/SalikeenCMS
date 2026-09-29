package com.example.salik_management_system.features.saliks.domain.model

/** Default bazam assigned to seeded areas and new areas without an explicit id. */
const val kDefaultBazamId = "bazamId3"

fun isDefaultBazam(bazamId: String?, bazamName: String? = null): Boolean {
    if (bazamId.isNullOrBlank()) return true
    val id = bazamId.trim()
    if (id.equals("bazamId3", ignoreCase = true) || id.equals("i-10", ignoreCase = true)) return true
    if (bazamName != null && bazamName.contains("i-10", ignoreCase = true)) return true
    return false
}

data class Bazam(
    val bazamId: String,
    val bazamName: String,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "bazamId" to bazamId,
        "bazamName" to bazamName,
    )

    companion object {
        fun fromMap(map: Map<String, Any?>, id: String? = null): Bazam {
            val bazamId = (map["bazamId"] as? String) ?: id
            require(!bazamId.isNullOrEmpty()) { "Bazam document missing bazamId" }
            return Bazam(
                bazamId = bazamId,
                bazamName = (map["bazamName"] as? String)?.trim()?.ifEmpty { null } ?: bazamId,
            )
        }
    }
}
