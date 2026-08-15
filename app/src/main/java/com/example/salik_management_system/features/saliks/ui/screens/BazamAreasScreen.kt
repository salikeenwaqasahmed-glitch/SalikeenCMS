package com.example.salik_management_system.features.saliks.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikListViewModel
import com.example.salik_management_system.ui.components.EmptyState
import com.example.salik_management_system.ui.components.SectionHeader
import com.example.salik_management_system.ui.components.StatTile
import com.example.salik_management_system.ui.theme.Dimens
import com.example.salik_management_system.ui.theme.brandTopAppBarColors

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
    val counts = state.saliks.groupingBy { it.areaId }.eachCount()
    
    // Only show areas that belong to this bazam AND have at least 1 salik
    val areasWithSaliks = state.areas
        .filter { it.bazamId == bazamId }
        .filter { (counts[it.areaId] ?: 0) > 0 }
        .sortedBy { it.areaName }

    val allCount = state.saliks.count {
        it.bazamId == bazamId || (it.bazamId.isEmpty() && bazamId == "i-10")
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        bazam?.bazamName ?: "Bazam areas",
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = brandTopAppBarColors(),
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = Dimens.screenPadding),
        ) {
            SectionHeader(
                title = "Area Statistics",
                modifier = Modifier.padding(bottom = Dimens.xs)
            )

            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(bottom = Dimens.xl),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                // "All Areas" summary card
                item {
                    StatTile(
                        label = "All areas",
                        count = allCount,
                        icon = Icons.Default.LocationOn,
                        onClick = { onOpenDirectory(null) }
                    )
                }

                // Individual Area cards
                items(areasWithSaliks, key = { it.areaId }) { area ->
                    StatTile(
                        label = area.areaName,
                        count = counts[area.areaId] ?: 0,
                        icon = Icons.Default.LocationOn,
                        onClick = { onOpenDirectory(area.areaId) }
                    )
                }
            }

            if (areasWithSaliks.isEmpty() && allCount == 0) {
                EmptyState(
                    title = "No active areas",
                    subtitle = "Areas with 0 saliks are hidden from this summary.",
                    icon = Icons.Default.LocationOn
                )
            }
        }
    }
}
