package com.example.salik_management_system.core.export

import com.example.salik_management_system.features.saliks.domain.Area
import com.example.salik_management_system.features.saliks.domain.Salik

object SalikCsvExport {
    fun build(saliks: List<Salik>, areaLookup: Map<String, Area> = emptyMap()): String {
        val sb = StringBuilder()
        sb.appendLine(
            listOf(
                "name",
                "fatherName",
                "mobileNumber",
                "whatsappNumber",
                "genderId",
                "area",
                "address",
                "referenceName",
                "dateOfBaith",
                "approvalStatus",
                "isActive",
                "isNafiAsbat",
                "isSahibEMehfil",
            ).joinToString(","),
        )
        for (s in saliks) {
            val areaLabel = areaLookup[s.areaId]?.areaName ?: s.areaId
            sb.appendLine(
                listOf(
                    esc(s.name),
                    esc(s.fatherName),
                    esc(s.mobileNumber),
                    esc(s.whatsappNumber),
                    esc(s.genderId),
                    esc(areaLabel),
                    esc(s.address),
                    esc(s.referenceName),
                    esc(s.dateOfBaith),
                    esc(s.approvalStatus.toFirestore()),
                    if (s.isActive) "true" else "false",
                    if (s.isNafiAsbat) "true" else "false",
                    if (s.isSahibEMehfil) "true" else "false",
                ).joinToString(","),
            )
        }
        return sb.toString()
    }

    private fun esc(value: String): String {
        val escaped = value.replace("\"", "\"\"")
        return if (escaped.contains(',') || escaped.contains('"') ||
            escaped.contains('\n') || escaped.contains('\r')
        ) {
            "\"$escaped\""
        } else {
            escaped
        }
    }
}
