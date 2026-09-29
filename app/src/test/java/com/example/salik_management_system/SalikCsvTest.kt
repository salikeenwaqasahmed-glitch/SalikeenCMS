package com.example.salik_management_system

import com.example.salik_management_system.core.export.SalikCsvImport
import com.example.salik_management_system.core.export.SalikCsvExport
import com.example.salik_management_system.features.saliks.domain.model.Salik
import org.junit.Assert.assertEquals
import org.junit.Test

class SalikCsvTest {
    @Test fun exportImportRoundTrip() {
        val salik = Salik.fromMap(mapOf(
            "name" to "Ali, \"Khan\"",
            "fatherName" to "والد",
            "mobileNumber" to "03001234567",
            "genderId" to "Male",
            "address" to "Line 1\nLine 2",
            "areaId" to "a1",
            "bazamId" to "b1",
        ))
        val row = SalikCsvImport.parse("\uFEFF" + SalikCsvExport.build(listOf(salik))).single()
        assertEquals(salik.name, row["name"])
        assertEquals(salik.fatherName, row["fatherName"])
        assertEquals(salik.address, row["address"])
        assertEquals("03001234567", row["mobileNumber"])
        assertEquals("a1", row["areaId"])
        assertEquals("b1", row["bazamId"])
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsUnclosedQuote() { SalikCsvImport.parse("name,mobileNumber,genderId\n\"bad,123,Male") }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsMissingColumns() { SalikCsvImport.parse("name\nAli") }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsMismatchedColumns() { SalikCsvImport.parse("name,mobileNumber,genderId\nAli,123") }

    @Test fun acceptsWindowsNewlinesAndEmptyValues() {
        val row = SalikCsvImport.parse("name,mobileNumber,genderId,address\r\nAli,03001234567,Male,\r\n").single()
        assertEquals("", row["address"])
    }
}
