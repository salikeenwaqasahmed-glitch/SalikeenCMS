package com.example.salik_management_system.features.saliks.presentation.screens

import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import com.example.salik_management_system.core.utils.ContactLauncher
import com.example.salik_management_system.features.saliks.presentation.viewmodel.SalikProfileViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SalikProfileScreen(
    salikId: String,
    onEdit: (String) -> Unit = {},
    onBack: () -> Unit = {},
    onDeleted: () -> Unit = {},
    viewModel: SalikProfileViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val salik = state.salik
    val context = LocalContext.current

    LaunchedEffect(state.message) {
        if (state.message == "Deleted") onDeleted()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(salik?.name ?: "Salik") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (state.canUpdate && salik != null) {
                        IconButton(onClick = { onEdit(salik.salikId) }) {
                            Icon(Icons.Filled.Edit, contentDescription = "Edit")
                        }
                    }
                    if (state.canDelete && salik != null) {
                        IconButton(onClick = viewModel::delete) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete")
                        }
                    }
                },
            )
        },
    ) { padding ->
        if (salik == null) {
            Column(
                modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("Salik not found ($salikId)")
            }
            return@Scaffold
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Field("Father", salik.fatherName)
            Field("Mobile", salik.mobileNumber)
            Field("WhatsApp", salik.whatsappNumber)
            Field("Gender", salik.genderId)
            Field("Area", state.area?.areaName ?: salik.areaId)
            Field("Address", salik.address)
            Field("Date of baith", salik.dateOfBaith)
            Field("Status", salik.approvalStatus.name)
            Field("Nafi Asbat", if (salik.isNafiAsbat) "Yes" else "No")
            Field("Sahib-e-Mehfil", if (salik.isSahibEMehfil) "Yes" else "No")
            Field("Added by", salik.addedByName.ifEmpty { salik.addedByUid })

            if (state.canUpdate) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Active")
                    Switch(
                        checked = salik.isActive,
                        onCheckedChange = viewModel::toggleActive,
                        enabled = salik.isApproved,
                    )
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick = {
                    ContactLauncher.callIntent(salik.mobileNumber)?.let {
                        context.startActivity(it)
                    }
                }) {
                    Icon(Icons.Filled.Call, contentDescription = null)
                    Text(" Call")
                }
                OutlinedButton(onClick = {
                    ContactLauncher.whatsappIntent(salik.whatsappNumber.ifEmpty { salik.mobileNumber })
                        ?.let { context.startActivity(it) }
                }) {
                    Icon(Icons.Filled.Chat, contentDescription = null)
                    Text(" WhatsApp")
                }
            }

            if (state.canApprove) {
                Spacer(Modifier.height(8.dp))
                Button(onClick = viewModel::approve, modifier = Modifier.fillMaxWidth()) {
                    Text("Approve")
                }
                OutlinedButton(onClick = viewModel::reject, modifier = Modifier.fillMaxWidth()) {
                    Text("Reject")
                }
            }

            state.message?.let {
                Text(it, color = MaterialTheme.colorScheme.primary)
            }
        }
    }
}

@Composable
private fun Field(label: String, value: String) {
    Column {
        Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value.ifEmpty { "—" }, style = MaterialTheme.typography.bodyLarge)
    }
}
