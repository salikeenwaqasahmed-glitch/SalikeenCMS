package com.example.salik_management_system.core.export

import android.content.ClipData
import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File

object CsvShare {
    fun intent(context: Context, csv: String): Intent {
        val directory = File(context.cacheDir, "exports").apply { mkdirs() }
        val file = File.createTempFile("saliks-", ".csv", directory)
        file.writeText("\uFEFF" + csv, Charsets.UTF_8)
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.exports", file)
        return Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
            type = "text/csv"
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newRawUri("Saliks CSV", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }, "Export CSV")
    }
}
