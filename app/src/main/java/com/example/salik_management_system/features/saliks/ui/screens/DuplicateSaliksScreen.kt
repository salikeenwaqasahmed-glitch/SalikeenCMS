package com.example.salik_management_system.features.saliks.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.ui.components.IosGroupedCard
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikListViewModel
import com.example.salik_management_system.ui.theme.brandTopAppBarColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DuplicateSaliksScreen(
    onBack: () -> Unit = {},
    viewModel: SalikListViewModel = hiltViewModel(),
) {
    val groups by viewModel.duplicateGroups.collectAsStateWithLifecycle()
    val keepByGroup = remember { mutableStateMapOf<String, String>() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Duplicate saliks") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = brandTopAppBarColors(),
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            items(groups, key = { it.id }) { group ->
                val keepId = keepByGroup[group.id] ?: group.saliks.first().salikId
                IosGroupedCard(modifier = Modifier.fillMaxWidth()) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Text(
                            "${group.label} · ${group.reasons.joinToString { it.name }}",
                            style = MaterialTheme.typography.titleSmall,
                        )
                        group.saliks.forEach { salik ->
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                RadioButton(
                                    selected = keepId == salik.salikId,
                                    onClick = { keepByGroup[group.id] = salik.salikId },
                                )
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(salik.name)
                                    Text(
                                        "${salik.mobileNumber} · ${salik.fatherName}",
                                        style = MaterialTheme.typography.bodySmall,
                                    )
                                }
                                OutlinedButton(onClick = { viewModel.delete(salik.salikId) }) {
                                    Text("Delete")
                                }
                            }
                        }
                        Button(
                            onClick = {
                                val remove = group.saliks.map { it.salikId }.filter { it != keepId }
                                viewModel.mergeGroup(keepId, remove)
                            },
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Text("Merge into selected")
                        }
                    }
                }
            }
            if (groups.isEmpty()) {
                item {
                    Text("No duplicates found", style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }
}
