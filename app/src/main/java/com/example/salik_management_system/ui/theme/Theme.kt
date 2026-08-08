package com.example.salik_management_system.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val PrimaryGreen = Color(0xFF003527)
val PrimaryGreenLight = Color(0xFF095C44)
val AccentGold = Color(0xFFFED65B)
val ScaffoldLightBg = Color(0xFFF4F7F6)
val DarkSurface = Color(0xFF121816)
val DarkScaffold = Color(0xFF0E1210)
val DarkPrimary = Color(0xFF95D3BA)

private val LightColorScheme = lightColorScheme(
    primary = PrimaryGreen,
    onPrimary = Color.White,
    secondary = AccentGold,
    onSecondary = PrimaryGreen,
    tertiary = PrimaryGreenLight,
    background = ScaffoldLightBg,
    surface = Color.White,
    onBackground = Color(0xFF1A1C1B),
    onSurface = Color(0xFF1A1C1B),
)

private val DarkColorScheme = darkColorScheme(
    primary = DarkPrimary,
    onPrimary = PrimaryGreen,
    secondary = AccentGold,
    onSecondary = PrimaryGreen,
    tertiary = PrimaryGreenLight,
    background = DarkScaffold,
    surface = DarkSurface,
    onBackground = Color(0xFFE2E3E1),
    onSurface = Color(0xFFE2E3E1),
)

@Composable
fun SalikTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    MaterialTheme(
        colorScheme = colorScheme,
        content = content,
    )
}
