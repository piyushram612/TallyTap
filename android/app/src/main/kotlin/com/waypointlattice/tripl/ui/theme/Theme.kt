package com.waypointlattice.tripl.ui.theme

import android.app.Activity
import android.content.Context
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

data class TriplNativeColors(
    val bgBase: Color,
    val cardBg: Color,
    val cardBorder: Color,
    val textPrimary: Color,
    val textMuted: Color,
    val primaryAccent: Color,
    val isLight: Boolean
)

val DefaultTriplColors = TriplNativeColors(
    bgBase = Color(0xFF08100E),
    cardBg = Color(0xFF0D1612),
    cardBorder = Color(0xFF1D2F28),
    textPrimary = Color(0xFFF3F4F6),
    textMuted = Color(0xFF9CA3AF),
    primaryAccent = Color(0xFF4EDEA3),
    isLight = false
)

val LocalTriplColors = staticCompositionLocalOf { DefaultTriplColors }

fun loadThemeFromPrefs(context: Context): TriplNativeColors {
    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    return try {
        val primaryAccent = prefs.getLong("flutter.tripl_theme_accent_color", 0xFF4EDEA3L).toInt()
        val bgBase = prefs.getLong("flutter.tripl_theme_bg_base", 0xFF08100EL).toInt()
        val cardBg = prefs.getLong("flutter.tripl_theme_card_bg", 0xFF0D1612L).toInt()
        val cardBorder = prefs.getLong("flutter.tripl_theme_card_border", 0xFF1D2F28L).toInt()
        val textPrimary = prefs.getLong("flutter.tripl_theme_text_primary", 0xFFF3F4F6L).toInt()
        val textMuted = prefs.getLong("flutter.tripl_theme_text_muted", 0xFF9CA3AFL).toInt()
        val isLight = prefs.getBoolean("flutter.tripl_theme_is_light", false)

        TriplNativeColors(
            bgBase = Color(bgBase),
            cardBg = Color(cardBg),
            cardBorder = Color(cardBorder),
            textPrimary = Color(textPrimary),
            textMuted = Color(textMuted),
            primaryAccent = Color(primaryAccent),
            isLight = isLight
        )
    } catch (e: Exception) {
        DefaultTriplColors
    }
}

@Composable
fun TriplTheme(
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    val triplColors = remember(context) { loadThemeFromPrefs(context) }
    
    val colorScheme = if (triplColors.isLight) {
        lightColorScheme(
            primary = triplColors.primaryAccent,
            background = triplColors.bgBase,
            surface = triplColors.cardBg,
            onSurface = triplColors.textPrimary
        )
    } else {
        darkColorScheme(
            primary = triplColors.primaryAccent,
            background = triplColors.bgBase,
            surface = triplColors.cardBg,
            onSurface = triplColors.textPrimary
        )
    }
    
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = triplColors.isLight
            }
        }
    }

    CompositionLocalProvider(LocalTriplColors provides triplColors) {
        MaterialTheme(
            colorScheme = colorScheme,
            content = content
        )
    }
}

