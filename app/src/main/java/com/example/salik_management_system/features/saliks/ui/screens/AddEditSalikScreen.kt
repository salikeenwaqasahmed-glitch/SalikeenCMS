package com.example.salik_management_system.features.saliks.ui.screens

import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ContentPaste
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikFormViewModel
import com.example.salik_management_system.ui.components.FilterDropdown
import com.example.salik_management_system.ui.components.IosGroupedCard
import com.example.salik_management_system.ui.components.rememberHaptic
import com.example.salik_management_system.ui.theme.Brand
import com.example.salik_management_system.ui.theme.Dimens
import com.example.salik_management_system.ui.theme.brandTopAppBarColors
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditSalikScreen(
    salikId: String? = null,
    onBack: () -> Unit = {},
    onSaved: (String) -> Unit = {},
    viewModel: SalikFormViewModel = hiltViewModel(),
) {
    val state by viewModel.form.collectAsStateWithLifecycle()
    var areaExpanded by remember { mutableStateOf(false) }
    var genderExpanded by remember { mutableStateOf(false) }
    var showDatePicker by remember { mutableStateOf(false) }
    var showAddAreaDialog by remember { mutableStateOf(false) }
    var newAreaName by remember { mutableStateOf("") }

    val isEditable = !state.isLoadingRecord && !state.isSaving
    val brandGreen = if (isSystemInDarkTheme()) Brand.GreenDark else Brand.Green
    val haptic = rememberHaptic()

    LaunchedEffect(salikId) {
        viewModel.load(salikId)
    }
    LaunchedEffect(state.savedId) {
        val id = state.savedId ?: return@LaunchedEffect
        haptic()
        onSaved(id)
        viewModel.clearSaved()
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (salikId == null) "Add New Salik" else "Edit Salik Info",
                        fontWeight = FontWeight.SemiBold
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
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Dimens.screenPadding, vertical = Dimens.md),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupSpacing),
        ) {
            state.error?.let {
                Text(
                    text = it,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(horizontal = Dimens.sm)
                )
            }

            FormSectionTitle("Identity", Icons.Default.Person, brandGreen)
            IosGroupedCard {
                Column(modifier = Modifier.padding(Dimens.md), verticalArrangement = Arrangement.spacedBy(Dimens.sm)) {
                    OutlinedTextField(
                        value = state.name,
                        onValueChange = { v -> viewModel.update { it.copy(name = v) } },
                        label = { Text("Full Name") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = brandGreen) },
                        shape = MaterialTheme.shapes.small,
                        enabled = isEditable
                    )
                    OutlinedTextField(
                        value = state.fatherName,
                        onValueChange = { v -> viewModel.update { it.copy(fatherName = v) } },
                        label = { Text("Father Name") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        leadingIcon = { Icon(Icons.Default.Badge, contentDescription = null, tint = brandGreen) },
                        shape = MaterialTheme.shapes.small,
                        enabled = isEditable
                    )
                    if (state.canSetGender) {
                        FilterDropdown(
                            label = "Gender",
                            value = state.genderId,
                            expanded = genderExpanded,
                            onExpandedChange = { if (isEditable) genderExpanded = it },
                            options = listOf("Male" to "Male", "Female" to "Female"),
                            onSelect = { g -> if (g != null) viewModel.update { it.copy(genderId = g) } },
                            includeAll = false,
                        )
                    }
                }
            }

            FormSectionTitle("Contact Details", Icons.Default.Phone, brandGreen)
            IosGroupedCard {
                Column(modifier = Modifier.padding(Dimens.md), verticalArrangement = Arrangement.spacedBy(Dimens.sm)) {
                    OutlinedTextField(
                        value = state.mobileNumber,
                        onValueChange = { v -> viewModel.update { it.copy(mobileNumber = v) } },
                        label = { Text("Mobile Number") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null, tint = brandGreen) },
                        shape = MaterialTheme.shapes.small,
                        enabled = isEditable
                    )
                    OutlinedTextField(
                        value = state.whatsappNumber,
                        onValueChange = { v -> viewModel.update { it.copy(whatsappNumber = v) } },
                        label = { Text("WhatsApp Number") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null, tint = brandGreen) },
                        shape = MaterialTheme.shapes.small,
                        enabled = isEditable,
                        trailingIcon = {
                            IconButton(
                                onClick = { viewModel.update { it.copy(whatsappNumber = it.mobileNumber) } },
                                enabled = isEditable && state.mobileNumber.isNotBlank()
                            ) {
                                Icon(
                                    imageVector = Icons.Default.ContentPaste,
                                    contentDescription = "Same as mobile",
                                    tint = if (isEditable) brandGreen else Color.Gray
                                )
                            }
                        }
                    )
                }
            }

            FormSectionTitle("Location & Membership", Icons.Default.LocationOn, brandGreen)
            IosGroupedCard {
                Column(modifier = Modifier.padding(Dimens.md), verticalArrangement = Arrangement.spacedBy(Dimens.sm)) {
                    
                    // Area Selection with "Add New"
                    val currentAreaName = if (state.areaId.startsWith("NEW:")) {
                        state.areaId.removePrefix("NEW:") + " (New)"
                    } else {
                        state.areas.find { it.areaId == state.areaId }?.areaName ?: "Select Area"
                    }

                    ExposedDropdownMenuBox(
                        expanded = areaExpanded,
                        onExpandedChange = { if (isEditable) areaExpanded = it },
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        OutlinedTextField(
                            value = currentAreaName,
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Area") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(areaExpanded) },
                            modifier = Modifier
                                .menuAnchor()
                                .fillMaxWidth(),
                            shape = MaterialTheme.shapes.small,
                            enabled = isEditable
                        )
                        ExposedDropdownMenu(
                            expanded = areaExpanded,
                            onDismissRequest = { areaExpanded = false },
                        ) {
                            DropdownMenuItem(
                                text = { 
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(Icons.Default.Add, contentDescription = null, tint = brandGreen, modifier = Modifier.size(18.dp))
                                        Spacer(modifier = Modifier.width(Dimens.xs))
                                        Text("Add New Area...", color = brandGreen, fontWeight = FontWeight.Bold)
                                    }
                                },
                                onClick = {
                                    areaExpanded = false
                                    newAreaName = ""
                                    showAddAreaDialog = true
                                },
                            )
                            HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp))
                            state.areas.forEach { area ->
                                DropdownMenuItem(
                                    text = { Text(area.areaName) },
                                    onClick = {
                                        viewModel.update { it.copy(areaId = area.areaId) }
                                        areaExpanded = false
                                    },
                                )
                            }
                        }
                    }

                    OutlinedTextField(
                        value = state.address,
                        onValueChange = { v -> viewModel.update { it.copy(address = v) } },
                        label = { Text("Residential Address") },
                        modifier = Modifier.fillMaxWidth(),
                        leadingIcon = { Icon(Icons.Default.Home, contentDescription = null, tint = brandGreen) },
                        shape = MaterialTheme.shapes.small,
                        enabled = isEditable
                    )

                    val dateInteractionSource = remember { MutableInteractionSource() }
                    val isPressed by dateInteractionSource.collectIsPressedAsState()
                    if (isPressed && isEditable) {
                        showDatePicker = true
                    }

                    OutlinedTextField(
                        value = state.dateOfBaith,
                        onValueChange = { },
                        label = { Text("Date of Baith") },
                        placeholder = { Text("YYYY-MM-DD") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.small,
                        singleLine = true,
                        readOnly = true,
                        enabled = isEditable,
                        interactionSource = dateInteractionSource,
                        leadingIcon = { Icon(Icons.Default.CalendarToday, contentDescription = null, tint = brandGreen) },
                        trailingIcon = {
                            Icon(Icons.Default.CalendarToday, contentDescription = null, tint = brandGreen)
                        }
                    )

                    OutlinedTextField(
                        value = state.referenceName,
                        onValueChange = { v -> viewModel.update { it.copy(referenceName = v) } },
                        label = { Text("Reference") },
                        modifier = Modifier.fillMaxWidth(),
                        leadingIcon = { Icon(Icons.Default.CheckCircle, contentDescription = null, tint = brandGreen) },
                        shape = MaterialTheme.shapes.small,
                        singleLine = true,
                        enabled = isEditable
                    )
                }
            }

            FormSectionTitle("Status", Icons.Default.CheckCircle, brandGreen)
            IosGroupedCard {
                Column(modifier = Modifier.padding(Dimens.md), verticalArrangement = Arrangement.spacedBy(Dimens.xs)) {
                    CheckboxRow(
                        label = "Nafi Asbat",
                        checked = state.isNafiAsbat,
                        onCheckedChange = { v -> viewModel.update { it.copy(isNafiAsbat = v) } },
                        enabled = isEditable
                    )
                    CheckboxRow(
                        label = "Sahib-e-Mehfil",
                        checked = state.isSahibEMehfil,
                        onCheckedChange = { v -> viewModel.update { it.copy(isSahibEMehfil = v) } },
                        enabled = isEditable
                    )
                }
            }

            Button(
                onClick = viewModel::save,
                enabled = isEditable,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = MaterialTheme.shapes.medium,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Brand.Green,
                    contentColor = Brand.Gold
                )
            ) {
                val label = when {
                    state.isLoadingRecord -> "Loading..."
                    state.isSaving -> "Saving Registration…"
                    salikId == null -> "Register Salik"
                    else -> "Update Salik Info"
                }
                Text(label, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            }
            
            Spacer(modifier = Modifier.height(Dimens.xl))
        }
    }

    if (showAddAreaDialog) {
        AlertDialog(
            onDismissRequest = { showAddAreaDialog = false },
            title = { Text("Add New Area") },
            text = {
                Column {
                    Text("Enter the name of the new area to add to the system.")
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = newAreaName,
                        onValueChange = { newAreaName = it },
                        label = { Text("Area Name") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        if (newAreaName.trim().isNotEmpty()) {
                            viewModel.update { it.copy(areaId = "NEW:${newAreaName.trim()}") }
                            showAddAreaDialog = false
                        }
                    },
                    enabled = newAreaName.trim().isNotEmpty()
                ) {
                    Text("Add")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddAreaDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showDatePicker) {
        val initialDate = remember(state.dateOfBaith) {
            runCatching {
                LocalDate.parse(state.dateOfBaith).atStartOfDay(ZoneId.systemDefault())
                    .toInstant().toEpochMilli()
            }.getOrNull() ?: System.currentTimeMillis()
        }
        val datePickerState = rememberDatePickerState(initialSelectedDateMillis = initialDate)

        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        val date = Instant.ofEpochMilli(millis)
                            .atZone(ZoneId.systemDefault())
                            .toLocalDate()
                        viewModel.update { it.copy(dateOfBaith = date.toString()) }
                    }
                    showDatePicker = false
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) {
                    Text("Cancel")
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }
}

@Composable
private fun FormSectionTitle(title: String, icon: ImageVector, tint: Color) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(start = Dimens.xs, top = Dimens.xs)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(18.dp),
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
private fun CheckboxRow(
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    enabled: Boolean
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().height(48.dp)
    ) {
        Checkbox(
            checked = checked,
            onCheckedChange = onCheckedChange,
            enabled = enabled,
            colors = CheckboxDefaults.colors(
                checkedColor = if (isSystemInDarkTheme()) Brand.GreenDark else Brand.Green,
                uncheckedColor = MaterialTheme.colorScheme.outline
            )
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            color = if (enabled) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/** Nav-graph alias used by existing route composables. */
@Composable
fun AddSalikFormScreen(
    salikId: String? = null,
    onBack: () -> Unit = {},
    onSaved: (String) -> Unit = {},
) {
    AddEditSalikScreen(salikId = salikId, onBack = onBack, onSaved = onSaved)
}
