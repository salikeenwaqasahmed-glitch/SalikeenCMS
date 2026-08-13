package com.example.salik_management_system.features.settings.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.BuildConfig
import com.example.salik_management_system.core.config.AppConfig
import com.example.salik_management_system.features.settings.ui.viewmodel.SettingsViewModel
import com.example.salik_management_system.ui.components.IosCardSection
import com.example.salik_management_system.ui.components.IosSettingsRow
import com.example.salik_management_system.ui.components.ProfileHeaderCard
import com.example.salik_management_system.ui.theme.Dimens
import com.example.salik_management_system.ui.theme.brandSwitchColors
import com.example.salik_management_system.ui.theme.brandTopAppBarColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onLoggedOut: () -> Unit = {},
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val session = state.session

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text("Settings", fontWeight = FontWeight.SemiBold) },
                colors = brandTopAppBarColors(),
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Dimens.screenPadding)
                .padding(bottom = Dimens.xl),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupSpacing),
        ) {
            ProfileHeaderCard(
                name = session?.name ?: "—",
                roleLine = "Role: ${session?.role?.label ?: "—"} · ${session?.gender.orEmpty()}",
                online = state.isOnline,
                showDev = AppConfig.showDevBadge,
            )

            IosCardSection(title = "Appearance") {
                IosSettingsRow(
                    title = "Dark mode",
                    showDivider = false,
                    trailing = {
                        Switch(
                            checked = state.darkMode,
                            onCheckedChange = { viewModel.toggleDarkMode() },
                            colors = brandSwitchColors(),
                        )
                    },
                )
            }

            IosCardSection(title = "Data") {
                IosSettingsRow(
                    title = "Pending sync queue",
                    subtitle = "${state.pendingCount} items",
                    showDivider = true,
                )
                IosSettingsRow(
                    title = if (state.isSyncing) "Syncing…" else "Sync now",
                    enabled = state.isOnline && !state.isSyncing,
                    showChevron = true,
                    showDivider = true,
                    onClick = { viewModel.syncNow() },
                )
                IosSettingsRow(
                    title = "Export saliks (CSV)",
                    showChevron = true,
                    showDivider = true,
                    onClick = { viewModel.exportCsv { context.startActivity(it) } },
                )
                IosSettingsRow(
                    title = "Import contacts (preview)",
                    showChevron = true,
                    showDivider = state.contactPreview.isNotEmpty() || state.message != null,
                    onClick = { viewModel.importContactsStub() },
                )
                if (state.contactPreview.isNotEmpty()) {
                    IosSettingsRow(
                        title = state.contactPreview.joinToString("\n"),
                        subtitle = null,
                        showDivider = state.message != null,
                    )
                }
                state.message?.let { msg ->
                    IosSettingsRow(
                        title = msg,
                        showDivider = false,
                    )
                }
            }

            IosCardSection(title = "Account") {
                IosSettingsRow(
                    title = "Logout",
                    destructive = true,
                    showDivider = false,
                    onClick = {
                        viewModel.logout()
                        onLoggedOut()
                    },
                )
            }

            Text(
                text = buildString {
                    append("Salikeen CMS v")
                    append(BuildConfig.VERSION_NAME)
                    if (AppConfig.showDevBadge) append(" · DEV")
                },
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = Dimens.xs),
            )
        }
    }
}
