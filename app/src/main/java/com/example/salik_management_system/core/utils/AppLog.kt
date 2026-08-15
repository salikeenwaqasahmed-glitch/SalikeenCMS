package com.example.salik_management_system.core.utils

import android.util.Log
import com.example.salik_management_system.BuildConfig

/**
 * Centralized logging utility for Salikeen CMS.
 * Automatically handles tags and debug-only filtering.
 */
object AppLog {
    private const val GLOBAL_TAG = "SalikCMS"

    fun d(tag: String, message: String) {
        if (BuildConfig.DEBUG) {
            Log.d("$GLOBAL_TAG:$tag", message)
        }
    }

    fun e(tag: String, message: String, throwable: Throwable? = null) {
        Log.e("$GLOBAL_TAG:$tag", message, throwable)
    }

    fun i(tag: String, message: String) {
        Log.i("$GLOBAL_TAG:$tag", message)
    }

    fun w(tag: String, message: String) {
        Log.w("$GLOBAL_TAG:$tag", message)
    }
}
