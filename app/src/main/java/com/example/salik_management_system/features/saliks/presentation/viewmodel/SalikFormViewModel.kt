package com.example.salik_management_system.features.saliks.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.data.resolveSalikBazamId
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.features.saliks.data.AreaRepository
import com.example.salik_management_system.features.saliks.data.SalikRepository
import com.example.salik_management_system.features.saliks.domain.Area
import com.example.salik_management_system.features.saliks.domain.DuplicateSalikException
import com.example.salik_management_system.features.saliks.domain.Salik
import com.example.salik_management_system.features.saliks.domain.kDefaultBazamId
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
    val areaId: String = "",
    val address: String = "",
    val isNafiAsbat: Boolean = false,
    val isSahibEMehfil: Boolean = false,
    val referenceName: String = "",
    val dateOfBaith: String = LocalDate.now().toString(),
    val areas: List<Area> = emptyList(),
    val canSetGender: Boolean = true,
    val isSaving: Boolean = false,
    val error: String? = null,
    val savedId: String? = null,
)

@HiltViewModel
class SalikFormViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val salikRepository: SalikRepository,
    private val areaRepository: AreaRepository,
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
        _form.update(block)
    }

    fun load(salikId: String?) {
        if (salikId.isNullOrEmpty()) return
        if (_form.value.salikId == salikId && _form.value.name.isNotEmpty()) return
        viewModelScope.launch {
            val salik = salikRepository.getById(salikId) ?: return@launch
            _form.update {
                it.copy(
                    salikId = salik.salikId,
                    name = salik.name,
                    fatherName = salik.fatherName,
                    mobileNumber = salik.mobileNumber,
                    whatsappNumber = salik.whatsappNumber,
                    genderId = salik.genderId,
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

    fun save() {
        viewModelScope.launch {
            val session = authRepository.session.value
            val state = _form.value
            if (state.name.isBlank() || state.mobileNumber.isBlank()) {
                _form.update { it.copy(error = "Name and mobile are required") }
                return@launch
            }
            _form.update { it.copy(isSaving = true, error = null) }
            try {
                val areas = state.areas
                val gender = if (session != null) {
                    AccessControl.effectiveGender(session, state.genderId)
                } else {
                    state.genderId
                }
                val bazamId = resolveSalikBazamId("", state.areaId, areas)
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
                    bazamId = bazamId.ifEmpty { kDefaultBazamId },
                    dateOfBaith = state.dateOfBaith.ifEmpty { now },
                    referenceName = state.referenceName.trim(),
                    isNafiAsbat = state.isNafiAsbat,
                    isSahibEMehfil = state.isSahibEMehfil,
                    createdDate = now,
                    modifiedDate = now,
                )
                val id = if (state.salikId.isNullOrEmpty()) {
                    salikRepository.create(salik, session)
                } else {
                    salikRepository.update(salik, session)
                    state.salikId
                }
                _form.update { it.copy(isSaving = false, savedId = id) }
            } catch (e: DuplicateSalikException) {
                _form.update {
                    it.copy(isSaving = false, error = "Duplicate salik (${e.reason})")
                }
            } catch (e: Exception) {
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
