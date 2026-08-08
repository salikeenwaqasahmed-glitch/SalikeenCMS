package com.example.salik_management_system.features.saliks.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.features.saliks.data.AreaRepository
import com.example.salik_management_system.features.saliks.data.SalikRepository
import com.example.salik_management_system.features.saliks.domain.Area
import com.example.salik_management_system.features.saliks.domain.ApprovalStatus
import com.example.salik_management_system.features.saliks.domain.Bazam
import com.example.salik_management_system.features.saliks.domain.Salik
import com.example.salik_management_system.features.saliks.domain.SalikDuplicateGroup
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SalikListFilters(
    val query: String = "",
    val bazamId: String? = null,
    val areaId: String? = null,
    val status: ApprovalStatus? = null,
    val nafiOnly: Boolean = false,
    val sahibOnly: Boolean = false,
)

data class SalikListUiState(
    val session: UserSession? = null,
    val saliks: List<Salik> = emptyList(),
    val areas: List<Area> = emptyList(),
    val bazams: List<Bazam> = emptyList(),
    val filters: SalikListFilters = SalikListFilters(),
    val canCreate: Boolean = false,
    val message: String? = null,
)

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class SalikListViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val salikRepository: SalikRepository,
    private val areaRepository: AreaRepository,
) : ViewModel() {
    private val _filters = MutableStateFlow(SalikListFilters())
    val filters: StateFlow<SalikListFilters> = _filters.asStateFlow()

    private val _message = MutableStateFlow<String?>(null)

    val uiState: StateFlow<SalikListUiState> = authRepository.session
        .flatMapLatest { session ->
            combine(
                salikRepository.watchDirectory(session),
                areaRepository.watchAreas(),
                areaRepository.watchBazams(),
                _filters,
                _message,
            ) { saliks, areas, bazams, filters, message ->
                SalikListUiState(
                    session = session,
                    saliks = applyFilters(saliks, filters),
                    areas = areas,
                    bazams = bazams,
                    filters = filters,
                    canCreate = session != null && AccessControl.canCreate(session.role),
                    message = message,
                )
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SalikListUiState())

    val pendingSaliks: StateFlow<List<Salik>> = authRepository.session
        .flatMapLatest { salikRepository.watchPending(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val duplicateGroups: StateFlow<List<SalikDuplicateGroup>> = authRepository.session
        .flatMapLatest { salikRepository.watchDuplicateGroups(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun setQuery(query: String) = _filters.update { it.copy(query = query) }
    fun setBazam(bazamId: String?) = _filters.update { it.copy(bazamId = bazamId, areaId = null) }
    fun setArea(areaId: String?) = _filters.update { it.copy(areaId = areaId) }
    fun setStatus(status: ApprovalStatus?) = _filters.update { it.copy(status = status) }
    fun clearMessage() { _message.value = null }

    fun approve(id: String) = act { session ->
        salikRepository.approve(id, session)
        _message.value = "Approved"
    }

    fun reject(id: String) = act { session ->
        salikRepository.reject(id, session)
        _message.value = "Rejected"
    }

    fun delete(id: String) = act { session ->
        salikRepository.delete(id, session)
        _message.value = "Deleted"
    }

    fun mergeGroup(keepId: String, removeIds: List<String>) = act { session ->
        salikRepository.mergeDuplicates(session, keepId, removeIds)
        _message.value = "Merged"
    }

    fun areasForBazam(bazamId: String): StateFlow<List<Area>> =
        areaRepository.watchAreas()
            .map { list -> list.filter { it.bazamId == bazamId } }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private fun act(block: suspend (UserSession) -> Unit) {
        viewModelScope.launch {
            val session = authRepository.session.value ?: return@launch
            try {
                block(session)
            } catch (e: Exception) {
                _message.value = e.message ?: "Action failed"
            }
        }
    }

    private fun applyFilters(saliks: List<Salik>, filters: SalikListFilters): List<Salik> {
        val q = filters.query.trim().lowercase()
        return saliks.filter { s ->
            (q.isEmpty() ||
                s.name.lowercase().contains(q) ||
                s.fatherName.lowercase().contains(q) ||
                s.mobileNumber.contains(q) ||
                s.whatsappNumber.contains(q)) &&
                (filters.bazamId == null || s.bazamId == filters.bazamId ||
                    (s.bazamId.isEmpty() && filters.bazamId == "i-10")) &&
                (filters.areaId == null || s.areaId == filters.areaId) &&
                (filters.status == null || s.approvalStatus == filters.status) &&
                (!filters.nafiOnly || s.isNafiAsbat) &&
                (!filters.sahibOnly || s.isSahibEMehfil)
        }
    }
}
