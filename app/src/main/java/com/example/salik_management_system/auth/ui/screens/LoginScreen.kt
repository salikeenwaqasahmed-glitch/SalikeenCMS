package com.example.salik_management_system.auth.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.salik_management_system.auth.ui.viewmodel.AuthViewModel
import com.example.salik_management_system.core.auth.staffEmailLocalPartError
import com.example.salik_management_system.core.config.AppConfig
import com.example.salik_management_system.ui.components.BrandMark
import com.example.salik_management_system.ui.components.StatusChip
import com.example.salik_management_system.ui.components.StatusTone
import com.example.salik_management_system.ui.theme.AccentGold
import com.example.salik_management_system.ui.theme.Dimens
import com.example.salik_management_system.ui.theme.PrimaryGreen
import com.example.salik_management_system.ui.theme.PrimaryGreenLight

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

    val heroBrush = Brush.verticalGradient(
        colors = listOf(
            PrimaryGreen,
            PrimaryGreenLight,
            Color(0xFF061510),
        ),
    )

    if (uiState.isBootstrapping || (uiState.isLoading && session == null) || session != null) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(heroBrush),
            contentAlignment = Alignment.Center,
        ) {
            CircularProgressIndicator(color = AccentGold)
        }
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(heroBrush),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = Dimens.xl)
                .padding(top = Dimens.md, bottom = Dimens.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            BrandMark(onDark = true)
            Spacer(modifier = Modifier.height(Dimens.md))
            Text(
                text = "Salikeen CMS",
                style = MaterialTheme.typography.headlineMedium,
                color = Color.White,
                fontWeight = FontWeight.Bold,
            )
            Spacer(modifier = Modifier.height(Dimens.xxs))
            Text(
                text = "Staff directory · secure access",
                style = MaterialTheme.typography.bodyMedium,
                color = AccentGold.copy(alpha = 0.92f),
            )
            if (AppConfig.isDev) {
                Spacer(modifier = Modifier.height(Dimens.sm))
                StatusChip(label = "DEV", tone = StatusTone.Gold)
            }
        }

        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
            shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
            color = MaterialTheme.colorScheme.surface,
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = Dimens.xl, vertical = Dimens.xl),
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(3.dp)
                        .background(
                            Brush.horizontalGradient(
                                listOf(PrimaryGreen, AccentGold, PrimaryGreenLight),
                            ),
                            RoundedCornerShape(2.dp),
                        ),
                )
                Spacer(modifier = Modifier.height(Dimens.lg))
                Text(
                    text = "Sign in",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text = "Use your staff username — no email domain",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = Dimens.xxs, bottom = Dimens.lg),
                )

                val fieldColors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = PrimaryGreen,
                    focusedLabelColor = PrimaryGreen,
                    cursorColor = PrimaryGreen,
                )

                OutlinedTextField(
                    value = username,
                    onValueChange = {
                        username = it.filter { c -> c != ' ' }
                        usernameError = null
                        viewModel.clearError()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Username") },
                    singleLine = true,
                    isError = usernameError != null,
                    supportingText = usernameError?.let { { Text(it) } },
                    colors = fieldColors,
                    shape = MaterialTheme.shapes.small,
                    keyboardOptions = KeyboardOptions(
                        capitalization = KeyboardCapitalization.None,
                        autoCorrectEnabled = false,
                        keyboardType = KeyboardType.Ascii,
                        imeAction = ImeAction.Next,
                    ),
                )
                Spacer(modifier = Modifier.height(Dimens.xs))
                OutlinedTextField(
                    value = password,
                    onValueChange = {
                        password = it
                        viewModel.clearError()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Password") },
                    singleLine = true,
                    enabled = !uiState.isLoading,
                    colors = fieldColors,
                    shape = MaterialTheme.shapes.small,
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
                                contentDescription = if (obscure) {
                                    "Show password"
                                } else {
                                    "Hide password"
                                },
                            )
                        }
                    },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Password,
                        imeAction = ImeAction.Done,
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = {
                            attemptSignIn(
                                username = username,
                                password = password,
                                setUsernameError = { usernameError = it },
                                signIn = viewModel::signIn,
                                isLoading = uiState.isLoading,
                            )
                        },
                    ),
                )

                uiState.errorMessage?.let { error ->
                    Spacer(modifier = Modifier.height(Dimens.xs))
                    Text(
                        text = error,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall,
                    )
                }

                Spacer(modifier = Modifier.height(Dimens.lg))
                Button(
                    onClick = {
                        attemptSignIn(
                            username = username,
                            password = password,
                            setUsernameError = { usernameError = it },
                            signIn = viewModel::signIn,
                            isLoading = uiState.isLoading,
                        )
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    enabled = !uiState.isLoading,
                    shape = MaterialTheme.shapes.small,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = PrimaryGreen,
                        contentColor = AccentGold,
                    ),
                ) {
                    if (uiState.isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.height(22.dp),
                            color = AccentGold,
                            strokeWidth = 2.dp,
                        )
                    } else {
                        Text(
                            "Sign in",
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                }
            }
        }
    }
}

private fun attemptSignIn(
    username: String,
    password: String,
    setUsernameError: (String?) -> Unit,
    signIn: (String, String) -> Unit,
    isLoading: Boolean,
) {
    if (isLoading) return
    val error = staffEmailLocalPartError(username)
    setUsernameError(error)
    if (error == null && password.isNotEmpty()) {
        signIn(username.trim(), password)
    }
}
