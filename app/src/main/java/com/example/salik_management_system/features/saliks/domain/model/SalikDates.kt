package com.example.salik_management_system.features.saliks.domain.model

import java.time.LocalDate
import java.time.Period
import java.time.format.DateTimeFormatter
import java.util.Locale

object SalikDates {
    private val displayFormatter: DateTimeFormatter =
        DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.getDefault())

    fun dateOnly(fullDate: String): String {
        return when {
            fullDate.contains("T") -> fullDate.substringBefore("T")
            fullDate.contains(" ") -> fullDate.substringBefore(" ")
            else -> fullDate
        }
    }

    fun parseBaithDate(dateStr: String): LocalDate? {
        val normalized = dateStr.trim().ifBlank { return null }
        return runCatching { LocalDate.parse(dateOnly(normalized)) }.getOrNull()
    }

    fun formatBaithDate(dateStr: String): String {
        val parsed = parseBaithDate(dateStr) ?: return dateStr.ifBlank { "—" }
        return displayFormatter.format(parsed)
    }

    fun formatBaithDuration(dateStr: String): String? {
        val baithDate = parseBaithDate(dateStr) ?: return null
        val period = Period.between(baithDate, LocalDate.now())
        return when {
            period.years > 0 -> "${period.years} years"
            period.months > 0 -> "${period.months} months"
            period.days > 0 -> "${period.days} days"
            else -> "Today"
        }
    }

    fun formatBaithDisplay(dateStr: String): String {
        if (dateStr.isBlank()) return "—"
        val formattedDate = formatBaithDate(dateStr)
        if (formattedDate == dateStr && parseBaithDate(dateStr) == null) return dateStr
        val duration = formatBaithDuration(dateStr)
        return if (duration != null) "$formattedDate · $duration" else formattedDate
    }
}

object SalikListFormatting {
    private fun String?.subtitlePartOrNull(): String? =
        this?.trim()?.takeIf { it.isNotEmpty() }

    fun directorySubtitle(
        salik: Salik,
        areaName: String,
        bazamName: String?,
    ): String {
        val phone = salik.mobileNumber.subtitlePartOrNull()
            ?: salik.whatsappNumber.subtitlePartOrNull()
        val baithPart = salik.dateOfBaith.subtitlePartOrNull()?.let {
            SalikDates.formatBaithDate(it).subtitlePartOrNull()
        }
        val rawParts = listOfNotNull(
            salik.fatherName.subtitlePartOrNull(),
            phone,
            areaName.subtitlePartOrNull(),
            bazamName.subtitlePartOrNull(),
            baithPart,
        )
        val seen = mutableSetOf<String>()
        val parts = rawParts.filter { part ->
            seen.add(part.lowercase())
        }
        return parts.joinToString(" · ")
    }
}
