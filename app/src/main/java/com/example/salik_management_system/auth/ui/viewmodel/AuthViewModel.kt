package com.example.salik_management_system.auth.ui.viewmodel

import com.example.salik_management_system.core.sync.SyncService
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.data.ProfileNotFoundException
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.auth.LocalAuthStore
import com.example.salik_management_system.core.auth.NoLocalUserOfflineException
import com.example.salik_management_system.core.auth.OfflineWrongPasswordException
import com.example.salik_management_system.core.auth.composeStaffEmail
import com.example.salik_management_system.core.auth.localPartFromStaffEmail
import com.example.salik_management_system.core.auth.staffEmailLocalPartError
import com.example.salik_management_system.core.utils.AppLog
import com.google.firebase.FirebaseNetworkException
import com.google.firebase.auth.FirebaseAuthException
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
    /** One-shot after first online login caches credentials. */
    val offlineReadyMessage: String? = null,
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val localAuthStore: LocalAuthStore,
    private val syncService: SyncService,
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
                authRepository.fetchSession()
                val restored = authRepository.session.value
                AppLog.i(
                    "Auth",
                    "Session bootstrap done uid=${restored?.uid} role=${restored?.role?.toFirestore()}",
                )
                _uiState.value = _uiState.value.copy(
                    isBootstrapping = false,
                    rememberedLocalPart = localPart,
                )
            } catch (e: Exception) {
                AppLog.e("Auth", "Session bootstrap failed: ${e.message}", e)
                _uiState.value = _uiState.value.copy(
                    isBootstrapping = false,
                    rememberedLocalPart = localPart,
                    errorMessage = e.message,
                )
            }
        }
    }

    fun signIn(username: String, password: String) {
        if (_uiState.value.isLoading) return

        val trimmedUser = username.trim()
        val userError = staffEmailLocalPartError(trimmedUser)
        if (userError != null) {
            _uiState.value = _uiState.value.copy(errorMessage = userError)
            return
        }
        if (password.isEmpty()) {
            _uiState.value = _uiState.value.copy(errorMessage = "Password required")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                isLoading = true,
                errorMessage = null,
                requiresOnlineDialog = false,
                offlineReadyMessage = null,
            )
            val email = composeStaffEmail(trimmedUser)
            AppLog.i("Auth", "signIn start email=$email")
            try {
                val hadLocal = localAuthStore.getUserByEmail(email) != null
                authRepository.signIn(email, password)
                AppLog.i("Auth", "signIn ok uid=${authRepository.session.value?.uid}")
                // One sync per explicit successful login, independent of screen lifecycle.
                val signedInSession = authRepository.session.value
                viewModelScope.launch {
                    syncService.syncNow(signedInSession)
                }
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    offlineReadyMessage = if (!hadLocal) {
                        "Saved for offline use."
                    } else {
                        null
                    },
                )
            } catch (_: NoLocalUserOfflineException) {
                AppLog.w("Auth", "signIn failed: first login needs internet")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    requiresOnlineDialog = true,
                    errorMessage = "Internet required for first login on this device.",
                )
            } catch (_: OfflineWrongPasswordException) {
                AppLog.w("Auth", "signIn failed: wrong password (offline)")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Wrong username or password.",
                )
            } catch (_: ProfileNotFoundException) {
                AppLog.w("Auth", "signIn failed: Firestore profile missing")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Staff profile not found — ask admin.",
                )
            } catch (e: FirebaseAuthException) {
                AppLog.w("Auth", "signIn FirebaseAuthException code=${e.errorCode}")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = mapFirebaseAuthError(e),
                )
            } catch (_: FirebaseNetworkException) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Network error — check connection.",
                )
            } catch (e: Exception) {
                val mapped = (e.cause as? FirebaseAuthException)?.let { mapFirebaseAuthError(it) }
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = mapped ?: "Sign-in failed.",
                )
                AppLog.e("Auth", "signIn failed: $e", e)
            }
        }
    }

    fun clearOnlineDialog() {
        _uiState.value = _uiState.value.copy(requiresOnlineDialog = false)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    fun clearOfflineReadyMessage() {
        _uiState.value = _uiState.value.copy(offlineReadyMessage = null)
    }

    fun signOut() {
        viewModelScope.launch {
            AppLog.i("Auth", "signOut")
            authRepository.signOut()
        }
    }

    private fun mapFirebaseAuthError(e: FirebaseAuthException): String {
        return when (e.errorCode) {
            "ERROR_WRONG_PASSWORD",
            "ERROR_USER_NOT_FOUND",
            "ERROR_INVALID_CREDENTIAL",
            "ERROR_INVALID_EMAIL",
            -> "Wrong username or password."
            "ERROR_TOO_MANY_REQUESTS" -> "Too many attempts — try later."
            "ERROR_NETWORK_REQUEST_FAILED" -> "Network error — check connection."
            "ERROR_USER_DISABLED" -> "Account disabled — ask admin."
            else -> "Sign-in failed."
        }
    }

}
