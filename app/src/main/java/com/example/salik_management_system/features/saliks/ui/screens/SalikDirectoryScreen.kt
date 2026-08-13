package com.example.salik_management_system.features.saliks.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContactPhone
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.PeopleOutline
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.features.saliks.domain.model.ApprovalStatus
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikListViewModel
import com.example.salik_management_system.ui.components.AppListRow
import com.example.salik_management_system.ui.components.EmptyState
import com.example.salik_management_system.ui.components.IosCardSection
import com.example.salik_management_system.ui.components.IosGroupedCard
import com.example.salik_management_system.ui.components.StatusChip
import com.example.salik_management_system.ui.components.StatusTone
import com.example.salik_management_system.ui.theme.Brand
import com.example.salik_management_system.ui.theme.Dimens
import com.example.salik_management_system.ui.theme.brandFilterChipBorder
import com.example.salik_management_system.ui.theme.brandFilterChipColors
import com.example.salik_management_system.ui.theme.brandTopAppBarColors

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
    val context = LocalContext.current
    var menuExpanded by remember { mutableStateOf(false) }
    var bazamMenu by remember { mutableStateOf(false) }
    var areaMenu by remember { mutableStateOf(false) }
    var showMessageDialog by remember { mutableStateOf(false) }
    var pendingMessage by remember { mutableStateOf("") }

    val areas = state.areas.filter {
        state.filters.bazamId == null || it.bazamId == state.filters.bazamId
    }
    val bazamLabel =
        state.bazams.firstOrNull { it.bazamId == state.filters.bazamId }?.bazamName ?: "Bazam"
    val areaLabel = areas.firstOrNull { it.areaId == state.filters.areaId }?.areaName ?: "Area"
    val rangeStart = if (state.totalCount == 0) {
        0
    } else {
        (state.page - 1) * state.pageSize + 1
    }
    val rangeEnd = minOf(state.page * state.pageSize, state.totalCount)

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = {
                    if (state.isSelectionMode) {
                        Text("${state.selectedIds.size} selected")
                    } else {
                        Text("Saliks", fontWeight = FontWeight.SemiBold)
                    }
                },
                navigationIcon = {
                    if (state.isSelectionMode) {
                        IconButton(onClick = viewModel::toggleSelectionMode) {
                            Icon(Icons.Filled.Close, contentDescription = "Cancel")
                        }
                    }
                },
                actions = {
                    if (state.isSelectionMode) {
                        IconButton(
                            onClick = { showMessageDialog = true },
                            enabled = state.selectedIds.isNotEmpty()
                        ) {
                            Icon(Icons.Filled.Chat, contentDescription = "Message")
                        }
                        IconButton(
                            onClick = {
                                viewModel.exportSelected { csv ->
                                    val intent = Intent(Intent.ACTION_SEND).apply {
                                        type = "text/csv"
                                        putExtra(Intent.EXTRA_SUBJECT, "Saliks Export")
                                        putExtra(Intent.EXTRA_TEXT, csv)
                                    }
                                    context.startActivity(
                                        Intent.createChooser(
                                            intent, "Share Export"
                                        )
                                    )
                                }
                            }, enabled = state.selectedIds.isNotEmpty()
                        ) {
                            Icon(Icons.Filled.Share, contentDescription = "Export")
                        }
                    } else {
                        IconButton(onClick = { menuExpanded = true }) {
                            Icon(Icons.Filled.MoreVert, contentDescription = "More")
                        }
                        DropdownMenu(
                            expanded = menuExpanded,
                            onDismissRequest = { menuExpanded = false },
                        ) {
                            DropdownMenuItem(
                                text = { Text("Export / Select") },
                                onClick = {
                                    menuExpanded = false
                                    viewModel.toggleSelectionMode()
                                },
                            )
                            DropdownMenuItem(
                                text = { Text("Pending Filter") },
                                onClick = {
                                    menuExpanded = false
                                    viewModel.setStatus(ApprovalStatus.Pending)
                                },
                            )
                            DropdownMenuItem(
                                text = { Text("Rejected Filter") },
                                onClick = {
                                    menuExpanded = false
                                    viewModel.setStatus(ApprovalStatus.Rejected)
                                },
                            )
                            DropdownMenuItem(
                                text = { Text("Go to Pending") },
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
                    }
                },
                colors = brandTopAppBarColors(),
            )
        },
        floatingActionButton = {
            if (state.canCreate && !state.isSelectionMode) {
                FloatingActionButton(
                    onClick = onAdd,
                    containerColor = Brand.Green,
                    contentColor = Color.White,
                    elevation = FloatingActionButtonDefaults.elevation(0.dp),
                ) {
                    Icon(Icons.Filled.Add, contentDescription = "Add")
                }
            }
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = Dimens.screenPadding),
        ) {
            // Top: search + chip filters
            Column(modifier = Modifier.padding(vertical = Dimens.md)) {
                OutlinedTextField(
                    value = state.filters.query,
                    onValueChange = viewModel::setQuery,
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Search name, mobile, baith date") },
                    leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                    singleLine = true,
                    shape = MaterialTheme.shapes.medium,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = MaterialTheme.colorScheme.primary,
                        unfocusedContainerColor = MaterialTheme.colorScheme.surface,
                        focusedContainerColor = MaterialTheme.colorScheme.surface,
                    ),
                )
                Spacer(modifier = Modifier.height(Dimens.sm))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy( Dimens.xs),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    StatusFilterChip(
                        label = "All",
                        selected = state.filters.status == null && !state.filters.nafiOnly && !state.filters.sahibOnly,
                        onClick = { viewModel.clearTypeFilters() },
                    )
                    StatusFilterChip(
                        label = "Nafi",
                        selected = state.filters.nafiOnly,
                        onClick = { viewModel.setNafiOnly(!state.filters.nafiOnly) },
                    )
                    StatusFilterChip(
                        label = "Sahib",
                        selected = state.filters.sahibOnly,
                        onClick = { viewModel.setSahibOnly(!state.filters.sahibOnly) },
                    )
                    if (state.filters.status != null) {
                        StatusFilterChip(
                            label = state.filters.status!!.name,
                            selected = true,
                            onClick = { viewModel.setStatus(null) },
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(4.dp))
                    
                    FilterChipWithMenu(
                        label = bazamLabel,
                        selected = state.filters.bazamId != null,
                        expanded = bazamMenu,
                        onExpandedChange = { bazamMenu = it },
                        onClear = { viewModel.setBazam(null) },
                        options = listOf(null to "All bazams") + state.bazams.map { it.bazamId to it.bazamName },
                        onSelect = { id -> viewModel.setBazam(id) },
                    )
                    if (state.filters.bazamId != null) {
                        FilterChipWithMenu(
                            label = areaLabel,
                            selected = state.filters.areaId != null,
                            expanded = areaMenu,
                            onExpandedChange = { areaMenu = it },
                            onClear = { viewModel.setArea(null) },
                            options = listOf(null to "All areas") + areas.map { it.areaId to it.areaName },
                            onSelect = { id -> viewModel.setArea(id) },
                        )
                    }
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = Dimens.xs),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (state.totalCount == 0) {
                        "0 saliks"
                    } else {
                        "Showing $rangeStart–$rangeEnd of ${state.totalCount}"
                    },
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = 4.dp),
                )
            }

            // Middle: page data
            IosGroupedCard(modifier = Modifier.weight(1f)) {
                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    itemsIndexed(state.pageItems, key = { _, s -> s.salikId }) { index, salik ->
                        val isSelected = salik.salikId in state.selectedIds
                        AppListRow(
                            title = salik.name,
                            subtitle = buildString {
                                append(salik.fatherName)
                                if (salik.mobileNumber.isNotBlank()) {
                                    append(" · ")
                                    append(salik.mobileNumber)
                                }
                                val years = salik.calculateAge()
                                if (years != null) {
                                    append(" · ")
                                    append("$years yrs")
                                }
                                val bazam = state.bazams.firstOrNull { it.bazamId == salik.bazamId }
                                if (bazam != null) {
                                    append(" · ")
                                    append(bazam.bazamName)
                                }
                            },
                            showDivider = index < state.pageItems.lastIndex,
                            onClick = {
                                if (state.isSelectionMode) {
                                    viewModel.toggleSelection(salik.salikId)
                                } else {
                                    onOpenProfile(salik.salikId)
                                }
                            },
                            trailing = {
                                if (state.isSelectionMode) {
                                    Icon(
                                        imageVector = if (isSelected) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                                        contentDescription = null,
                                        tint = if (isSelected) Brand.Green else Brand.OutlineVariant
                                    )
                                } else {
                                    ContactActionMenu(salik)
                                }
                            },
                        )
                    }
                    if (state.pageItems.isEmpty()) {
                        item {
                            EmptyState(
                                title = "No saliks yet",
                                subtitle = "Sync to pull data, or tap Add to create one.",
                                icon = Icons.Filled.PeopleOutline,
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(Dimens.sm))

            // Bottom: fixed pagination
            PaginationBar(
                page = state.page,
                totalPages = state.totalPages,
                totalCount = state.totalCount,
                canPrev = state.page > 1,
                canNext = state.page < state.totalPages,
                onPrev = viewModel::prevPage,
                onNext = viewModel::nextPage,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = Dimens.sm),
            )
        }
    }

    if (showMessageDialog) {
        AlertDialog(
            onDismissRequest = { showMessageDialog = false },
            title = { Text("Send Message") },
            text = {
                Column {
                    Text(
                        "Sending to ${state.selectedIds.size} saliks",
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    OutlinedTextField(
                        value = pendingMessage,
                        onValueChange = { pendingMessage = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Type your message here...") },
                        minLines = 3
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        val phones = viewModel.getSelectedPhones()
                        if (phones.isNotEmpty()) {
                            val uri = Uri.parse("smsto:${phones.joinToString(";")}")
                            val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
                                putExtra("sms_body", pendingMessage)
                            }
                            context.startActivity(Intent.createChooser(intent, "Send Message"))
                        }
                        showMessageDialog = false
                        pendingMessage = ""
                    }, enabled = pendingMessage.isNotBlank()
                ) {
                    Text("Send")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    showMessageDialog = false
                    pendingMessage = ""
                }) {
                    Text("Cancel")
                }
            })
    }
}

