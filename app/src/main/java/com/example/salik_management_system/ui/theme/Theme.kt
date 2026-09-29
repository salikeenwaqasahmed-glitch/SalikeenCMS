package com.example.salik_management_system.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.LocalTonalElevationEnabled
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/** Blue and white palette. Legacy token names retained for existing callers. */
val PrimaryGreen = Color(0xFF17689C)
val PrimaryGreenLight = Color(0xFF287EAE)
val AccentGold = Color(0xFFD7EEFF)
val AccentGoldMuted = Color(0xFFA9D8F5)

private val LightColorScheme = lightColorScheme(
    primary = PrimaryGreen,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFDCEFFF),
    onPrimaryContainer = PrimaryGreen,
    secondary = AccentGold,
    onSecondary = Color.Black,
    secondaryContainer = Color(0xFFE4F3FF),
    onSecondaryContainer = Color(0xFF173E58),
    tertiary = PrimaryGreenLight,
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFD4ECFA),
    onTertiaryContainer = Color(0xFF103B55),
    background = Color(0xFFF2F8FD),
    onBackground = Color(0xFF1A1C1E),
    surface = Color.White,
    onSurface = Color(0xFF1A1C1E),
    surfaceVariant = Color(0xFFE5F0F8),
    onSurfaceVariant = Color(0xFF486174),
    surfaceTint = Color.Transparent,
    surfaceBright = Color.White,
    surfaceDim = Color(0xFFD4E4EF),
    surfaceContainerLowest = Color.White,
    surfaceContainerLow = Color(0xFFF1F8FD),
    surfaceContainer = Color(0xFFEAF4FB),
    surfaceContainerHigh = Color(0xFFDEEDF7),
    surfaceContainerHighest = Color(0xFFD1E5F3),
    outline = Color(0xFF637E91),
    outlineVariant = Color(0xFFB6CFDF),
    error = Color(0xFFBA1A1A),
    onError = Color.White,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002),
    inverseSurface = Color(0xFF2F3033),
    inverseOnSurface = Color(0xFFE5F0F8),
    inversePrimary = Color(0xFF94CFF5),
    scrim = Color(0x99000000),
)

private val DarkColorScheme = darkColorScheme(
    primary = Brand.GreenDark,
    onPrimary = Color(0xFF00344F),
    primaryContainer = Brand.GreenContainerDark,
    onPrimaryContainer = Brand.OnGreenContainerDark,
    secondary = AccentGold,
    onSecondary = Color(0xFF12384E),
    secondaryContainer = Color(0xFF294D65),
    onSecondaryContainer = Color(0xFFCCE8FA),
    tertiary = Color(0xFF9BD6F5),
    onTertiary = Color(0xFF00344F),
    tertiaryContainer = Brand.GreenContainerDark,
    onTertiaryContainer = Brand.OnGreenContainerDark,
    background = Brand.BgDark,
    onBackground = Color(0xFFE2EFF8),
    surface = Brand.SurfaceDark,
    onSurface = Color(0xFFE2EFF8),
    surfaceVariant = Color(0xFF172A38),
    onSurfaceVariant = Color(0xFFABC2D3),
    surfaceTint = Color.Transparent,
    surfaceBright = Color(0xFF304858),
    surfaceDim = Brand.BgDark,
    surfaceContainerLowest = Color(0xFF080F16),
    surfaceContainerLow = Color(0xFF172A38),
    surfaceContainer = Color(0xFF1C303F),
    surfaceContainerHigh = Color(0xFF253C4C),
    surfaceContainerHighest = Color(0xFF304858),
    outline = Color(0xFF809CAE),
    outlineVariant = Color(0xFF3C5669),
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6),
    inverseSurface = Color(0xFFE2EFF8),
    inverseOnSurface = Color(0xFF213746),
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
        CompositionLocalProvider(LocalTonalElevationEnabled provides false) {
            content()
        }
    }
}

/** Forces light (white) status/navigation bar icons on dark backgrounds (e.g. Login). */
@Composable
fun LightSystemBarIcons() {
    val view = LocalView.current
    if (view.isInEditMode) return
    DisposableEffect(Unit) {
        val window = (view.context as Activity).window
        val controller = WindowCompat.getInsetsController(window, view)
        val previousStatus = controller.isAppearanceLightStatusBars
        val previousNav = controller.isAppearanceLightNavigationBars
        controller.isAppearanceLightStatusBars = false
        controller.isAppearanceLightNavigationBars = false
        onDispose {
            controller.isAppearanceLightStatusBars = previousStatus
            controller.isAppearanceLightNavigationBars = previousNav
        }
    }
}
