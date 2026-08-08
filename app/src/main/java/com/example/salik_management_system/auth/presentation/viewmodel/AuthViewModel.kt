package com.example.salik_management_system.auth.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.auth.LocalAuthStore
import com.example.salik_management_system.core.auth.composeStaffEmail
import com.example.salik_management_system.core.auth.localPartFromStaffEmail
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AuthUiState(
    val isLoading: Boolean = false,
    val isBootstrapping: Boolean = true,
    val errorMessage: String? = null,
    val rememberedLocalPart: String = "",
    val requiresOnlineDialog: Boolean = false,
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val localAuthStore: LocalAuthStore,
) : ViewModel() {
    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    val session: StateFlow<UserSession?> = authRepository.session
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    init {
        viewModelScope.launch {
            val remembered = localAuthStore.getRememberedEmail()
            val localPart = remembered?.let { localPartFromStaffEmail(it) }.orEmpty()
            try {
                val restored = authRepository.fetchSession()
                _uiState.value = _uiState.value.copy(
                    isBootstrapping = false,
                    rememberedLocalPart = localPart,
                )
                if (restored != null) {
                    // session StateFlow already updated by repository
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isBootstrapping = false,
                    rememberedLocalPart = localPart,
                    errorMessage = e.message,
                )
            }
        }
    }

    fun signIn(username: String, password: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                isLoading = true,
                errorMessage = null,
                requiresOnlineDialog = false,
            )
            try {
                val email = composeStaffEmail(username)
                authRepository.signIn(email, password)
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: com.example.salik_management_system.core.auth.NoLocalUserOfflineException) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    requiresOnlineDialog = true,
                    errorMessage = "Internet required for first login on this device.",
                )
            } catch (e: com.example.salik_management_system.core.auth.OfflineWrongPasswordException) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Wrong password.",
                )
            } catch (e: com.example.salik_management_system.auth.data.ProfileNotFoundException) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Staff profile not found.",
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Sign-in failed.",
                )
            }
        }
    }

    fun clearOnlineDialog() {
        _uiState.value = _uiState.value.copy(requiresOnlineDialog = false)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    fun signOut() {
        viewModelScope.launch {
            authRepository.signOut()
        }
    }
}
