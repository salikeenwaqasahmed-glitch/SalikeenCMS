package com.example.salik_management_system.features.saliks.ui.screens

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.PendingActions
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.auth.domain.UserRole
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikListViewModel
import com.example.salik_management_system.ui.components.AppListRow
import com.example.salik_management_system.ui.components.EmptyState
import com.example.salik_management_system.ui.components.StatusChip
import com.example.salik_management_system.ui.components.StatusTone
import com.example.salik_management_system.ui.theme.Dimens

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PendingApprovalsScreen(
    onOpenProfile: (String) -> Unit = {},
    onBack: () -> Unit = {},
    viewModel: SalikListViewModel = hiltViewModel(),
) {
    val pending by viewModel.pendingSaliks.collectAsStateWithLifecycle()
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val isEditor = state.session?.role == UserRole.Editor
    val title = if (isEditor) "My submissions" else "Pending approvals"

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text(title, fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                ),
            )
        },
    ) { padding ->
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(Dimens.screenPadding)
                .border(
                    1.dp,
                    MaterialTheme.colorScheme.outlineVariant,
                    MaterialTheme.shapes.medium,
                ),
            shape = MaterialTheme.shapes.medium,
            color = MaterialTheme.colorScheme.surface,
        ) {
            LazyColumn {
                items(pending, key = { it.salikId }) { salik ->
                    AppListRow(
                        title = salik.name,
                        subtitle = "${salik.fatherName} · ${salik.addedByName}",
                        onClick = { onOpenProfile(salik.salikId) },
                        trailing = {
                            StatusChip(label = salik.approvalStatus.name, tone = StatusTone.Warning)
                        },
                    )
                }
                if (pending.isEmpty()) {
                    item {
                        EmptyState(
                            title = "Nothing pending",
                            subtitle = if (isEditor) {
                                "Your submissions will show here."
                            } else {
                                "No approvals waiting right now."
                            },
                            icon = Icons.Filled.PendingActions,
                        )
                    }
                }
            }
        }
    }
}