@Composable
private fun ContactActionMenu(salik: com.example.salik_management_system.features.saliks.domain.model.Salik) {
    val context = LocalContext.current
    var expanded by remember { mutableStateOf(false) }

    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(
                imageVector = Icons.Default.Call,
                contentDescription = "Contact options",
                tint = Brand.Green
            )
        }
        DropdownMenu(
            expanded = expanded, onDismissRequest = { expanded = false }) {
            DropdownMenuItem(
                text = { Text("Call") },
                leadingIcon = { Icon(Icons.Default.Call, contentDescription = null) },
                onClick = {
                    expanded = false
                    com.example.salik_management_system.core.utils.ContactLauncher.callIntent(salik.mobileNumber)
                        ?.let {
                            context.startActivity(it)
                        }
                })
            DropdownMenuItem(
                text = { Text("WhatsApp") },
                leadingIcon = { Icon(Icons.Default.Chat, contentDescription = null) },
                onClick = {
                    expanded = false
                    val phone = salik.whatsappNumber.ifEmpty { salik.mobileNumber }
                    com.example.salik_management_system.core.utils.ContactLauncher.whatsappIntent(
                        phone
                    )?.let { context.startActivity(it) }
                })
            DropdownMenuItem(
                text = { Text("Send SMS") },
                leadingIcon = { Icon(Icons.Default.Chat, contentDescription = null) },
                onClick = {
                    expanded = false
                    com.example.salik_management_system.core.utils.ContactLauncher.smsIntent(salik.mobileNumber)
                        ?.let { context.startActivity(it) }
                })
        }
    }
}

