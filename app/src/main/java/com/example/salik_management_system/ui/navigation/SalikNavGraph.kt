package com.example.salik_management_system.ui.navigation

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.dp
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.navArgument
import com.example.salik_management_system.auth.ui.screens.LoginScreen
import com.example.salik_management_system.features.dashboard.ui.screens.DashboardScreen
import com.example.salik_management_system.features.saliks.ui.screens.AddEditSalikScreen
import com.example.salik_management_system.features.saliks.ui.screens.BazamAreasScreen
import com.example.salik_management_system.features.saliks.ui.screens.DuplicateSaliksScreen
import com.example.salik_management_system.features.saliks.ui.screens.PendingApprovalsScreen
import com.example.salik_management_system.features.saliks.ui.screens.SalikDirectoryScreen
import com.example.salik_management_system.features.saliks.ui.screens.SalikMessageQueueScreen
import com.example.salik_management_system.features.saliks.ui.screens.SalikProfileScreen
import com.example.salik_management_system.features.settings.ui.screens.SettingsScreen
import com.example.salik_management_system.ui.components.OfflineBanner
import com.example.salik_management_system.ui.theme.Brand
import com.example.salik_management_system.ui.theme.brandNavItemColors

@Composable
fun SalikNavGraph(
    navController: NavHostController,
    startDestination: String,
    snackbarHostState: SnackbarHostState,
    isOnline: Boolean,
    isSyncing: Boolean,
    onSync: () -> Unit,
    onLoggedIn: () -> Unit,
    onLoggedOut: () -> Unit,
) {
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val showBottomBar = SalikRoutes.showsBottomBar(currentRoute)

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        contentColor = MaterialTheme.colorScheme.onBackground,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            if (showBottomBar) {
                Column {
                    if (isSyncing) {
                        LinearProgressIndicator(
                            modifier = Modifier.fillMaxWidth(),
                            color = MaterialTheme.colorScheme.primary,
                            trackColor = MaterialTheme.colorScheme.primaryContainer,
                        )
                    }
                    SalikBottomBar(
                        currentRoute = currentRoute,
                        onNavigate = { route ->
                            navController.navigate(route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        onSync = onSync,
                    )
                }
            }
        },
    ) { padding ->
        val layoutDirection = LocalLayoutDirection.current
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(
                    start = padding.calculateStartPadding(layoutDirection),
                    end = padding.calculateEndPadding(layoutDirection),
                    bottom = padding.calculateBottomPadding(),
                )
        ) {
            if (!isOnline) {
                OfflineBanner(modifier = Modifier.statusBarsPadding())
            }
            NavHost(
                navController = navController,
                startDestination = startDestination,
            ) {
                composable(SalikRoutes.Login) {
                    LoginScreen(onLoggedIn = onLoggedIn)
                }
                composable(SalikRoutes.Dashboard) {
                    DashboardScreen(
                        onAddSalik = { navController.navigate(SalikRoutes.SalikAdd) },
                        onOpenBazam = { id -> navController.navigate(SalikRoutes.bazams(id)) },
                        onOpenPending = { navController.navigate(SalikRoutes.SalikPending) },
                        onOpenSaliks = {
                            navController.navigate(SalikRoutes.Saliks) {
                                launchSingleTop = true
                            }
                        },
                    )
                }
                composable(
                    route = SalikRoutes.Bazams,
                    arguments = listOf(navArgument("bazamId") { type = NavType.StringType }),
                ) { entry ->
                    val bazamId = entry.arguments?.getString("bazamId").orEmpty()
                    BazamAreasScreen(
                        bazamId = bazamId,
                        onBack = { navController.popBackStack() },
                        onOpenDirectory = {
                            navController.navigate(SalikRoutes.Saliks) {
                                launchSingleTop = true
                            }
                        },
                    )
                }
                composable(SalikRoutes.Saliks) {
                    SalikDirectoryScreen(
                        onOpenProfile = { id ->
                            navController.navigate(SalikRoutes.salikProfile(id))
                        },
                        onAdd = { navController.navigate(SalikRoutes.SalikAdd) },
                        onOpenPending = { navController.navigate(SalikRoutes.SalikPending) },
                        onOpenDuplicates = {
                            navController.navigate(SalikRoutes.SalikDuplicates)
                        },
                        onOpenMessageQueue = {
                            navController.navigate(SalikRoutes.SalikMessageQueue)
                        },
                    )
                }
                composable(
                    route = SalikRoutes.SalikProfile,
                    arguments = listOf(navArgument("id") { type = NavType.StringType }),
                ) { entry ->
                    val id = entry.arguments?.getString("id").orEmpty()
                    SalikProfileScreen(
                        salikId = id,
                        onEdit = { navController.navigate(SalikRoutes.salikEdit(it)) },
                        onBack = { navController.popBackStack() },
                        onDeleted = { navController.popBackStack() },
                    )
                }
                composable(SalikRoutes.SalikAdd) {
                    AddEditSalikScreen(
                        onBack = { navController.popBackStack() },
                        onSaved = { _ ->
                            navController.navigate(SalikRoutes.Saliks) {
                                popUpTo(SalikRoutes.Dashboard) { inclusive = false }
                                launchSingleTop = true
                            }
                        },
                    )
                }
                composable(
                    route = SalikRoutes.SalikEdit,
                    arguments = listOf(navArgument("id") { type = NavType.StringType }),
                ) { entry ->
                    val id = entry.arguments?.getString("id")
                    AddEditSalikScreen(
                        salikId = id,
                        onBack = { navController.popBackStack() },
                        onSaved = { _ ->
                            navController.navigate(SalikRoutes.Saliks) {
                                popUpTo(SalikRoutes.Dashboard) { inclusive = false }
                                launchSingleTop = true
                            }
                        },
                    )
                }
                composable(SalikRoutes.SalikPending) {
                    PendingApprovalsScreen(
                        onOpenProfile = { id ->
                            navController.navigate(SalikRoutes.salikProfile(id))
                        },
                        onBack = { navController.popBackStack() },
                    )
                }
                composable(SalikRoutes.SalikDuplicates) {
                    DuplicateSaliksScreen(onBack = { navController.popBackStack() })
                }
                composable(SalikRoutes.SalikMessageQueue) {
                    SalikMessageQueueScreen(onBack = { navController.popBackStack() })
                }
                composable(SalikRoutes.Settings) {
                    SettingsScreen(onLoggedOut = onLoggedOut)
                }
            }
        }
    }
}

private data class BottomItem(
    val route: String,
    val label: String,
    val icon: ImageVector,
)

@Composable
private fun SalikBottomBar(
    currentRoute: String?,
    onNavigate: (String) -> Unit,
    onSync: () -> Unit,
) {
    val items = listOf(
        BottomItem(SalikRoutes.Dashboard, "Dashboard", Icons.Filled.Home),
        BottomItem(SalikRoutes.Saliks, "Saliks", Icons.Filled.Person),
        BottomItem(SalikRoutes.Settings, "Settings", Icons.Filled.Settings),
    )

    val itemColors = brandNavItemColors()
    NavigationBar(
        containerColor = Brand.Surface,
        contentColor = Brand.OnSurface,
        tonalElevation = 0.dp,
    ) {
        items.forEach { item ->
            NavigationBarItem(
                selected = currentRoute == item.route,
                onClick = { onNavigate(item.route) },
                icon = { Icon(item.icon, contentDescription = item.label) },
                label = { Text(item.label) },
                colors = itemColors,
            )
        }
        NavigationBarItem(
            selected = false,
            onClick = onSync,
            icon = { Icon(Icons.Filled.Refresh, contentDescription = "Sync") },
            label = { Text("Sync") },
            colors = itemColors,
        )
    }
}
