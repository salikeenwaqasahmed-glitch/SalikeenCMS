package com.example.salik_management_system.ui.theme

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

private val Context.themeDataStore: DataStore<Preferences> by preferencesDataStore("salik_theme")

@Singleton
class ThemePreferences @Inject constructor(
    @ApplicationContext context: Context,
) {
    private val store = context.themeDataStore
    private val darkKey = booleanPreferencesKey("dark_mode")

    val darkMode = store.data.map { prefs -> prefs[darkKey] ?: false }

    suspend fun setDarkMode(enabled: Boolean) {
        store.edit { it[darkKey] = enabled }
    }

    suspend fun toggle() {
        store.edit { prefs ->
            prefs[darkKey] = !(prefs[darkKey] ?: false)
        }
    }
}

@HiltViewModel
class ThemeViewModel @Inject constructor(
    private val themePreferences: ThemePreferences,
) : ViewModel() {
    val darkTheme: StateFlow<Boolean> = themePreferences.darkMode
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    fun setDarkMode(enabled: Boolean) {
        viewModelScope.launch { themePreferences.setDarkMode(enabled) }
    }

    fun toggleDarkMode() {
        viewModelScope.launch { themePreferences.toggle() }
    }
}
