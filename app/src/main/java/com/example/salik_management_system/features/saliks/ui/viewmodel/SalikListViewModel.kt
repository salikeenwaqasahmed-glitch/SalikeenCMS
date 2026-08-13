package com.example.salik_management_system.features.saliks.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.core.utils.AppLog
import com.example.salik_management_system.features.saliks.data.repository.AreaRepository
import com.example.salik_management_system.features.saliks.data.repository.SalikRepository
import com.example.salik_management_system.features.saliks.domain.model.ApprovalStatus
import com.example.salik_management_system.features.saliks.domain.model.Area
import com.example.salik_management_system.features.saliks.domain.model.Bazam
import com.example.salik_management_system.features.saliks.domain.model.Salik
import com.example.salik_management_system.features.saliks.domain.model.SalikDuplicateGroup
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
import kotlin.math.ceil

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
    /** Full filtered list (for counts / bazam screens). */
    val saliks: List<Salik> = emptyList(),
    /** Current page slice for directory. */
    val pageItems: List<Salik> = emptyList(),
    val areas: List<Area> = emptyList(),
    val bazams: List<Bazam> = emptyList(),
    val filters: SalikListFilters = SalikListFilters(),
    val selectedIds: Set<String> = emptySet(),
    val isSelectionMode: Boolean = false,
    val page: Int = 1,
    val pageSize: Int = 20,
    val totalCount: Int = 0,
    val totalPages: Int = 1,
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

    private val _page = MutableStateFlow(1)
    private val _message = MutableStateFlow<String?>(null)
    private val _selectedIds = MutableStateFlow<Set<String>>(emptySet())
    private val _isSelectionMode = MutableStateFlow(false)

    val uiState: StateFlow<SalikListUiState> = authRepository.session
        .flatMapLatest { session ->
            val paging = combine(
                _filters,
                _page,
                _message,
                _selectedIds,
                _isSelectionMode
            ) { filters, page, message, selected, selectionMode ->
                DataBundle(filters, page, message, selected, selectionMode)
            }
            combine(
                salikRepository.watchDirectory(session),
                areaRepository.watchAreas(),
                areaRepository.watchBazams(),
                paging,
            ) { saliks, areas, bazams, meta ->
                val (filters, page, message, selected, selectionMode) = meta
                val filtered = applyFilters(saliks, filters)
                val total = filtered.size
                val totalPages = ceil(total / PAGE_SIZE.toDouble()).toInt().coerceAtLeast(1)
                val safePage = page.coerceIn(1, totalPages)
                val from = (safePage - 1) * PAGE_SIZE
                val pageItems = if (from >= total) {
                    emptyList()
                } else {
                    filtered.subList(from, minOf(from + PAGE_SIZE, total))
                }
                SalikListUiState(
                    session = session,
                    saliks = filtered,
                    pageItems = pageItems,
                    areas = areas,
                    bazams = bazams,
                    filters = filters,
                    selectedIds = selected,
                    isSelectionMode = selectionMode,
                    page = safePage,
                    pageSize = PAGE_SIZE,
                    totalCount = total,
                    totalPages = totalPages,
                    canCreate = session != null && AccessControl.canCreate(session.role),
                    message = message,
                )
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SalikListUiState())

    private data class DataBundle(
        val filters: SalikListFilters,
        val page: Int,
        val message: String?,
        val selected: Set<String>,
        val selectionMode: Boolean
    )

    val pendingSaliks: StateFlow<List<Salik>> = authRepository.session
        .flatMapLatest { salikRepository.watchPending(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val duplicateGroups: StateFlow<List<SalikDuplicateGroup>> = authRepository.session
        .flatMapLatest { salikRepository.watchDuplicateGroups(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun setQuery(query: String) {
        _filters.update { it.copy(query = query) }
        resetPage()
    }

    fun clearTypeFilters() {
        _filters.update {
            it.copy(
                status = null,
                nafiOnly = false,
                sahibOnly = false
            )
        }
        resetPage()
    }

    fun setBazam(bazamId: String?) {
        _filters.update { it.copy(bazamId = bazamId, areaId = null) }
        resetPage()
    }

    fun setArea(areaId: String?) {
        _filters.update { it.copy(areaId = areaId) }
        resetPage()
    }

    fun setStatus(status: ApprovalStatus?) {
        _filters.update {
            it.copy(
                status = status,
                nafiOnly = false,
                sahibOnly = false
            )
        }
        resetPage()
    }

    fun setNafiOnly(enabled: Boolean) {
        _filters.update {
            if (enabled) {
                AppLog.d("SalikListVM", "Filtering for Nafi only")
                it.copy(nafiOnly = true, sahibOnly = false, status = null)
            } else {
                AppLog.d("SalikListVM", "Clearing Nafi filter")
                it.copy(nafiOnly = false)
            }
        }
        resetPage()
    }

    fun setSahibOnly(enabled: Boolean) {
        _filters.update {
            if (enabled) {
                AppLog.d("SalikListVM", "Filtering for Sahib only")
                it.copy(sahibOnly = true, nafiOnly = false, status = null)
            } else {
                AppLog.d("SalikListVM", "Clearing Sahib filter")
                it.copy(sahibOnly = false)
            }
        }
        resetPage()
    }

    fun toggleSelectionMode() {
        _isSelectionMode.update { !it }
        if (!_isSelectionMode.value) {
            _selectedIds.value = emptySet()
        }
    }

    fun toggleSelection(id: String) {
        _selectedIds.update { current ->
            if (id in current) current - id else current + id
        }
    }

    fun clearSelection() {
        _selectedIds.value = emptySet()
    }

    fun nextPage() {
        _page.update { p ->
            val max = uiState.value.totalPages
            (p + 1).coerceAtMost(max)
        }
    }

    fun prevPage() {
        _page.update { (it - 1).coerceAtLeast(1) }
    }

    fun goToPage(page: Int) {
        val max = uiState.value.totalPages
        _page.value = page.coerceIn(1, max)
    }

    fun clearMessage() {
        _message.value = null
    }

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

    fun exportSelected(onReady: (String) -> Unit) {
        val selected = _selectedIds.value
        if (selected.isEmpty()) return
        val allSaliks = uiState.value.saliks
        val toExport = allSaliks.filter { it.salikId in selected }
        val areaLookup = uiState.value.areas.associateBy { it.areaId }
        val csv = com.example.salik_management_system.core.export.SalikCsvExport.build(toExport, areaLookup)
        onReady(csv)
    }

    fun getSelectedPhones(): List<String> {
        val selected = _selectedIds.value
        val allSaliks = uiState.value.saliks
        return allSaliks.filter { it.salikId in selected }
            .map { it.mobileNumber.ifEmpty { it.whatsappNumber } }
            .filter { it.isNotBlank() }
    }

    fun areasForBazam(bazamId: String): StateFlow<List<Area>> =
        areaRepository.watchAreas()
            .map { list -> list.filter { it.bazamId == bazamId } }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private fun resetPage() {
        _page.value = 1
    }

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
        val result = saliks.filter { s ->
            val matchesQuery = q.isEmpty() ||
                    s.name.lowercase().contains(q) ||
                    s.fatherName.lowercase().contains(q) ||
                    s.mobileNumber.contains(q) ||
                    s.whatsappNumber.contains(q)
            
            val matchesBazam = filters.bazamId == null || s.bazamId == filters.bazamId ||
                    (s.bazamId.isEmpty() && filters.bazamId == "i-10")
            
            val matchesArea = filters.areaId == null || s.areaId == filters.areaId
            
            val matchesStatus = filters.status == null || s.approvalStatus == filters.status
            
            val matchesNafi = !filters.nafiOnly || s.isNafiAsbat
            
            val matchesSahib = !filters.sahibOnly || s.isSahibEMehfil

            matchesQuery && matchesBazam && matchesArea && matchesStatus && matchesNafi && matchesSahib
        }
        
        AppLog.d("SalikListVM", "applyFilters: Input=${saliks.size}, Output=${result.size}, Filters=$filters")
        return result
    }

    companion object {
        const val PAGE_SIZE = 20
    }
}
