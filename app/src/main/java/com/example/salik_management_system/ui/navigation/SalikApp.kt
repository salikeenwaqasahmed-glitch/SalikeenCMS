package com.example.salik_management_system.ui.navigation

import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.rememberNavController
import com.example.salik_management_system.auth.ui.viewmodel.AuthViewModel
import com.example.salik_management_system.core.sync.SyncViewModel
import com.example.salik_management_system.core.utils.AppLog
import com.example.salik_management_system.ui.theme.SalikTheme
import com.example.salik_management_system.ui.theme.ThemeViewModel
import kotlinx.coroutines.launch

@Composable
fun SalikApp(
    authViewModel: AuthViewModel = hiltViewModel(),
    syncViewModel: SyncViewModel = hiltViewModel(),
    themeViewModel: ThemeViewModel = hiltViewModel(),
) {
    val navController = rememberNavController()
    val session by authViewModel.session.collectAsStateWithLifecycle()
    val uiState by authViewModel.uiState.collectAsStateWithLifecycle()
    val syncState by syncViewModel.uiState.collectAsStateWithLifecycle()
    val isOnline by syncViewModel.isOnline.collectAsStateWithLifecycle()
    val darkTheme by themeViewModel.darkTheme.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    fun goLogin() {
        navController.navigate(SalikRoutes.Login) {
            popUpTo(navController.graph.id) { inclusive = true }
            launchSingleTop = true
        }
    }

    fun goDashboard() {
        navController.navigate(SalikRoutes.Dashboard) {
            popUpTo(navController.graph.id) { inclusive = true }
            launchSingleTop = true
        }
    }


    LaunchedEffect(uiState.isBootstrapping, session?.uid) {
        if (uiState.isBootstrapping) return@LaunchedEffect
        val active = session
        if (active != null) {
            val current = navController.currentDestination?.route
            AppLog.d("Nav", "session active uid=${active.uid} route=$current → dashboard")
            if (current == SalikRoutes.Login || current == null) {
                goDashboard()
            }
        } else {
            val current = navController.currentDestination?.route
            AppLog.d("Nav", "no session route=$current → login")
            if (current != null && current != SalikRoutes.Login) {
                goLogin()
            }
        }
    }

    LaunchedEffect(uiState.offlineReadyMessage) {
        val msg = uiState.offlineReadyMessage ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(msg)
        authViewModel.clearOfflineReadyMessage()
    }

    SalikTheme(darkTheme = darkTheme) {
        SalikNavGraph(
            navController = navController,
            startDestination = SalikRoutes.Login,
            snackbarHostState = snackbarHostState,
            isOnline = isOnline,
            isSyncing = syncState.isSyncing,
            onSync = {
                AppLog.i("Sync", "manual sync from nav")
                syncViewModel.syncNow { result ->
                    scope.launch {
                        snackbarHostState.currentSnackbarData?.dismiss()
                        snackbarHostState.showSnackbar(if (result.ok) "Sync complete" else "Sync failed. Check connection and retry.")
                    }
                }
            },
            onLoggedIn = { goDashboard() },
            onLoggedOut = { goLogin() },
        )
    }
}
