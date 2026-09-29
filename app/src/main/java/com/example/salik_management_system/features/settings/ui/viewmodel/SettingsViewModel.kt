package com.example.salik_management_system.features.settings.ui.viewmodel

import android.content.Context
import android.content.Intent
import android.net.Uri
import com.example.salik_management_system.core.export.CsvShare
import com.example.salik_management_system.core.export.SalikCsvImport
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.features.saliks.domain.model.Salik
import com.example.salik_management_system.features.saliks.domain.model.DuplicateSalikException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.CancellationException
import java.time.LocalDate
import android.provider.Settings
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.config.AppConfig
import com.example.salik_management_system.core.export.SalikCsvExport
import com.example.salik_management_system.core.network.ConnectivityService
import com.example.salik_management_system.core.sync.SyncResult
import com.example.salik_management_system.core.sync.SyncService
import com.example.salik_management_system.features.saliks.data.repository.AreaRepository
import com.example.salik_management_system.features.saliks.data.repository.SalikRepository
import com.example.salik_management_system.ui.theme.ThemePreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val session: UserSession? = null,
    val darkMode: Boolean = false,
    val isOnline: Boolean = false,
    val pendingCount: Int = 0,
    val isSyncing: Boolean = false,
    val envLabel: String = AppConfig.envLabel,
    val message: String? = null,
    val contactPreview: List<String> = emptyList(),
    val importBusy: Boolean = false,
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val authRepository: AuthRepository,
    private val syncService: SyncService,
    private val salikRepository: SalikRepository,
    private val areaRepository: AreaRepository,
    private val themePreferences: ThemePreferences,
    private val connectivity: ConnectivityService,
) : ViewModel() {
    private val _importBusy = MutableStateFlow(false)
    private var pendingImport = emptyList<Salik>()
    private val _isSyncing = MutableStateFlow(false)
    private val _message = MutableStateFlow<String?>(null)
    private val _contactPreview = MutableStateFlow<List<String>>(emptyList())

    val uiState: StateFlow<SettingsUiState> = combine(
        authRepository.session,
        themePreferences.darkMode,
        connectivity.watchOnline(),
        syncService.pendingCount,
        _isSyncing,
    ) { session, dark, online, pending, syncing ->
        SettingsUiState(
            session = session,
            darkMode = dark,
            isOnline = online,
            pendingCount = pending,
            isSyncing = syncing,
            envLabel = AppConfig.envLabel,
            message = _message.value,
            contactPreview = _contactPreview.value,
        )
    }.combine(_message) { state, msg -> state.copy(message = msg) }
        .combine(_contactPreview) { state, contacts -> state.copy(contactPreview = contacts) }
        .combine(_importBusy) { state, busy -> state.copy(importBusy = busy) }
        .stateIn(
            viewModelScope,
            SharingStarted.WhileSubscribed(5_000),
            SettingsUiState(session = authRepository.session.value)
        )

    fun toggleDarkMode() {

        viewModelScope.launch { themePreferences.toggle() }
    }

    fun syncNow(onResult: ((SyncResult) -> Unit)? = null) {
        if (_isSyncing.value) return
        viewModelScope.launch {
            _isSyncing.value = true
            val result = syncService.syncNow(authRepository.session.value)
            _isSyncing.value = false
            _message.value = if (result.ok) "Sync complete" else "Sync failed. Please retry."
            onResult?.invoke(result)
        }
    }

    fun reportMessage(message: String) { _message.value = message }

    fun clearMessage() {
        _message.value = null
    }

    fun logout() {
        viewModelScope.launch { authRepository.signOut() }
    }


    fun exportCsv(onReady: (Intent) -> Unit) {
        viewModelScope.launch {
            try {
                val session = authRepository.session.value ?: error("Sign in first")
                val saliks = salikRepository.watchDirectory(session).first()
                val areas = areaRepository.watchAreas().first().associateBy { it.areaId }
                val intent = withContext(Dispatchers.IO) {
                    CsvShare.intent(context, SalikCsvExport.build(saliks, areas))
                }
                onReady(intent)
            } catch (e: CancellationException) { throw e
            } catch (e: Exception) { _message.value = "Export failed" }
        }
    }

    fun cancelImport() {
        if (_importBusy.value) return
        pendingImport = emptyList()
        _contactPreview.value = emptyList()
    }

    fun previewCsv(uri: Uri) {
        if (_importBusy.value) return
        _importBusy.value = true
        viewModelScope.launch {
            try {
                pendingImport = emptyList()
                _contactPreview.value = emptyList()
                val session = authRepository.session.value ?: error("Sign in first")
                require(AccessControl.canCreate(session.role)) { "Import not allowed for this role" }
                val text = withContext(Dispatchers.IO) {
                    context.contentResolver.openInputStream(uri)?.bufferedReader()?.use { reader ->
                        val buffer = CharArray(2_000_001)
                        var count = 0
                        while (count < buffer.size) {
                            val n = reader.read(buffer, count, buffer.size - count)
                            if (n < 0) break
                            count += n
                        }
                        require(count <= 2_000_000) { "CSV too large (maximum 2 MB text)" }
                        String(buffer, 0, count)
                    } ?: error("Cannot open CSV")
                }
                val rows = withContext(Dispatchers.Default) { SalikCsvImport.parse(text) }
                require(rows.isNotEmpty() && rows.size <= 5000) { "Choose 1–5000 records" }
                val areas = areaRepository.watchAreas().first()
                val now = LocalDate.now().toString()
                pendingImport = rows.mapIndexed { index, row ->
                    val prefix = "Row ${index + 2}: "
                    require(!row["name"].isNullOrBlank()) { prefix + "name required" }
                    val phone = row["mobileNumber"].orEmpty()
                    require(phone.count { it.isDigit() } in 7..15) { prefix + "invalid phone" }
                    val gender = row["genderId"].orEmpty()
                    require(gender.equals("Male", true) || gender.equals("Female", true)) { prefix + "invalid gender" }
                    require(AccessControl.canSetGender(session) || gender.equals(session.gender, true)) {
                        prefix + "gender outside your access"
                    }
                    val areaId = row["areaId"].orEmpty()
                    val matches = areas.filter {
                        if (areaId.isNotBlank()) it.areaId == areaId
                        else it.areaName.equals(row["area"].orEmpty(), true)
                    }
                    require(matches.size == 1) { prefix + "area missing or ambiguous; sync reference data first" }
                    val area = matches.single()
                    listOf("isActive", "isNafiAsbat", "isSahibEMehfil").forEach { key ->
                        require(row[key].isNullOrBlank() || row[key].equals("true", true) || row[key].equals("false", true)) {
                            prefix + "invalid " + key
                        }
                    }
                    row["dateOfBaith"]?.takeIf { it.isNotBlank() }?.let { LocalDate.parse(it) }
                    Salik.fromMap(row + mapOf(
                        "salikId" to "", "areaId" to area.areaId, "bazamId" to area.bazamId,
                        "genderId" to AccessControl.effectiveGender(session, gender),
                        "createdDate" to now, "modifiedDate" to now,
                        "isActive" to (row["isActive"] ?: "true"),
                    ))
                }
                _contactPreview.value = listOf("${pendingImport.size} records ready. Duplicates will be skipped.")
            } catch (e: CancellationException) { throw e
            } catch (e: Exception) {
                pendingImport = emptyList()
                _message.value = e.message ?: "Cannot read CSV"
            } finally { _importBusy.value = false }
        }
    }

    fun confirmImport() {
        if (_importBusy.value || pendingImport.isEmpty()) return
        _importBusy.value = true
        val records = pendingImport
        viewModelScope.launch {
            var imported = 0
            var duplicates = 0
            try {
                val session = authRepository.session.value ?: error("Sign in first")
                require(AccessControl.canCreate(session.role)) { "Import not allowed" }
                for (record in records) {
                    require(authRepository.session.value?.uid == session.uid) { "Session changed" }
                    require(AccessControl.canSetGender(session) || record.genderId.equals(session.gender, true)) { "Gender not allowed" }
                    try {
                        salikRepository.create(record, session)
                        imported++
                    } catch (_: DuplicateSalikException) { duplicates++ }
                }
                _message.value = "Imported $imported; skipped $duplicates duplicates. Press Sync to upload."
            } catch (e: CancellationException) { throw e
            } catch (e: Exception) {
                _message.value = "Stopped after $imported imports: ${e.message ?: "import failed"}"
            } finally {
                pendingImport = emptyList()
                _contactPreview.value = emptyList()
                _importBusy.value = false
            }
        }
    }
}
