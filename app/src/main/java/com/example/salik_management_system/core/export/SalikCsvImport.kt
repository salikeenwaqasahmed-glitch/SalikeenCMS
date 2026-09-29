package com.example.salik_management_system.core.export

/** Strict CSV reader supporting escaped quotes and multiline fields. */
object SalikCsvImport {
    fun parse(text: String): List<Map<String, String>> {
        val rows = mutableListOf<List<String>>()
        var row = mutableListOf<String>()
        val field = StringBuilder()
        var quoted = false
        var closed = false
        var i = 0
        val input = text.removePrefix("\uFEFF")
        fun finishField() { row.add(field.toString()); field.clear(); closed = false }
        fun finishRow() {
            finishField()
            if (row.any { it.isNotBlank() }) rows.add(row)
            row = mutableListOf()
        }
        while (i < input.length) {
            val c = input[i]
            if (quoted) {
                if (c == '"') {
                    if (i + 1 < input.length && input[i + 1] == '"') {
                        field.append('"'); i++
                    } else { quoted = false; closed = true }
                } else field.append(c)
            } else {
                when (c) {
                    '"' -> { require(field.isEmpty() && !closed) { "Invalid CSV quote" }; quoted = true }
                    ',' -> finishField()
                    '\n', '\r' -> {
                        finishRow()
                        if (c == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++
                    }
                    else -> { require(!closed) { "Unexpected text after quote" }; field.append(c) }
                }
            }
            i++
        }
        require(!quoted) { "Unclosed CSV quote" }
        if (field.isNotEmpty() || row.isNotEmpty() || closed) finishRow()
        require(rows.isNotEmpty()) { "CSV is empty" }
        val headers = rows.first().map { it.trim() }
        require(headers.distinct().size == headers.size) { "Duplicate CSV headers" }
        require(headers.containsAll(listOf("name", "mobileNumber", "genderId"))) {
            "Required columns: name, mobileNumber, genderId"
        }
        return rows.drop(1).mapIndexed { index, values ->
            require(values.size == headers.size) { "Row ${index + 2}: wrong column count" }
            headers.zip(values).toMap()
        }
    }
}
