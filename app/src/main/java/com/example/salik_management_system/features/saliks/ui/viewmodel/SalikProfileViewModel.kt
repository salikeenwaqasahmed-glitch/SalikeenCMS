package com.example.salik_management_system.features.saliks.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.features.saliks.data.repository.AreaRepository
import com.example.salik_management_system.features.saliks.data.repository.SalikRepository
import com.example.salik_management_system.features.saliks.domain.model.Area
import com.example.salik_management_system.features.saliks.domain.model.Bazam
import com.example.salik_management_system.features.saliks.domain.model.Salik
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SalikProfileUiState(
    val salik: Salik? = null,
    val area: Area? = null,
    val bazam: Bazam? = null,
    val session: UserSession? = null,
    val canApprove: Boolean = false,
    val canUpdate: Boolean = false,
    val canDelete: Boolean = false,
    val isLoading: Boolean = true,
    val message: String? = null,
)

@HiltViewModel
class SalikProfileViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val salikRepository: SalikRepository,
    private val areaRepository: AreaRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val salikId: String = savedStateHandle["id"] ?: ""
    private val _message = MutableStateFlow<String?>(null)

    val uiState: StateFlow<SalikProfileUiState> = combine(
        salikRepository.watchById(salikId),
        authRepository.session,
        areaRepository.watchAreas(),
        areaRepository.watchBazams(),
        _message,
    ) { salik, session, areas, bazams, message ->
        SalikProfileUiState(
            salik = salik,
            area = salik?.let { s -> areas.firstOrNull { it.areaId == s.areaId } },
            bazam = salik?.let { s -> bazams.firstOrNull { it.bazamId == s.bazamId } },
            session = session,
            canApprove = session != null && AccessControl.canApprove(session.role) &&
                salik?.isPending == true,
            canUpdate = session != null && AccessControl.canUpdate(session.role),
            canDelete = session != null && AccessControl.canDelete(session.role),
            isLoading = false,
            message = message,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SalikProfileUiState())

    fun approve() = act { s, session ->
        salikRepository.approve(s.salikId, session)
        _message.value = "Approved"
    }

    fun reject() = act { s, session ->
        salikRepository.reject(s.salikId, session)
        _message.value = "Rejected"
    }

    fun delete() = act { s, session ->
        salikRepository.delete(s.salikId, session)
        _message.value = "Deleted"
    }

    fun toggleActive(active: Boolean) = act { s, session ->
        salikRepository.toggleActive(s.salikId, active, session)
    }

    fun clearMessage() {
        _message.value = null
    }

    private fun act(block: suspend (Salik, UserSession) -> Unit) {
        viewModelScope.launch {
            val session = authRepository.session.value ?: return@launch
            val salik = salikRepository.getById(salikId) ?: return@launch
            try {
                block(salik, session)
            } catch (e: Exception) {
                _message.value = e.message
            }
        }
    }
}
