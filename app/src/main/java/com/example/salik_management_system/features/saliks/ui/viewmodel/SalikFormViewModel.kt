package com.example.salik_management_system.features.saliks.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.sync.SyncService
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.core.utils.AppLog
import com.example.salik_management_system.features.saliks.data.repository.AreaRepository
import com.example.salik_management_system.features.saliks.data.repository.SalikRepository
import com.example.salik_management_system.features.saliks.domain.model.Area
import com.example.salik_management_system.features.saliks.domain.model.Bazam
import com.example.salik_management_system.features.saliks.domain.model.DuplicateSalikException
import com.example.salik_management_system.features.saliks.domain.model.Salik
import com.example.salik_management_system.features.saliks.domain.model.kDefaultBazamId
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

data class SalikFormState(
    val salikId: String? = null,
    val name: String = "",
    val fatherName: String = "",
    val mobileNumber: String = "",
    val whatsappNumber: String = "",
    val genderId: String = "Male",
    val bazamId: String = "",
    val areaId: String = "",
    val address: String = "",
    val isNafiAsbat: Boolean = false,
    val isSahibEMehfil: Boolean = false,
    val referenceName: String = "",
    val dateOfBaith: String = LocalDate.now().toString(),
    val areas: List<Area> = emptyList(),
    val bazams: List<Bazam> = emptyList(),
    val canSetGender: Boolean = true,
    val isLoadingRecord: Boolean = false,
    val isSaving: Boolean = false,
    val error: String? = null,
    val savedId: String? = null,
)

