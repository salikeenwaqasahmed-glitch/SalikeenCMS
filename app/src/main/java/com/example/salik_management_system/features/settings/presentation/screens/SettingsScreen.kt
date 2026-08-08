package com.example.salik_management_system.features.settings.presentation.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.features.settings.presentation.viewmodel.SettingsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onLoggedOut: () -> Unit = {},
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val session = state.session

    LaunchedEffect(session) {
        if (session == null) onLoggedOut()
    }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Settings") }) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text(session?.name ?: "—", style = MaterialTheme.typography.titleMedium)
                    Text(session?.email.orEmpty())
                    Text("Role: ${session?.role?.name ?: "—"} · Gender: ${session?.gender.orEmpty()}")
                    Text("Env: ${state.envLabel} · ${if (state.isOnline) "Online" else "Offline"}")
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text("Dark mode")
                Switch(
                    checked = state.darkMode,
                    onCheckedChange = { viewModel.toggleDarkMode() },
                )
            }

            Text("Pending sync queue: ${state.pendingCount}")
            Button(
                onClick = { viewModel.syncNow() },
                enabled = state.isOnline && !state.isSyncing,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(if (state.isSyncing) "Syncing…" else "Sync now")
            }

            OutlinedButton(
                onClick = { viewModel.exportCsv { context.startActivity(it) } },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("Export saliks (CSV)")
            }

            OutlinedButton(
                onClick = { viewModel.importContactsStub() },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("Import contacts (preview)")
            }

            if (state.contactPreview.isNotEmpty()) {
                Text(
                    state.contactPreview.joinToString("\n"),
                    style = MaterialTheme.typography.bodySmall,
                )
            }

            state.message?.let {
                Text(it, color = MaterialTheme.colorScheme.primary)
            }

            Button(
                onClick = {
                    viewModel.logout()
                    onLoggedOut()
                },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("Logout")
            }

            Text(
                "Salikeen CMS v1.0.0",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
