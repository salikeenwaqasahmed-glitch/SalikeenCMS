package com.example.salik_management_system.core.utils

import android.content.Context
import android.content.Intent
import android.net.Uri

object ContactLauncher {
    fun digitsOnly(phone: String): String = phone.replace(Regex("[^0-9]"), "")

    fun callIntent(phone: String): Intent? {
        val digits = digitsOnly(phone)
        if (digits.isEmpty()) return null
        return Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + (if (phone.trim().startsWith("+")) "+" else "") + digits))
    }

    fun smsIntent(phone: String, body: String? = null): Intent? {
        val digits = digitsOnly(phone)
        if (digits.isEmpty()) return null
        val uri = if (body.isNullOrBlank()) {
            Uri.parse("sms:" + (if (phone.trim().startsWith("+")) "+" else "") + digits)
        } else {
            Uri.parse("sms:" + (if (phone.trim().startsWith("+")) "+" else "") + digits).buildUpon().appendQueryParameter("body", body).build()
        }
        return Intent(Intent.ACTION_SENDTO, uri)
    }

    fun whatsappIntent(phone: String, text: String? = null): Intent? {
        val digits = digitsOnly(phone)
        if (digits.isEmpty()) return null
        val builder = Uri.parse("https://wa.me/$digits").buildUpon()
        if (!text.isNullOrBlank()) builder.appendQueryParameter("text", text)
        return Intent(Intent.ACTION_VIEW, builder.build())
    }

    fun launch(context: Context, intent: Intent?): Boolean {
        if (intent == null) return false
        return runCatching {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }.isSuccess
    }
}
