package com.example.salik_management_system.auth.presentation.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.auth.presentation.viewmodel.AuthViewModel
import com.example.salik_management_system.core.auth.staffEmailLocalPartError
import com.example.salik_management_system.core.config.AppConfig
import com.example.salik_management_system.ui.theme.AccentGold
import com.example.salik_management_system.ui.theme.PrimaryGreen

@Composable
fun LoginScreen(
    onLoggedIn: () -> Unit,
    viewModel: AuthViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val session by viewModel.session.collectAsStateWithLifecycle()

    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var obscure by remember { mutableStateOf(true) }
    var usernameError by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(uiState.rememberedLocalPart) {
        if (username.isEmpty() && uiState.rememberedLocalPart.isNotEmpty()) {
            username = uiState.rememberedLocalPart
        }
    }

    LaunchedEffect(session) {
        if (session != null && !uiState.isBootstrapping) {
            onLoggedIn()
        }
    }

    if (uiState.requiresOnlineDialog) {
        AlertDialog(
            onDismissRequest = viewModel::clearOnlineDialog,
            title = { Text("Internet required") },
            text = {
                Text("First login on this device needs an internet connection.")
            },
            confirmButton = {
                TextButton(onClick = viewModel::clearOnlineDialog) {
                    Text("OK")
                }
            },
        )
    }

    if (uiState.isBootstrapping || uiState.isLoading || session != null) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(PrimaryGreen),
            contentAlignment = Alignment.Center,
        ) {
            CircularProgressIndicator(color = AccentGold)
        }
        return
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PrimaryGreen),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = "Salik CRM",
                style = MaterialTheme.typography.headlineMedium,
                color = ColorWhite,
                fontWeight = FontWeight.Bold,
            )
            Text(
                text = AppConfig.envLabel,
                style = MaterialTheme.typography.labelLarge,
                color = AccentGold,
            )
            Spacer(modifier = Modifier.height(24.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        text = "Sign in",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Spacer(modifier = Modifier.height(16.dp))

                    OutlinedTextField(
                        value = username,
                        onValueChange = {
                            username = it
                            usernameError = null
                        },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Username") },
                        suffix = { Text(AppConfig.staffEmailDomain) },
                        singleLine = true,
                        isError = usernameError != null,
                        supportingText = usernameError?.let { { Text(it) } },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Email,
                            imeAction = ImeAction.Next,
                        ),
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Password") },
                        singleLine = true,
                        visualTransformation = if (obscure) {
                            PasswordVisualTransformation()
                        } else {
                            VisualTransformation.None
                        },
                        trailingIcon = {
                            IconButton(onClick = { obscure = !obscure }) {
                                Icon(
                                    imageVector = if (obscure) {
                                        Icons.Filled.Visibility
                                    } else {
                                        Icons.Filled.VisibilityOff
                                    },
                                    contentDescription = if (obscure) "Show password" else "Hide password",
                                )
                            }
                        },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Password,
                            imeAction = ImeAction.Done,
                        ),
                        keyboardActions = KeyboardActions(
                            onDone = {
                                usernameError = staffEmailLocalPartError(username)
                                if (usernameError == null && password.isNotEmpty()) {
                                    viewModel.signIn(username, password)
                                }
                            },
                        ),
                    )

                    uiState.errorMessage?.let { error ->
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = error,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = {
                            usernameError = staffEmailLocalPartError(username)
                            if (usernameError == null && password.isNotEmpty()) {
                                viewModel.signIn(username, password)
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryGreen),
                    ) {
                        Text("Sign in")
                    }
                }
            }
        }
    }
}

private val ColorWhite = androidx.compose.ui.graphics.Color.White
