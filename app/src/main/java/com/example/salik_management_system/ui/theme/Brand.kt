@file:OptIn(ExperimentalMaterial3Api::class)

package com.example.salik_management_system.ui.theme

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
    val GreenContainer = Color(0xFFB8E0CF)
    val OnGreenContainer = Color(0xFF002117)
    val Gold = AccentGold
    val GoldMuted = AccentGoldMuted
    val BgLight = Color(0xFFF0F4F2)
    val Surface = Color(0xFFFFFFFF)
    val OnSurface = Color(0xFF121C18)
    val OnSurfaceVariant = Color(0xFF3F4A45)
    val OutlineVariant = Color(0xFFBFC9C3)

    val BgDark = Color(0xFF0B100E)
    val SurfaceDark = Color(0xFF141A17)
    val GreenDark = Color(0xFF8FCFB4)
    val GreenContainerDark = Color(0xFF005138)
    val OnGreenContainerDark = Color(0xFFA8E6CB)
}

@Composable
fun brandNavItemColors() = NavigationBarItemDefaults.colors(
    selectedIconColor = Brand.Green,
    selectedTextColor = Brand.Green,
    indicatorColor = Brand.GreenContainer,
    unselectedIconColor = Brand.OnSurfaceVariant,
    unselectedTextColor = Brand.OnSurfaceVariant,
)

@Composable
fun brandTopAppBarColors() = TopAppBarDefaults.topAppBarColors(
    containerColor = Brand.BgLight,
    titleContentColor = Brand.OnSurface,
    navigationIconContentColor = Brand.OnSurface,
    actionIconContentColor = Brand.OnSurface,
    scrolledContainerColor = Brand.BgLight,
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
