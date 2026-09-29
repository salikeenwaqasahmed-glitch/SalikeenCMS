package com.example.salik_management_system

import android.app.Application
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.core.sync.SyncService
import com.example.salik_management_system.core.config.AppConfig
import com.example.salik_management_system.core.utils.AppLog
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltAndroidApp
class SalikApplication : Application() {

    @Inject
    lateinit var authRepository: AuthRepository

    @Inject
    lateinit var syncService: SyncService

    // Global scope for application-level background tasks
    private val applicationScope = MainScope()

    override fun onCreate() {
        super.onCreate()
        
        AppLog.i("App", "Salikeen CMS starting (env=${AppConfig.envLabel}, project=${AppConfig.firebaseProjectId})")

        // Major background initializations after Hilt injection
        applicationScope.launch {
            bootstrapApplication()
        }
    }

    private suspend fun bootstrapApplication() {
        AppLog.d("App", "Bootstrap: fetchSession")
        
        try {
            // 1. Warm up session / user profile to ensure data is ready for screens
            authRepository.fetchSession()
            
            AppLog.i("App", "Bootstrap complete")
        } catch (e: Exception) {
            AppLog.e("App", "Bootstrap failed: ${e.message}", e)
        }
    }
}
