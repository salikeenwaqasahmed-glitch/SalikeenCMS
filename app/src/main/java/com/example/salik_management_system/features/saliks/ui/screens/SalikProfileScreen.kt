package com.example.salik_management_system.features.saliks.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Assignment
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Person
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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.TextButton
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.core.utils.ContactLauncher
import com.example.salik_management_system.features.saliks.domain.model.SalikDates
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikProfileViewModel
import com.example.salik_management_system.ui.components.InlineDetailRow
import com.example.salik_management_system.ui.components.IosGroupedCard
import com.example.salik_management_system.ui.components.StatusChip
import com.example.salik_management_system.ui.components.shimmerLoadingAnimation
import com.example.salik_management_system.ui.components.StatusTone
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
    var confirmDelete by remember { mutableStateOf(false) }
    val salik = state.salik
    val context = LocalContext.current
    val brandGreen = if (isSystemInDarkTheme()) Brand.GreenDark else Brand.Green

    LaunchedEffect(state.message) {
        if (state.message == "Deleted") onDeleted()
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete Salik?") },
            text = { Text("Delete this record locally and queue its deletion for the next sync?") },
            confirmButton = { TextButton(onClick = { confirmDelete = false; viewModel.delete() }) { Text("Delete") } },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("Cancel") } },
        )
    }
    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text("Salik Profile", fontWeight = FontWeight.SemiBold) },
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
                        IconButton(onClick = { confirmDelete = true }) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete")
                        }
                    }
                },
                colors = brandTopAppBarColors(),
            )
        },
    ) { padding ->
        if (state.isLoading) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(Dimens.screenPadding),
                verticalArrangement = Arrangement.spacedBy(Dimens.groupSpacing)
            ) {
                // Shimmer header
                Spacer(modifier = Modifier.height(Dimens.md))
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .align(Alignment.CenterHorizontally)
                        .clip(CircleShape)
                        .shimmerLoadingAnimation()
                )
                // Shimmer cards
                repeat(3) {
                    IosGroupedCard {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(150.dp)
                                .shimmerLoadingAnimation()
                        )
                    }
                }
            }
            return@Scaffold
        }

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

        val baithDisplay = remember(salik.dateOfBaith, salik.calculateAge()) {
            val base = SalikDates.formatBaithDisplay(salik.dateOfBaith)
            val age = salik.calculateAge()
            if (age != null) "$base · Age $age" else base
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Dimens.screenPadding, vertical = Dimens.md),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupSpacing),
        ) {
            // Header Section
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(brandGreen),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = salik.name.take(1).uppercase(),
                        style = MaterialTheme.typography.headlineLarge,
                        color = Brand.Gold,
                        fontWeight = FontWeight.Bold
                    )
                }
                Spacer(modifier = Modifier.height(Dimens.sm))
                Text(
                    text = salik.name,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "${salik.fatherName}'s Son",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(Dimens.xs))
                StatusChip(
                    label = salik.approvalStatus.name,
                    tone = when (salik.approvalStatus.name) {
                        "Approved" -> StatusTone.Success
                        "Rejected" -> StatusTone.Danger
                        else -> StatusTone.Warning
                    }
                )
            }

            // Quick Actions
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
                    Icon(Icons.Filled.Call, contentDescription = null, modifier = Modifier.size(18.dp))
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
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Brand.Green,
                        contentColor = Brand.Gold
                    )
                ) {
                    Icon(Icons.Filled.Chat, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(Dimens.xxs))
                    Text("WhatsApp")
                }
            }

            SectionTitle("Personal Information", Icons.Default.Person, brandGreen)
            IosGroupedCard {
                Column(modifier = Modifier.padding(vertical = Dimens.xs)) {
                    InlineDetailRow("Father Name", salik.fatherName)
                    InlineDetailRow("Mobile", salik.mobileNumber)
                    InlineDetailRow("WhatsApp", salik.whatsappNumber)
                    InlineDetailRow("Gender", salik.genderId)
                    InlineDetailRow("Reference", salik.referenceName, isLast = true)
                }
            }

            SectionTitle("Location & Bazam", Icons.Default.LocationOn, brandGreen)
            IosGroupedCard {
                Column(modifier = Modifier.padding(vertical = Dimens.xs)) {
                    InlineDetailRow("Bazam", state.bazam?.bazamName ?: salik.bazamId)
                    InlineDetailRow("Area", state.area?.areaName ?: salik.areaId)
                    InlineDetailRow("Address", salik.address, isLast = true)
                }
            }

            SectionTitle("Salik Details", Icons.Default.Assignment, brandGreen)
            IosGroupedCard {
                Column(modifier = Modifier.padding(vertical = Dimens.xs)) {
                    InlineDetailRow("Date of Baith", baithDisplay)
                    InlineDetailRow("Nafi Asbat", if (salik.isNafiAsbat) "Yes" else "No")
                    InlineDetailRow("Sahib-e-Mehfil", if (salik.isSahibEMehfil) "Yes" else "No")
                    InlineDetailRow("Added by", salik.addedByName.ifEmpty { salik.addedByUid }, isLast = true)
                }
            }

            if (state.canUpdate) {
                SectionTitle("Settings", Icons.Default.Badge, brandGreen)
                IosGroupedCard {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(Dimens.md),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column {
                            Text("Active Status", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
                            Text(
                                if (salik.isActive) "Visible in directory" else "Hidden from directory",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Switch(
                            checked = salik.isActive,
                            onCheckedChange = viewModel::toggleActive,
                            enabled = salik.isApproved,
                            colors = brandSwitchColors()
                        )
                    }
                }
            }

            if (state.canApprove && salik.isPending) {
                Column(verticalArrangement = Arrangement.spacedBy(Dimens.sm)) {
                    Button(
                        onClick = viewModel::approve,
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = MaterialTheme.shapes.small,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Brand.Green,
                            contentColor = Brand.Gold
                        )
                    ) {
                        Text("Approve Salik", fontWeight = FontWeight.SemiBold)
                    }
                    OutlinedButton(
                        onClick = viewModel::reject,
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = MaterialTheme.shapes.small
                    ) {
                        Text("Reject Registration", fontWeight = FontWeight.SemiBold)
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
private fun SectionTitle(title: String, icon: ImageVector, tint: Color) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(start = Dimens.xs, top = Dimens.xs)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = tint
        )
        Spacer(modifier = Modifier.width(Dimens.xs))
        Text(
            text = title.uppercase(),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.sp
        )
    }
}