@Composable
private fun PaginationBar(
    page: Int,
    totalPages: Int,
    totalCount: Int,
    canPrev: Boolean,
    canNext: Boolean,
    onPrev: () -> Unit,
    onNext: () -> Unit,
    modifier: Modifier = Modifier,
) {
    IosGroupedCard(modifier = modifier) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Dimens.xs, vertical = Dimens.xxs),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            IconButton(onClick = onPrev, enabled = canPrev) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                    contentDescription = "Previous page",
                )
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "Page $page of $totalPages",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text = "$totalCount total",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            IconButton(onClick = onNext, enabled = canNext) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = "Next page",
                )
            }
        }
    }
}

@Composable
private fun StatusFilterChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = { Text(label) },
        colors = brandFilterChipColors(),
        border = brandFilterChipBorder(selected),
    )
}

@Composable
private fun FilterChipWithMenu(
    label: String,
    selected: Boolean,
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    onClear: () -> Unit,
    options: List<Pair<String?, String>>,
    onSelect: (String?) -> Unit,
) {
    Column {
        FilterChip(
            selected = selected,
            onClick = { onExpandedChange(true) },
            label = {
                Text(
                    text = label,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            },
            trailingIcon = {
                Icon(
                    Icons.Filled.ArrowDropDown,
                    contentDescription = null,
                    modifier = Modifier.width(18.dp),
                )
            },
            colors = brandFilterChipColors(),
            border = brandFilterChipBorder(selected),
        )
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { onExpandedChange(false) },
        ) {
            options.forEach { (id, title) ->
                DropdownMenuItem(
                    text = { Text(title) },
                    onClick = {
                        if (id == null) onClear() else onSelect(id)
                        onExpandedChange(false)
                    },
                )
            }
        }
    }
}
