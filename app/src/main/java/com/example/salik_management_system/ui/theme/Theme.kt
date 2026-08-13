package com.example.salik_management_system.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.LocalTonalElevationEnabled
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/** Brand — deep forest + restrained gold accent (enterprise CMS). */
val PrimaryGreen = Color(0xFF003527)
val PrimaryGreenLight = Color(0xFF0A5C44)
val AccentGold = Color(0xFFE8C547)
val AccentGoldMuted = Color(0xFFC9A227)

private val LightColorScheme = lightColorScheme(
    primary = PrimaryGreen,
    onPrimary = Color.White,
    primaryContainer = Brand.GreenContainer,
    onPrimaryContainer = Brand.OnGreenContainer,
    secondary = AccentGoldMuted,
    onSecondary = Color(0xFF1A1500),
    secondaryContainer = Color(0xFFFFF0C2),
    onSecondaryContainer = Color(0xFF241A00),
    tertiary = PrimaryGreenLight,
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFC5E8D8),
    onTertiaryContainer = Brand.OnGreenContainer,
    background = Brand.BgLight,
    onBackground = Brand.OnSurface,
    surface = Brand.Surface,
    onSurface = Brand.OnSurface,
    surfaceVariant = Color(0xFFE8EEEC),
    onSurfaceVariant = Brand.OnSurfaceVariant,
    surfaceTint = Color.Transparent,
    surfaceBright = Brand.Surface,
    surfaceDim = Color(0xFFDCE5E1),
    surfaceContainerLowest = Brand.Surface,
    surfaceContainerLow = Color(0xFFE8EEEC),
    surfaceContainer = Color(0xFFE2EAE6),
    surfaceContainerHigh = Color(0xFFDCE5E1),
    surfaceContainerHighest = Color(0xFFD0DBD5),
    outline = Color(0xFF6F7B75),
    outlineVariant = Brand.OutlineVariant,
    error = Color(0xFFBA1A1A),
    onError = Color.White,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002),
    inverseSurface = Color(0xFF2D322F),
    inverseOnSurface = Color(0xFFEFF1EE),
    inversePrimary = Brand.GreenDark,
    scrim = Color(0x99000000),
)

private val DarkColorScheme = darkColorScheme(
    primary = Brand.GreenDark,
    onPrimary = Color(0xFF003827),
    primaryContainer = Brand.GreenContainerDark,
    onPrimaryContainer = Brand.OnGreenContainerDark,
    secondary = AccentGold,
    onSecondary = Color(0xFF3A2F00),
    secondaryContainer = Color(0xFF554600),
    onSecondaryContainer = Color(0xFFFFE08A),
    tertiary = Color(0xFF6DB89A),
    onTertiary = Color(0xFF003827),
    tertiaryContainer = Brand.GreenContainerDark,
    onTertiaryContainer = Brand.OnGreenContainerDark,
    background = Brand.BgDark,
    onBackground = Color(0xFFE2E8E4),
    surface = Brand.SurfaceDark,
    onSurface = Color(0xFFE2E8E4),
    surfaceVariant = Color(0xFF1A221E),
    onSurfaceVariant = Color(0xFFA8B5AE),
    surfaceTint = Color.Transparent,
    surfaceBright = Color(0xFF2E3A34),
    surfaceDim = Brand.BgDark,
    surfaceContainerLowest = Color(0xFF080C0A),
    surfaceContainerLow = Color(0xFF1A221E),
    surfaceContainer = Color(0xFF1E2622),
    surfaceContainerHigh = Color(0xFF243029),
    surfaceContainerHighest = Color(0xFF2E3A34),
    outline = Color(0xFF88948E),
    outlineVariant = Color(0xFF3A4540),
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6),
    inverseSurface = Color(0xFFE2E8E4),
    inverseOnSurface = Color(0xFF2D322F),
    inversePrimary = PrimaryGreen,
    scrim = Color(0x99000000),
)

@Composable
fun SalikTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    val view = LocalView.current

    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window ?: return@SideEffect
            val insets = WindowCompat.getInsetsController(window, view)
            insets.isAppearanceLightStatusBars = !darkTheme
            insets.isAppearanceLightNavigationBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = SalikTypography,
        shapes = SalikShapes,
    ) {
        // Inside MaterialTheme so tonal overlay cannot re-enable purple wash.
        CompositionLocalProvider(LocalTonalElevationEnabled provides false) {
            content()
        }
    }
}
