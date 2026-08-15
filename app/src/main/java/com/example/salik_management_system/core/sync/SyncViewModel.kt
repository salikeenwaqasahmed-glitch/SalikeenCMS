package com.example.salik_management_system.core.sync

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.core.network.ConnectivityService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SyncUiState(
    val isSyncing: Boolean = false,
    val lastMessage: String? = null,
    val lastOk: Boolean? = null,
)

@HiltViewModel
class SyncViewModel @Inject constructor(
    private val syncService: SyncService,
    private val authRepository: AuthRepository,
    connectivity: ConnectivityService,
) : ViewModel() {
    private val _uiState = MutableStateFlow(SyncUiState())
    val uiState: StateFlow<SyncUiState> = _uiState.asStateFlow()

    val isOnline: StateFlow<Boolean> = connectivity.watchOnline()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), connectivity.isOnline)

    val pendingCount: StateFlow<Int> = syncService.pendingCount
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    fun syncNow(onResult: ((SyncResult) -> Unit)? = null) {
        if (_uiState.value.isSyncing) return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSyncing = true, lastMessage = null)
            val result = syncService.syncNow(authRepository.session.value)
            _uiState.value = SyncUiState(
                isSyncing = false,
                lastMessage = result.message,
                lastOk = result.ok,
            )
            onResult?.invoke(result)
        }
    }
}