@HiltViewModel
class SalikFormViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val salikRepository: SalikRepository,
    private val areaRepository: AreaRepository,
    private val syncService: SyncService,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val editId: String? = savedStateHandle["id"]
        ?: savedStateHandle.get<String>("salikId")

    private val _form = MutableStateFlow(SalikFormState(salikId = editId))
    val form: StateFlow<SalikFormState> = _form.asStateFlow()

    val session: StateFlow<UserSession?> = authRepository.session
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    init {
        viewModelScope.launch {
            areaRepository.watchAreas().collect { areas ->
                _form.update { it.copy(areas = areas) }
            }
        }
        viewModelScope.launch {
            areaRepository.watchBazams().collect { bazams ->
                _form.update { it.copy(bazams = bazams) }
            }
        }
        viewModelScope.launch {
            authRepository.session.collect { session ->
                if (session == null) return@collect
                _form.update {
                    it.copy(
                        canSetGender = AccessControl.canSetGender(session),
                        genderId = if (AccessControl.canSetGender(session)) {
                            it.genderId
                        } else {
                            AccessControl.effectiveGender(session, it.genderId)
                        },
                    )
                }
            }
        }
        if (!editId.isNullOrEmpty()) {
            viewModelScope.launch {
                val salik = salikRepository.getById(editId) ?: return@launch
                _form.update {
                    it.copy(
                        salikId = salik.salikId,
                        name = salik.name,
                        fatherName = salik.fatherName,
                        mobileNumber = salik.mobileNumber,
                        whatsappNumber = salik.whatsappNumber,
                        genderId = salik.genderId,
                        bazamId = salik.bazamId,
                        areaId = salik.areaId,
                        address = salik.address,
                        isNafiAsbat = salik.isNafiAsbat,
                        isSahibEMehfil = salik.isSahibEMehfil,
                        referenceName = salik.referenceName,
                        dateOfBaith = salik.dateOfBaith.ifEmpty { LocalDate.now().toString() },
                    )
                }
            }
        }
    }

    fun update(block: (SalikFormState) -> SalikFormState) {
        _form.update { prevState ->
            val newState = block(prevState)
            // If area changed, automatically update bazamId based on the area's metadata
            if (newState.areaId != prevState.areaId) {
                val area = newState.areas.find { it.areaId == newState.areaId }
                if (area != null) {
                    newState.copy(bazamId = area.bazamId)
                } else {
                    newState
                }
            } else {
                newState
            }
        }
    }

    fun load(salikId: String?) {
        if (salikId.isNullOrEmpty()) return
        if (_form.value.salikId == salikId && _form.value.name.isNotEmpty()) return
        viewModelScope.launch {
            _form.update { it.copy(isLoadingRecord = true, salikId = salikId) }
            
            // Try to sync this specific ID from server before editing to ensure latest data
            syncService.syncNow() 

            val salik = salikRepository.getById(salikId)
            if (salik != null) {
                _form.update {
                    it.copy(
                        salikId = salik.salikId,
                        name = salik.name,
                        fatherName = salik.fatherName,
                        mobileNumber = salik.mobileNumber,
                        whatsappNumber = salik.whatsappNumber,
                        genderId = salik.genderId,
                        bazamId = salik.bazamId,
                        areaId = salik.areaId,
                        address = salik.address,
                        isNafiAsbat = salik.isNafiAsbat,
                        isSahibEMehfil = salik.isSahibEMehfil,
                        referenceName = salik.referenceName,
                        dateOfBaith = salik.dateOfBaith.ifEmpty { LocalDate.now().toString() },
                        isLoadingRecord = false,
                    )
                }
            } else {
                _form.update { it.copy(isLoadingRecord = false) }
            }
        }
    }

    fun save() {
        viewModelScope.launch {
            val session = authRepository.session.value
            val state = _form.value
            
            AppLog.d("SalikFormVM", "Save clicked. Mode: ${if (state.salikId.isNullOrEmpty()) "CREATE" else "UPDATE (${state.salikId})"}")
            
            if (state.name.isBlank() || state.mobileNumber.isBlank()) {
                AppLog.w("SalikFormVM", "Validation failed: Name or Mobile empty")
                _form.update { it.copy(error = "Name and mobile are required") }
                return@launch
            }
            _form.update { it.copy(isSaving = true, error = null) }
            try {
                val gender = if (session != null) {
                    AccessControl.effectiveGender(session, state.genderId)
                } else {
                    state.genderId
                }
                val now = LocalDate.now().toString()
                val salik = Salik(
                    salikId = state.salikId.orEmpty(),
                    name = state.name.trim(),
                    fatherName = state.fatherName.trim(),
                    mobileNumber = state.mobileNumber.trim(),
                    whatsappNumber = state.whatsappNumber.trim().ifEmpty { state.mobileNumber.trim() },
                    areaId = state.areaId,
                    address = state.address.trim(),
                    genderId = gender,
                    bazamId = state.bazamId.ifEmpty { kDefaultBazamId },
                    dateOfBaith = state.dateOfBaith.ifEmpty { now },
                    referenceName = state.referenceName.trim(),
                    isNafiAsbat = state.isNafiAsbat,
                    isSahibEMehfil = state.isSahibEMehfil,
                    createdDate = now,
                    modifiedDate = now,
                )
                
                AppLog.d("SalikFormVM", "Executing repository action for ${salik.name}")
                val id: String
                if (state.salikId.isNullOrEmpty()) {
                    AppLog.i("SalikFormVM", "Performing CREATE action")
                    id = salikRepository.create(salik, session)
                } else {
                    AppLog.i("SalikFormVM", "Performing UPDATE action for ID: ${state.salikId}")
                    salikRepository.update(salik, session)
                    id = state.salikId
                }
                
                AppLog.i("SalikFormVM", "Save successful. Final ID: $id")
                
                // Trigger background sync immediately after successful local save
                viewModelScope.launch {
                    AppLog.d("SalikFormVM", "Triggering post-save sync")
                    syncService.syncNow()
                }

                _form.update { it.copy(isSaving = false, savedId = id) }
            } catch (e: DuplicateSalikException) {
                AppLog.w("SalikFormVM", "Save failed: Duplicate detected (${e.reason})")
                _form.update {
                    it.copy(isSaving = false, error = "Duplicate salik (${e.reason})")
                }
            } catch (e: Exception) {
                AppLog.e("SalikFormVM", "Save failed: ${e.message}", e)
                _form.update {
                    it.copy(isSaving = false, error = e.message ?: "Save failed")
                }
            }
        }
    }

    fun clearSaved() {
        _form.update { it.copy(savedId = null) }
    }
}
