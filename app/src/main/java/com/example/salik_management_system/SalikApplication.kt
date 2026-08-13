package com.example.salik_management_system

import android.app.Application
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.core.sync.SyncService
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
        
        AppLog.i("Application", "Salikeen CMS starting...")

        // Major background initializations after Hilt injection
        applicationScope.launch {
            bootstrapApplication()
        }
    }

    private suspend fun bootstrapApplication() {
        AppLog.d("Application", "Bootstrapping major services...")
        
        try {
            // 1. Warm up session / user profile to ensure data is ready for screens
            authRepository.fetchSession()
            
            // 2. Perform initial background sync if device is online
            syncService.syncNow()
            
            AppLog.i("Application", "Bootstrap complete")
        } catch (e: Exception) {
            AppLog.e("Application", "Bootstrap failed: ${e.message}", e)
        }
    }
}
