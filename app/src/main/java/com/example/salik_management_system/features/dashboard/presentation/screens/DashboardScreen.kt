package com.example.salik_management_system.features.dashboard.presentation.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.features.dashboard.presentation.viewmodel.DashboardViewModel

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

    Scaffold(
        topBar = { TopAppBar(title = { Text("Dashboard") }) },
        floatingActionButton = {
            if (state.canCreate) {
                FloatingActionButton(onClick = onAddSalik) {
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (session != null) {
                Text(
                    text = "Welcome, ${session.name}",
                    style = MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary,
                )
                Text(
                    text = "${session.role.label} · ${session.gender}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            Text("Overview", style = MaterialTheme.typography.titleMedium)
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                StatCard("Total", state.stats.total, Icons.Filled.People, Modifier.weight(1f), onOpenSaliks)
                if (session == null || AccessControl.canViewAllGenders(session.role)) {
                    StatCard("Male", state.stats.maleCount, Icons.Filled.People, Modifier.weight(1f))
                    StatCard("Female", state.stats.femaleCount, Icons.Filled.People, Modifier.weight(1f))
                }
            }
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                StatCard(
                    "Nafi Asbat",
                    state.stats.nafiAsbatCount,
                    Icons.Filled.VolunteerActivism,
                    Modifier.weight(1f),
                )
                StatCard(
                    "Sahib-e-Mehfil",
                    state.stats.sahibMehfilCount,
                    Icons.Filled.Star,
                    Modifier.weight(1f),
                )
            }

            if (state.bazamCounts.isNotEmpty()) {
                Text("By bazam", style = MaterialTheme.typography.titleMedium)
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    contentPadding = PaddingValues(vertical = 4.dp),
                ) {
                    items(state.bazamCounts, key = { it.bazamId }) { bazam ->
                        StatCard(
                            label = bazam.bazamName,
                            count = bazam.count,
                            icon = Icons.Filled.Groups,
                            modifier = Modifier.width(132.dp),
                            onClick = { onOpenBazam(bazam.bazamId) },
                        )
                    }
                }
            }

            if (state.canViewPending) {
                OutlinedButton(
                    onClick = onOpenPending,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Icon(Icons.Filled.PendingActions, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        if (session != null && AccessControl.isEditor(session.role)) {
                            "My submissions (${state.pendingCount})"
                        } else {
                            "Pending approvals (${state.pendingCount})"
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun StatCard(
    label: String,
    count: Int,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
) {
    Card(
        modifier = modifier.then(
            if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier,
        ),
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.Start,
        ) {
            Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.height(4.dp))
            Text(label, style = MaterialTheme.typography.labelMedium)
            Text("$count", style = MaterialTheme.typography.headlineSmall)
        }
    }
}
