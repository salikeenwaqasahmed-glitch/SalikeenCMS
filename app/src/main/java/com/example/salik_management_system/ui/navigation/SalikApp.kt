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
import com.example.salik_management_system.auth.presentation.viewmodel.AuthViewModel
import com.example.salik_management_system.core.sync.SyncViewModel
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
            popUpTo(0) { inclusive = true }
            launchSingleTop = true
        }
    }

    fun goDashboard() {
        navController.navigate(SalikRoutes.Dashboard) {
            popUpTo(SalikRoutes.Login) { inclusive = true }
            launchSingleTop = true
        }
    }

    LaunchedEffect(uiState.isBootstrapping, session?.uid) {
        if (uiState.isBootstrapping) return@LaunchedEffect
        if (session != null) {
            val current = navController.currentDestination?.route
            if (current == SalikRoutes.Login || current == null) {
                goDashboard()
            }
        } else {
            val current = navController.currentDestination?.route
            if (current != null && current != SalikRoutes.Login) {
                goLogin()
            }
        }
    }

    SalikTheme(darkTheme = darkTheme) {
        SalikNavGraph(
            navController = navController,
            startDestination = SalikRoutes.Login,
            snackbarHostState = snackbarHostState,
            isOnline = isOnline,
            isSyncing = syncState.isSyncing,
            onSync = {
                syncViewModel.syncNow { result ->
                    scope.launch {
                        snackbarHostState.showSnackbar(result.message)
                    }
                }
            },
            onLoggedIn = { goDashboard() },
            onLoggedOut = { goLogin() },
        )
    }
}
