package com.example.salik_management_system.features.saliks.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.core.utils.ContactLauncher
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikProfileViewModel
import com.example.salik_management_system.ui.components.IosGroupedCard
import com.example.salik_management_system.ui.theme.Brand
import com.example.salik_management_system.ui.theme.Dimens
import com.example.salik_management_system.ui.theme.brandSwitchColors
import com.example.salik_management_system.ui.theme.brandTopAppBarColors

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
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text(salik?.name ?: "Salik Profile", fontWeight = FontWeight.SemiBold) },
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
                colors = brandTopAppBarColors(),
            )
        },
    ) { padding ->
        if (salik == null) {
            Column(
                modifier = Modifier.fillMaxSize().padding(padding).padding(Dimens.screenPadding),
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
                .padding(horizontal = Dimens.screenPadding, vertical = Dimens.md),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupSpacing),
        ) {
            IosGroupedCard {
                Column(modifier = Modifier.padding(Dimens.md), verticalArrangement = Arrangement.spacedBy(Dimens.md)) {
                    Field("Father Name", salik.fatherName)
                    Field("Mobile", salik.mobileNumber)
                    Field("WhatsApp", salik.whatsappNumber)
                    Field("Gender", salik.genderId)
                    salik.calculateAge()?.let { age ->
                        Field("Age", "$age yrs")
                    }
                    Field("Bazam", state.bazam?.bazamName ?: salik.bazamId)
                    Field("Area", state.area?.areaName ?: salik.areaId)
                    Field("Address", salik.address)
                    Field("Date of Baith", salik.dateOfBaith)
                    Field("Reference", salik.referenceName)
                }
            }

            IosGroupedCard {
                Column(modifier = Modifier.padding(Dimens.md), verticalArrangement = Arrangement.spacedBy(Dimens.md)) {
                    Field("Status", salik.approvalStatus.name)
                    Field("Nafi Asbat", if (salik.isNafiAsbat) "Yes" else "No")
                    Field("Sahib-e-Mehfil", if (salik.isSahibEMehfil) "Yes" else "No")
                    Field("Added by", salik.addedByName.ifEmpty { salik.addedByUid })
                }
            }

            if (state.canUpdate) {
                IosGroupedCard {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(Dimens.md),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text("Active Status", style = MaterialTheme.typography.bodyLarge)
                        Switch(
                            checked = salik.isActive,
                            onCheckedChange = viewModel::toggleActive,
                            enabled = salik.isApproved,
                            colors = brandSwitchColors()
                        )
                    }
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(Dimens.md), modifier = Modifier.fillMaxWidth()) {
                OutlinedButton(
                    onClick = {
                        ContactLauncher.callIntent(salik.mobileNumber)?.let {
                            context.startActivity(it)
                        }
                    },
                    modifier = Modifier.weight(1f).height(48.dp),
                    shape = MaterialTheme.shapes.small
                ) {
                    Icon(Icons.Filled.Call, contentDescription = null)
                    Spacer(modifier = Modifier.width(Dimens.xxs))
                    Text("Call")
                }
                Button(
                    onClick = {
                        ContactLauncher.whatsappIntent(salik.whatsappNumber.ifEmpty { salik.mobileNumber })
                            ?.let { context.startActivity(it) }
                    },
                    modifier = Modifier.weight(1f).height(48.dp),
                    shape = MaterialTheme.shapes.small,
                    colors = ButtonDefaults.buttonColors(containerColor = Brand.Green)
                ) {
                    Icon(Icons.Filled.Chat, contentDescription = null)
                    Spacer(modifier = Modifier.width(Dimens.xxs))
                    Text("WhatsApp")
                }
            }

            if (state.canApprove && salik.isPending) {
                Column(verticalArrangement = Arrangement.spacedBy(Dimens.sm)) {
                    Button(
                        onClick = viewModel::approve,
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = MaterialTheme.shapes.small,
                        colors = ButtonDefaults.buttonColors(containerColor = Brand.Green)
                    ) {
                        Text("Approve", fontWeight = FontWeight.SemiBold)
                    }
                    OutlinedButton(
                        onClick = viewModel::reject,
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = MaterialTheme.shapes.small
                    ) {
                        Text("Reject", fontWeight = FontWeight.SemiBold)
                    }
                }
            }

            state.message?.let {
                Text(
                    text = it,
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.padding(horizontal = Dimens.sm),
                    style = MaterialTheme.typography.bodyMedium
                )
            }
            
            Spacer(modifier = Modifier.height(Dimens.xl))
        }
    }
}

@Composable
private fun Field(label: String, value: String) {
    Column {
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value.ifEmpty { "—" }, style = MaterialTheme.typography.bodyLarge)
    }
}
