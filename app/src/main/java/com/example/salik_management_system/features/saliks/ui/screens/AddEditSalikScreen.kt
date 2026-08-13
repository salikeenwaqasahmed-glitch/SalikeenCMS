package com.example.salik_management_system.features.saliks.ui.screens

import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.ContentPaste
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikFormViewModel
import com.example.salik_management_system.ui.components.FilterDropdown
import com.example.salik_management_system.ui.components.IosGroupedCard
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

    val isEditable = !state.isLoadingRecord && !state.isSaving

    LaunchedEffect(salikId) {
        viewModel.load(salikId)
    }
    LaunchedEffect(state.savedId) {
        val id = state.savedId ?: return@LaunchedEffect
        onSaved(id)
        viewModel.clearSaved()
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (salikId == null) "Add Salik" else "Edit Salik",
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

            IosGroupedCard {
                Column(modifier = Modifier.padding(Dimens.md), verticalArrangement = Arrangement.spacedBy(Dimens.sm)) {
                    OutlinedTextField(
                        value = state.name,
                        onValueChange = { v -> viewModel.update { it.copy(name = v) } },
                        label = { Text("Name") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = MaterialTheme.shapes.small,
                        enabled = isEditable
                    )
                    OutlinedTextField(
                        value = state.fatherName,
                        onValueChange = { v -> viewModel.update { it.copy(fatherName = v) } },
                        label = { Text("Father Name") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = MaterialTheme.shapes.small,
                        enabled = isEditable
                    )
                    OutlinedTextField(
                        value = state.mobileNumber,
                        onValueChange = { v -> viewModel.update { it.copy(mobileNumber = v) } },
                        label = { Text("Mobile") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = MaterialTheme.shapes.small,
                        enabled = isEditable
                    )
                    OutlinedTextField(
                        value = state.whatsappNumber,
                        onValueChange = { v -> viewModel.update { it.copy(whatsappNumber = v) } },
                        label = { Text("WhatsApp") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
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
                                    tint = if (isEditable) MaterialTheme.colorScheme.primary else Color.Gray
                                )
                            }
                        }
                    )
                }
            }

            IosGroupedCard {
                Column(modifier = Modifier.padding(Dimens.md), verticalArrangement = Arrangement.spacedBy(Dimens.sm)) {
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

                    FilterDropdown(
                        label = "Area",
                        value = state.areas.find { it.areaId == state.areaId }?.areaName ?: "Select Area",
                        expanded = areaExpanded,
                        onExpandedChange = { if (isEditable) areaExpanded = it },
                        options = state.areas.map { it.areaId to it.areaName },
                        onSelect = { id -> if (id != null) viewModel.update { it.copy(areaId = id) } },
                        includeAll = false,
                    )

                    OutlinedTextField(
                        value = state.address,
                        onValueChange = { v -> viewModel.update { it.copy(address = v) } },
                        label = { Text("Address") },
                        modifier = Modifier.fillMaxWidth(),
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
                        trailingIcon = {
                            Icon(Icons.Default.CalendarToday, contentDescription = null)
                        }
                    )

                    OutlinedTextField(
                        value = state.referenceName,
                        onValueChange = { v -> viewModel.update { it.copy(referenceName = v) } },
                        label = { Text("Reference Name") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.small,
                        singleLine = true,
                        enabled = isEditable
                    )
                }
            }

            IosGroupedCard {
                Column(modifier = Modifier.padding(Dimens.md)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(
                            checked = state.isNafiAsbat,
                            onCheckedChange = { v -> viewModel.update { it.copy(isNafiAsbat = v) } },
                            enabled = isEditable
                        )
                        Text("Nafi Asbat")
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(
                            checked = state.isSahibEMehfil,
                            onCheckedChange = { v -> viewModel.update { it.copy(isSahibEMehfil = v) } },
                            enabled = isEditable
                        )
                        Text("Sahib-e-Mehfil")
                    }
                }
            }

            Button(
                onClick = viewModel::save,
                enabled = isEditable,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = MaterialTheme.shapes.small,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Brand.Green,
                    contentColor = Color.White
                )
            ) {
                val label = when {
                    state.isLoadingRecord -> "Loading..."
                    state.isSaving -> "Saving…"
                    salikId == null -> "Save Salik"
                    else -> "Update Salik"
                }
                Text(label, fontWeight = FontWeight.SemiBold)
            }
            
            Spacer(modifier = Modifier.height(Dimens.xl))
        }
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

/** Nav-graph alias used by existing route composables. */
@Composable
fun AddSalikFormScreen(
    salikId: String? = null,
    onBack: () -> Unit = {},
    onSaved: (String) -> Unit = {},
) {
    AddEditSalikScreen(salikId = salikId, onBack = onBack, onSaved = onSaved)
}
