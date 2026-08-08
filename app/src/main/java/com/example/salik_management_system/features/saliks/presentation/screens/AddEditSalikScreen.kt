package com.example.salik_management_system.features.saliks.presentation.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.features.saliks.presentation.viewmodel.SalikFormViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditSalikScreen(
    salikId: String? = null,
    onBack: () -> Unit = {},
    onSaved: (String) -> Unit = {},
    viewModel: SalikFormViewModel = hiltViewModel(),
) {
    val form by viewModel.form.collectAsStateWithLifecycle()
    var areaExpanded by remember { mutableStateOf(false) }
    var genderExpanded by remember { mutableStateOf(false) }

    LaunchedEffect(salikId) {
        viewModel.load(salikId)
    }
    LaunchedEffect(form.savedId) {
        val id = form.savedId ?: return@LaunchedEffect
        onSaved(id)
        viewModel.clearSaved()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (salikId == null) "Add salik" else "Edit salik") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
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
            form.error?.let { Text(it, color = androidx.compose.material3.MaterialTheme.colorScheme.error) }

            OutlinedTextField(
                value = form.name,
                onValueChange = { v -> viewModel.update { it.copy(name = v) } },
                label = { Text("Name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
            )
            OutlinedTextField(
                value = form.fatherName,
                onValueChange = { v -> viewModel.update { it.copy(fatherName = v) } },
                label = { Text("Father name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
            )
            OutlinedTextField(
                value = form.mobileNumber,
                onValueChange = { v -> viewModel.update { it.copy(mobileNumber = v) } },
                label = { Text("Mobile") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
            )
            OutlinedTextField(
                value = form.whatsappNumber,
                onValueChange = { v -> viewModel.update { it.copy(whatsappNumber = v) } },
                label = { Text("WhatsApp") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
            )

            if (form.canSetGender) {
                FilterDropdown(
                    label = "Gender",
                    value = form.genderId,
                    expanded = genderExpanded,
                    onExpandedChange = { genderExpanded = it },
                    options = listOf("Male" to "Male", "Female" to "Female"),
                    onSelect = { g -> if (g != null) viewModel.update { it.copy(genderId = g) } },
                    includeAll = false,
                )
            } else {
                OutlinedTextField(
                    value = form.genderId,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Gender") },
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            FilterDropdown(
                label = "Area",
                value = form.areas.firstOrNull { it.areaId == form.areaId }?.areaName
                    ?: if (form.areaId.isEmpty()) "Select area" else form.areaId,
                expanded = areaExpanded,
                onExpandedChange = { areaExpanded = it },
                options = form.areas.map { it.areaId to it.areaName },
                onSelect = { id -> if (id != null) viewModel.update { it.copy(areaId = id) } },
                includeAll = false,
            )

            OutlinedTextField(
                value = form.address,
                onValueChange = { v -> viewModel.update { it.copy(address = v) } },
                label = { Text("Address") },
                modifier = Modifier.fillMaxWidth(),
            )

            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(
                    checked = form.isNafiAsbat,
                    onCheckedChange = { v -> viewModel.update { it.copy(isNafiAsbat = v) } },
                )
                Text("Nafi Asbat")
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(
                    checked = form.isSahibEMehfil,
                    onCheckedChange = { v -> viewModel.update { it.copy(isSahibEMehfil = v) } },
                )
                Text("Sahib-e-Mehfil")
            }

            Button(
                onClick = viewModel::save,
                enabled = !form.isSaving,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(if (form.isSaving) "Saving…" else "Save")
            }
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
