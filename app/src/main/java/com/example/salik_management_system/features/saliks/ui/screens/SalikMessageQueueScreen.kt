package com.example.salik_management_system.features.saliks.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.core.utils.ContactLauncher
import com.example.salik_management_system.features.saliks.ui.viewmodel.SalikListViewModel

enum class MessageChannel { WhatsApp, Sms }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SalikMessageQueueScreen(
    salikIds: List<String> = emptyList(),
    onBack: () -> Unit = {},
    viewModel: SalikListViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val queue = remember(salikIds, state.saliks) {
        if (salikIds.isEmpty()) {
            state.saliks
        } else {
            val idSet = salikIds.toSet()
            state.saliks.filter { it.salikId in idSet }
        }
    }
    var index by remember { mutableIntStateOf(0) }
    var channel by remember { mutableStateOf(MessageChannel.WhatsApp) }
    var template by remember { mutableStateOf("Assalam o Alaikum") }
    val context = LocalContext.current

    LaunchedEffect(queue.size) {
        if (index >= queue.size) index = 0
    }

    val current = queue.getOrNull(index)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Message queue") },
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                if (queue.isEmpty()) {
                    "No saliks in queue — open from directory selection or browse first."
                } else {
                    "${index + 1} / ${queue.size}"
                },
                style = MaterialTheme.typography.titleMedium,
            )

            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                MessageChannel.entries.forEachIndexed { i, item ->
                    SegmentedButton(
                        selected = channel == item,
                        onClick = { channel = item },
                        shape = SegmentedButtonDefaults.itemShape(
                            index = i,
                            count = MessageChannel.entries.size,
                        ),
                    ) {
                        Text(item.name)
                    }
                }
            }

            OutlinedTextField(
                value = template,
                onValueChange = { template = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Message template") },
                minLines = 3,
            )

            if (current != null) {
                Text(current.name, style = MaterialTheme.typography.headlineSmall)
                Text(current.mobileNumber.ifBlank { current.whatsappNumber })

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(
                        onClick = {
                            val phone = current.whatsappNumber.ifBlank { current.mobileNumber }
                            val intent = when (channel) {
                                MessageChannel.WhatsApp ->
                                    ContactLauncher.whatsappIntent(phone, template)
                                MessageChannel.Sms ->
                                    ContactLauncher.smsIntent(phone, template)
                            }
                            ContactLauncher.launch(context, intent)
                            if (index < queue.lastIndex) index++
                        },
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Send / Open")
                    }
                    OutlinedButton(
                        onClick = { if (index < queue.lastIndex) index++ },
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Skip")
                    }
                }
                OutlinedButton(
                    onClick = onBack,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Done")
                }
            }
        }
    }
}
