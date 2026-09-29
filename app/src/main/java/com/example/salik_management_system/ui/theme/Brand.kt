@file:OptIn(ExperimentalMaterial3Api::class)

package com.example.salik_management_system.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/** Hard brand tokens — use when Material defaults leak purple. */
object Brand {
    val Green = PrimaryGreen
    val GreenLight = PrimaryGreenLight
    val GreenContainer = Color(0xFFDCEFFF)
    val OnGreenContainer = Color(0xFF103B55)
    val Gold = AccentGold
    val GoldMuted = AccentGoldMuted
    val BgLight = Color.White
    val Surface = Color.White
    val OnSurface = Color(0xFF1A1C1E)
    val OnSurfaceVariant = Color(0xFF486174)
    val OutlineVariant = Color(0xFFB6CFDF)

    val BgDark = Color(0xFF0C1720)
    val SurfaceDark = Color(0xFF142430)
    val GreenDark = Color(0xFF94CFF5)
    val GreenContainerDark = Color(0xFF164B6B)
    val OnGreenContainerDark = Color(0xFFD1EBFF)
}

@Composable
fun brandNavItemColors() = NavigationBarItemDefaults.colors(
    selectedIconColor = MaterialTheme.colorScheme.primary,
    selectedTextColor = MaterialTheme.colorScheme.primary,
    indicatorColor = MaterialTheme.colorScheme.primaryContainer,
    unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
    unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
)

@Composable
fun brandTopAppBarColors() = TopAppBarDefaults.topAppBarColors(
    containerColor = MaterialTheme.colorScheme.primaryContainer,
    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
    navigationIconContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
    actionIconContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
    scrolledContainerColor = MaterialTheme.colorScheme.primaryContainer,
)

@Composable
fun brandSwitchColors() = SwitchDefaults.colors(
    checkedThumbColor = Color.White,
    checkedTrackColor = Brand.Green,
    checkedBorderColor = Brand.Green,
    uncheckedThumbColor = Color.White,
    uncheckedTrackColor = MaterialTheme.colorScheme.outlineVariant,
    uncheckedBorderColor = MaterialTheme.colorScheme.outlineVariant,
)

@Composable
fun brandFilterChipColors() = FilterChipDefaults.filterChipColors(
    containerColor = MaterialTheme.colorScheme.surface,
    labelColor = MaterialTheme.colorScheme.onSurfaceVariant,
    iconColor = MaterialTheme.colorScheme.onSurfaceVariant,
    selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
    selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer,
    selectedLeadingIconColor = MaterialTheme.colorScheme.onPrimaryContainer,
    selectedTrailingIconColor = MaterialTheme.colorScheme.onPrimaryContainer,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun brandFilterChipBorder(selected: Boolean) = FilterChipDefaults.filterChipBorder(
    enabled = true,
    selected = selected,
    borderColor = MaterialTheme.colorScheme.outlineVariant,
    selectedBorderColor = Brand.Green,
)
