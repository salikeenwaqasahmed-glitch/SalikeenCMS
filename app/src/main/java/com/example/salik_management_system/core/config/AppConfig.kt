package com.example.salik_management_system.core.config

import com.example.salik_management_system.BuildConfig

object AppConfig {
    val env: String
        get() = BuildConfig.APP_ENV

    val isProd: Boolean
        get() = env.equals("prod", ignoreCase = true)

    val isDev: Boolean
        get() = !isProd

    /** Room database file name (parity with Flutter driftDbName). */
    val roomDbName: String
        get() = if (isProd) "salik_crm_local_prod" else "salik_crm_local_dev"

    /** Internal / log label. */
    val envLabel: String
        get() = if (isProd) "prod" else "dev"

    /** User-facing chip — only Dev shows a badge. */
    val showDevBadge: Boolean
        get() = isDev

    val envDisplayName: String
        get() = if (isProd) "Salikeen CMS" else "Dev App"

    val firebaseProjectId: String
        get() = if (isProd) "salikeencms-prod" else "salikeencms"

    val staffEmailDomain: String
        get() = if (isProd) "@cms.com" else "@dev.cms.com"

    /** Shared AES-256 field-crypto key (base64, 32 bytes). */
    val fieldCryptoKeyBase64: String
        get() = BuildConfig.FIELD_CRYPTO_KEY_BASE64
}
