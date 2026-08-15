@file:OptIn(ExperimentalMaterial3Api::class)

package com.example.salik_management_system.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
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
    val GreenContainer = Color(0xFFC8E6C9)
    val OnGreenContainer = Color(0xFF002106)
    val Gold = AccentGold
    val GoldMuted = AccentGoldMuted
    val BgLight = Color.White
    val Surface = Color.White
    val OnSurface = Color(0xFF1A1C1E)
    val OnSurfaceVariant = Color(0xFF44474E)
    val OutlineVariant = Color(0xFFC4C6CF)

    val BgDark = Color(0xFF0B100E)
    val SurfaceDark = Color(0xFF141A17)
    val GreenDark = Color(0xFF8FCFB4)
    val GreenContainerDark = Color(0xFF005138)
    val OnGreenContainerDark = Color(0xFFA8E6CB)
}

@Composable
fun brandNavItemColors() = NavigationBarItemDefaults.colors(
    selectedIconColor = Brand.Gold,
    selectedTextColor = Brand.Gold,
    indicatorColor = Brand.Gold.copy(alpha = 0.15f),
    unselectedIconColor = if (isSystemInDarkTheme()) Color.White.copy(alpha = 0.7f) else Color.White,
    unselectedTextColor = if (isSystemInDarkTheme()) Color.White.copy(alpha = 0.7f) else Color.White,
)

@Composable
fun brandTopAppBarColors() = TopAppBarDefaults.topAppBarColors(
    containerColor = Brand.Green,
    titleContentColor = Color.White,
    navigationIconContentColor = Color.White,
    actionIconContentColor = Color.White,
    scrolledContainerColor = Brand.Green,
)

@Composable
fun brandSwitchColors() = SwitchDefaults.colors(
    checkedThumbColor = Color.White,
    checkedTrackColor = Brand.Green,
    checkedBorderColor = Brand.Green,
    uncheckedThumbColor = Color.White,
    uncheckedTrackColor = Brand.OutlineVariant,
    uncheckedBorderColor = Brand.OutlineVariant,
)

@Composable
fun brandFilterChipColors() = FilterChipDefaults.filterChipColors(
    containerColor = Brand.Surface,
    labelColor = Brand.OnSurfaceVariant,
    iconColor = Brand.OnSurfaceVariant,
    selectedContainerColor = Brand.GreenContainer,
    selectedLabelColor = Brand.OnGreenContainer,
    selectedLeadingIconColor = Brand.OnGreenContainer,
    selectedTrailingIconColor = Brand.OnGreenContainer,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun brandFilterChipBorder(selected: Boolean) = FilterChipDefaults.filterChipBorder(
    enabled = true,
    selected = selected,
    borderColor = Brand.OutlineVariant,
    selectedBorderColor = Brand.Green,
)
