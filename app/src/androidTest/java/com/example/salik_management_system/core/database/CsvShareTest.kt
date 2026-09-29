package com.example.salik_management_system.core.database

import android.content.Intent
import android.net.Uri
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.salik_management_system.core.export.CsvShare
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class CsvShareTest {
    @Test fun attachmentIsReadableCsv() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val chooser = CsvShare.intent(context, "name,mobileNumber\nAli,03001234567\n")
        val send = chooser.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)!!
        assertEquals("text/csv", send.type)
        assertTrue(send.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0)
        val uri = send.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)!!
        val content = context.contentResolver.openInputStream(uri)!!.bufferedReader().use { it.readText() }
        assertEquals("\uFEFFname,mobileNumber\nAli,03001234567\n", content)
    }
}
