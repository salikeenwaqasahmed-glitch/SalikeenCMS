package com.example.salik_management_system.features.dashboard.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.PendingActions
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.VolunteerActivism
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.features.dashboard.ui.viewmodel.DashboardViewModel
import com.example.salik_management_system.ui.components.IosCardSection
import com.example.salik_management_system.ui.components.IosGroupedCard
import com.example.salik_management_system.ui.components.IosSettingsRow
import com.example.salik_management_system.ui.components.SectionHeader
import com.example.salik_management_system.ui.components.StatTile
import com.example.salik_management_system.ui.theme.Brand
import com.example.salik_management_system.ui.theme.Dimens
import com.example.salik_management_system.ui.theme.brandTopAppBarColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    onAddSalik: () -> Unit = {},
    onOpenBazam: (String) -> Unit = {},
    onOpenPending: () -> Unit = {},
    onOpenSaliks: () -> Unit = {},
    viewModel: DashboardViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val session = state.session
    val showGenderSplit = session == null || AccessControl.canViewAllGenders(session.role)

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = {
                    Text("Dashboard", fontWeight = FontWeight.SemiBold)
                },
                colors = brandTopAppBarColors(),
            )
        },
        floatingActionButton = {
            if (state.canCreate) {
                FloatingActionButton(
                    onClick = onAddSalik,
                    containerColor = Brand.Green,
                    contentColor = Brand.Gold,
                    elevation = FloatingActionButtonDefaults.elevation(0.dp),
                ) {
                    Icon(Icons.Filled.Add, contentDescription = "Add salik")
                }
            }
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
            if (session != null) {
                IosGroupedCard {
                    Column(modifier = Modifier.padding(Dimens.md)) {
                        Text(
                            text = "Welcome, ${session.name}",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary,
                        )
                        Text(
                            text = "${session.role.label} · ${session.gender}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(top = Dimens.xxs),
                        )
                    }
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(Dimens.xs)) {
                SectionHeader(title = "Overview")
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    StatTile(
                        label = "Total",
                        count = state.stats.total,
                        icon = Icons.Filled.People,
                        modifier = Modifier.weight(1f),
                        onClick = onOpenSaliks,
                    )
                    if (showGenderSplit) {
                        StatTile(
                            label = "Male",
                            count = state.stats.maleCount,
                            icon = Icons.Filled.People,
                            modifier = Modifier.weight(1f),
                        )
                        StatTile(
                            label = "Female",
                            count = state.stats.femaleCount,
                            icon = Icons.Filled.People,
                            modifier = Modifier.weight(1f),
                        )
                    } else {
                        StatTile(
                            label = "Nafi Asbat",
                            count = state.stats.nafiAsbatCount,
                            icon = Icons.Filled.VolunteerActivism,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    if (showGenderSplit) {
                        StatTile(
                            label = "Nafi Asbat",
                            count = state.stats.nafiAsbatCount,
                            icon = Icons.Filled.VolunteerActivism,
                            modifier = Modifier.weight(1f),
                        )
                    }
                    StatTile(
                        label = "Sahib-e-Mehfil",
                        count = state.stats.sahibMehfilCount,
                        icon = Icons.Filled.Star,
                        modifier = Modifier.weight(1f),
                    )
                    if (!showGenderSplit) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
            }

            if (showGenderSplit) {
                IosCardSection(title = "Gender Distribution") {
                    GenderDonutChart(
                        male = state.stats.maleCount,
                        female = state.stats.femaleCount,
                        modifier = Modifier.padding(Dimens.md)
                    )
                }
            }

            if (state.bazamCounts.isNotEmpty()) {
                Column(verticalArrangement = Arrangement.spacedBy(Dimens.xs)) {
                    SectionHeader(title = "By bazam")
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        contentPadding = PaddingValues(vertical = Dimens.xxs),
                    ) {
                        items(state.bazamCounts, key = { it.bazamId }) { bazam ->
                            StatTile(
                                label = bazam.bazamName,
                                count = bazam.count,
                                icon = Icons.Filled.Groups,
                                modifier = Modifier.width(148.dp),
                                onClick = { onOpenBazam(bazam.bazamId) },
                            )
                        }
                    }
                }
            }

            if (state.canViewPending) {
                IosCardSection(title = "Approvals") {
                    IosSettingsRow(
                        title = if (session != null && AccessControl.isEditor(session.role)) {
                            "My submissions"
                        } else {
                            "Pending approvals"
                        },
                        subtitle = "${state.pendingCount} waiting",
                        showDivider = false,
                        showChevron = true,
                        onClick = onOpenPending,
                        trailing = {
                            Icon(
                                Icons.Filled.PendingActions,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                            )
                        },
                    )
                }
            }
        }
    }
}
