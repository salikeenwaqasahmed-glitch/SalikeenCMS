package com.example.salik_management_system.core.utils

import android.util.Log
import com.example.salik_management_system.BuildConfig

/**
 * App-wide logging — filter Logcat with tag **SalikCMS** only.
 *
 * ```
 * adb logcat -s SalikCMS
 * ```
 *
 * Component name lives in message prefix: `[Sync] …`, `[Auth] …`
 */
object AppLog {
    /** Single Logcat tag for the whole app. */
    const val TAG = "SalikCMS"

    fun trace(area: String, message: String) {
        d(area, message)
    }

    fun d(area: String, message: String) {
        if (BuildConfig.DEBUG) {
            Log.d(TAG, format(area, message))
        }
    }

    fun i(area: String, message: String) {
        Log.i(TAG, format(area, message))
    }

    fun w(area: String, message: String) {
        Log.w(TAG, format(area, message))
    }

    fun e(area: String, message: String, throwable: Throwable? = null) {
        Log.e(TAG, format(area, message), throwable)
    }

    private fun format(area: String, message: String): String = "[$area] $message"
}
