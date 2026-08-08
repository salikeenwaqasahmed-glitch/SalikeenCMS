package com.example.salik_management_system.features.saliks.presentation.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.features.saliks.domain.ApprovalStatus
import com.example.salik_management_system.features.saliks.presentation.viewmodel.SalikListViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SalikDirectoryScreen(
    onOpenProfile: (String) -> Unit = {},
    onAdd: () -> Unit = {},
    onOpenPending: () -> Unit = {},
    onOpenDuplicates: () -> Unit = {},
    onOpenMessageQueue: () -> Unit = {},
    viewModel: SalikListViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    var statusExpanded by remember { mutableStateOf(false) }
    var bazamExpanded by remember { mutableStateOf(false) }
    var areaExpanded by remember { mutableStateOf(false) }
    var menuExpanded by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Saliks") },
                actions = {
                    IconButton(onClick = { menuExpanded = true }) {
                        Icon(Icons.Filled.MoreVert, contentDescription = "More")
                    }
                    DropdownMenu(
                        expanded = menuExpanded,
                        onDismissRequest = { menuExpanded = false },
                    ) {
                        DropdownMenuItem(
                            text = { Text("Pending") },
                            onClick = { menuExpanded = false; onOpenPending() },
                        )
                        DropdownMenuItem(
                            text = { Text("Duplicates") },
                            onClick = { menuExpanded = false; onOpenDuplicates() },
                        )
                        DropdownMenuItem(
                            text = { Text("Message queue") },
                            onClick = { menuExpanded = false; onOpenMessageQueue() },
                        )
                    }
                },
            )
        },
        floatingActionButton = {
            if (state.canCreate) {
                FloatingActionButton(onClick = onAdd) {
                    Icon(Icons.Filled.Add, contentDescription = "Add")
                }
            }
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedTextField(
                value = state.filters.query,
                onValueChange = viewModel::setQuery,
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Search") },
                leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                singleLine = true,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterDropdown(
                    label = "Bazam",
                    value = state.bazams.firstOrNull { it.bazamId == state.filters.bazamId }?.bazamName
                        ?: "All bazams",
                    expanded = bazamExpanded,
                    onExpandedChange = { bazamExpanded = it },
                    modifier = Modifier.weight(1f),
                    options = state.bazams.map { it.bazamId to it.bazamName },
                    onSelect = viewModel::setBazam,
                )
                val areas = state.areas.filter {
                    state.filters.bazamId == null || it.bazamId == state.filters.bazamId
                }
                FilterDropdown(
                    label = "Area",
                    value = areas.firstOrNull { it.areaId == state.filters.areaId }?.areaName
                        ?: "All areas",
                    expanded = areaExpanded,
                    onExpandedChange = { areaExpanded = it },
                    modifier = Modifier.weight(1f),
                    options = areas.map { it.areaId to it.areaName },
                    onSelect = viewModel::setArea,
                )
            }
            FilterDropdown(
                label = "Status",
                value = state.filters.status?.name ?: "Any status",
                expanded = statusExpanded,
                onExpandedChange = { statusExpanded = it },
                options = ApprovalStatus.entries.map { it.name to it.name },
                onSelect = { raw ->
                    viewModel.setStatus(raw?.let { ApprovalStatus.fromString(it) })
                },
            )

            LazyColumn(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                items(state.saliks, key = { it.salikId }) { salik ->
                    ListItem(
                        headlineContent = { Text(salik.name) },
                        supportingContent = {
                            Text("${salik.fatherName} · ${salik.mobileNumber} · ${salik.approvalStatus.name}")
                        },
                        modifier = Modifier.clickable { onOpenProfile(salik.salikId) },
                    )
                }
                if (state.saliks.isEmpty()) {
                    item { Text("No saliks found", style = MaterialTheme.typography.bodyMedium) }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BazamAreasScreen(
    bazamId: String,
    onOpenDirectory: (areaId: String?) -> Unit = {},
    onBack: () -> Unit = {},
    viewModel: SalikListViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val bazam = state.bazams.firstOrNull { it.bazamId == bazamId }
    val areas = state.areas.filter { it.bazamId == bazamId }
    val counts = state.saliks.groupingBy { it.areaId }.eachCount()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(bazam?.bazamName ?: "Bazam areas") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            item {
                ListItem(
                    headlineContent = { Text("All areas") },
                    supportingContent = {
                        Text(
                            "${state.saliks.count { it.bazamId == bazamId || (it.bazamId.isEmpty() && bazamId == "i-10") }} saliks",
                        )
                    },
                    modifier = Modifier.clickable { onOpenDirectory(null) },
                )
            }
            items(areas, key = { it.areaId }) { area ->
                ListItem(
                    headlineContent = { Text(area.areaName) },
                    supportingContent = { Text("${counts[area.areaId] ?: 0} saliks") },
                    modifier = Modifier.clickable { onOpenDirectory(area.areaId) },
                )
            }
            if (areas.isEmpty()) {
                item {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("No areas yet (count 0 is OK)", style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }
}
