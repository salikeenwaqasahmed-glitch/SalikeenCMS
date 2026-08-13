package com.example.salik_management_system.features.settings.ui.viewmodel

import android.content.Context
import android.content.Intent
import android.provider.ContactsContract
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
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsUiState())

    fun toggleDarkMode() {
        viewModelScope.launch { themePreferences.toggle() }
    }

    fun syncNow(onResult: ((SyncResult) -> Unit)? = null) {
        if (_isSyncing.value) return
        viewModelScope.launch {
            _isSyncing.value = true
            val result = syncService.syncNow(authRepository.session.value)
            _isSyncing.value = false
            _message.value = result.message
            onResult?.invoke(result)
        }
    }

    fun clearMessage() {
        _message.value = null
    }

    fun logout() {
        viewModelScope.launch { authRepository.signOut() }
    }

    fun exportCsvShareIntent(): Intent? {
        // Built synchronously from last known; prefer coroutine helper.
        return null
    }

    fun exportCsv(onReady: (Intent) -> Unit) {
        viewModelScope.launch {
            val session = authRepository.session.value
            val saliks = salikRepository.watchApproved(session).first()
            val areas = areaRepository.watchAreas().first().associateBy { it.areaId }
            val csv = SalikCsvExport.build(saliks, areas)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/csv"
                putExtra(Intent.EXTRA_SUBJECT, "Saliks export")
                putExtra(Intent.EXTRA_TEXT, csv)
            }
            onReady(Intent.createChooser(intent, "Export CSV"))
        }
    }

    /** Stub: opens app settings or runs a basic ContactsContract query. */
    fun importContactsStub(openSettingsFallback: Boolean = false) {
        viewModelScope.launch {
            if (openSettingsFallback) {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = android.net.Uri.fromParts("package", context.packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                runCatching { context.startActivity(intent) }
                return@launch
            }
            try {
                val names = mutableListOf<String>()
                context.contentResolver.query(
                    ContactsContract.Contacts.CONTENT_URI,
                    arrayOf(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY),
                    null,
                    null,
                    "${ContactsContract.Contacts.DISPLAY_NAME_PRIMARY} ASC LIMIT 10",
                )?.use { cursor ->
                    val idx = cursor.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY)
                    while (cursor.moveToNext() && names.size < 10) {
                        if (idx >= 0) names += cursor.getString(idx).orEmpty()
                    }
                }
                _contactPreview.value = names
                _message.value = if (names.isEmpty()) {
                    "No contacts found (grant permission in settings)"
                } else {
                    "Previewed ${names.size} contacts"
                }
            } catch (e: SecurityException) {
                _message.value = "Contacts permission needed"
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = android.net.Uri.fromParts("package", context.packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                runCatching { context.startActivity(intent) }
            } catch (e: Exception) {
                _message.value = e.message ?: "Import failed"
            }
        }
    }
}
