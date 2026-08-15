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
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
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
import androidx.compose.runtime.remember
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
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikProfileViewModel
import com.example.salik_management_system.ui.components.IosGroupedCard
import com.example.salik_management_system.ui.components.StatusChip
import com.example.salik_management_system.ui.components.shimmerLoadingAnimation
import com.example.salik_management_system.ui.components.StatusTone
import com.example.salik_management_system.ui.theme.Brand
import com.example.salik_management_system.ui.theme.Dimens
import com.example.salik_management_system.ui.theme.brandSwitchColors
import com.example.salik_management_system.ui.theme.brandTopAppBarColors
import java.time.LocalDate
import java.time.Period
import java.time.format.DateTimeFormatter

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
    val brandGreen = if (isSystemInDarkTheme()) Brand.GreenDark else Brand.Green

    LaunchedEffect(state.message) {
        if (state.message == "Deleted") onDeleted()
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
                        IconButton(onClick = viewModel::delete) {
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

        val connectionInfo = remember(salik.dateOfBaith) {
            calculateConnectionTime(salik.dateOfBaith)
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

            // Connection Badge / Card
            IosGroupedCard(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier.padding(Dimens.md),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.History,
                        contentDescription = null,
                        tint = brandGreen,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(Dimens.sm))
                    Column {
                        Text(
                            text = "Connected Since",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = connectionInfo,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = brandGreen
                        )
                    }
                }
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
                    DetailRow("Father Name", salik.fatherName)
                    DetailRow("Mobile", salik.mobileNumber)
                    DetailRow("WhatsApp", salik.whatsappNumber)
                    DetailRow("Gender", salik.genderId)
                    DetailRow("Reference", salik.referenceName, isLast = true)
                }
            }

            SectionTitle("Location & Bazam", Icons.Default.LocationOn, brandGreen)
            IosGroupedCard {
                Column(modifier = Modifier.padding(vertical = Dimens.xs)) {
                    DetailRow("Bazam", state.bazam?.bazamName ?: salik.bazamId)
                    DetailRow("Area", state.area?.areaName ?: salik.areaId)
                    DetailRow("Address", salik.address, isLast = true)
                }
            }

            SectionTitle("Salik Details", Icons.Default.Assignment, brandGreen)
            IosGroupedCard {
                Column(modifier = Modifier.padding(vertical = Dimens.xs)) {
                    DetailRow("Date of Baith", salik.dateOfBaith)
                    DetailRow("Nafi Asbat", if (salik.isNafiAsbat) "Yes" else "No")
                    DetailRow("Sahib-e-Mehfil", if (salik.isSahibEMehfil) "Yes" else "No")
                    DetailRow("Added by", salik.addedByName.ifEmpty { salik.addedByUid }, isLast = true)
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

fun calculateConnectionTime(dateStr: String): String {
    if (dateStr.isBlank()) return "Unknown"
    return try {
        val baithDate = LocalDate.parse(dateStr)
        val now = LocalDate.now()
        val period = Period.between(baithDate, now)
        
        when {
            period.years > 0 -> "${period.years} years, ${period.months} months"
            period.months > 0 -> "${period.months} months, ${period.days} days"
            else -> "${period.days} days"
        }
    } catch (e: Exception) {
        dateStr
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

@Composable
private fun DetailRow(label: String, value: String, isLast: Boolean = false) {
    Column(modifier = Modifier.fillMaxWidth().padding(horizontal = Dimens.md, vertical = Dimens.sm)) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value.ifEmpty { "—" },
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface,
            fontWeight = FontWeight.Medium
        )
        if (!isLast) {
            Spacer(modifier = Modifier.height(Dimens.sm))
            HorizontalDivider(thickness = 0.5.dp, color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
        }
    }
}
