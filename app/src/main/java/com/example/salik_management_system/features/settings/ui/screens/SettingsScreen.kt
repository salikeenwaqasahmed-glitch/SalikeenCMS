package com.example.salik_management_system.features.settings.ui.screens

import android.app.Activity
import android.content.Intent
import android.provider.ContactsContract
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.TextButton
import com.example.salik_management_system.core.utils.AccessControl
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
    onImportContact: (String, String) -> Unit = { _, _ -> },
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val session = state.session
    val csvPicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) {
        it?.let(viewModel::previewCsv)
    }
    val contactPicker = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            result.data?.data?.let { uri ->
                runCatching {
                    context.contentResolver.query(uri, arrayOf(
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                        ContactsContract.CommonDataKinds.Phone.NUMBER,
                    ), null, null, null)?.use { cursor ->
                        if (cursor.moveToFirst()) onImportContact(cursor.getString(0).orEmpty(), cursor.getString(1).orEmpty())
                    }
                }.onFailure { viewModel.reportMessage("Cannot open contact") }
            }
        }
    }
    if (state.contactPreview.isNotEmpty()) {
        AlertDialog(
            onDismissRequest = viewModel::cancelImport,
            title = { Text("Import Saliks?") },
            text = { Text(state.contactPreview.joinToString("\n")) },
            confirmButton = {
                TextButton(onClick = viewModel::confirmImport, enabled = !state.importBusy) {
                    Text(if (state.importBusy) "Importing…" else "Import")
                }
            },
            dismissButton = { TextButton(onClick = viewModel::cancelImport, enabled = !state.importBusy) { Text("Cancel") } },
        )
    }

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
                if (session != null && AccessControl.canCreate(session.role)) {
                    IosSettingsRow(
                        title = if (state.importBusy) "Reading / importing…" else "Import saliks (CSV)",
                        subtitle = "Use exported CSV columns. Review before saving.",
                        enabled = !state.importBusy,
                        onClick = { csvPicker.launch(arrayOf("text/*", "application/csv", "application/vnd.ms-excel")) },
                    )
                    IosSettingsRow(
                        title = "Import contact",
                        subtitle = "Choose a phone number, complete details, then save.",
                        onClick = {
                            runCatching { contactPicker.launch(Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)) }
                                .onFailure { viewModel.reportMessage("No contacts app available") }
                        },
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
