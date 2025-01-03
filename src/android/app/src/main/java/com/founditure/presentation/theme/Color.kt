/*
 * Human Tasks:
 * 1. Verify that the color values meet WCAG 2.1 AA contrast requirements using a color contrast analyzer
 * 2. Test color schemes in both light and dark themes across different Android devices
 * 3. Validate color accessibility with Android's built-in accessibility scanner
 * 4. Review color harmony with design team for brand consistency
 */

package com.founditure.presentation.theme

// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.graphics.Color
// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme

// Light Theme Colors
// Requirement: Visual Hierarchy - Material Design 3 with dynamic color system
private val md_theme_light_primary = Color(0xFF6750A4)
private val md_theme_light_onPrimary = Color(0xFFFFFFFF)
private val md_theme_light_primaryContainer = Color(0xFFEADDFF)
private val md_theme_light_onPrimaryContainer = Color(0xFF21005E)
private val md_theme_light_secondary = Color(0xFF625B71)
private val md_theme_light_onSecondary = Color(0xFFFFFFFF)
private val md_theme_light_secondaryContainer = Color(0xFFE8DEF8)
private val md_theme_light_onSecondaryContainer = Color(0xFF1E192B)
private val md_theme_light_tertiary = Color(0xFF7D5260)
private val md_theme_light_onTertiary = Color(0xFFFFFFFF)
private val md_theme_light_tertiaryContainer = Color(0xFFFFD8E4)
private val md_theme_light_onTertiaryContainer = Color(0xFF31111D)
private val md_theme_light_error = Color(0xFFB3261E)
private val md_theme_light_onError = Color(0xFFFFFFFF)
private val md_theme_light_errorContainer = Color(0xFFF9DEDC)
private val md_theme_light_onErrorContainer = Color(0xFF410E0B)
private val md_theme_light_background = Color(0xFFFFFBFE)
private val md_theme_light_onBackground = Color(0xFF1C1B1F)
private val md_theme_light_surface = Color(0xFFFFFBFE)
private val md_theme_light_onSurface = Color(0xFF1C1B1F)
private val md_theme_light_surfaceVariant = Color(0xFFE7E0EC)
private val md_theme_light_onSurfaceVariant = Color(0xFF49454F)
private val md_theme_light_outline = Color(0xFF79747E)

// Dark Theme Colors
// Requirement: Theme Support - Dark mode color scheme with WCAG compliance
private val md_theme_dark_primary = Color(0xFFD0BCFF)
private val md_theme_dark_onPrimary = Color(0xFF381E72)
private val md_theme_dark_primaryContainer = Color(0xFF4F378B)
private val md_theme_dark_onPrimaryContainer = Color(0xFFEADDFF)
private val md_theme_dark_secondary = Color(0xFFCCC2DC)
private val md_theme_dark_onSecondary = Color(0xFF332D41)
private val md_theme_dark_secondaryContainer = Color(0xFF4A4458)
private val md_theme_dark_onSecondaryContainer = Color(0xFFE8DEF8)
private val md_theme_dark_tertiary = Color(0xFFEFB8C8)
private val md_theme_dark_onTertiary = Color(0xFF492532)
private val md_theme_dark_tertiaryContainer = Color(0xFF633B48)
private val md_theme_dark_onTertiaryContainer = Color(0xFFFFD8E4)
private val md_theme_dark_error = Color(0xFFF2B8B5)
private val md_theme_dark_onError = Color(0xFF601410)
private val md_theme_dark_errorContainer = Color(0xFF8C1D18)
private val md_theme_dark_onErrorContainer = Color(0xFFF9DEDC)
private val md_theme_dark_background = Color(0xFF1C1B1F)
private val md_theme_dark_onBackground = Color(0xFFE6E1E5)
private val md_theme_dark_surface = Color(0xFF1C1B1F)
private val md_theme_dark_onSurface = Color(0xFFE6E1E5)
private val md_theme_dark_surfaceVariant = Color(0xFF49454F)
private val md_theme_dark_onSurfaceVariant = Color(0xFFCAC4D0)
private val md_theme_dark_outline = Color(0xFF938F99)

/**
 * Creates a Material3 light theme color scheme for the application with WCAG 2.1 AA compliant contrast ratios
 * Requirement: Accessibility - WCAG 2.1 AA compliance with minimum contrast ratio of 4.5:1
 */
val lightColorScheme: ColorScheme = lightColorScheme(
    primary = md_theme_light_primary,
    onPrimary = md_theme_light_onPrimary,
    primaryContainer = md_theme_light_primaryContainer,
    onPrimaryContainer = md_theme_light_onPrimaryContainer,
    secondary = md_theme_light_secondary,
    onSecondary = md_theme_light_onSecondary,
    secondaryContainer = md_theme_light_secondaryContainer,
    onSecondaryContainer = md_theme_light_onSecondaryContainer,
    tertiary = md_theme_light_tertiary,
    onTertiary = md_theme_light_onTertiary,
    tertiaryContainer = md_theme_light_tertiaryContainer,
    onTertiaryContainer = md_theme_light_onTertiaryContainer,
    error = md_theme_light_error,
    onError = md_theme_light_onError,
    errorContainer = md_theme_light_errorContainer,
    onErrorContainer = md_theme_light_onErrorContainer,
    background = md_theme_light_background,
    onBackground = md_theme_light_onBackground,
    surface = md_theme_light_surface,
    onSurface = md_theme_light_onSurface,
    surfaceVariant = md_theme_light_surfaceVariant,
    onSurfaceVariant = md_theme_light_onSurfaceVariant,
    outline = md_theme_light_outline
)

/**
 * Creates a Material3 dark theme color scheme for the application with WCAG 2.1 AA compliant contrast ratios
 * Requirement: Theme Support - Dark mode support with custom color schemes
 */
val darkColorScheme: ColorScheme = darkColorScheme(
    primary = md_theme_dark_primary,
    onPrimary = md_theme_dark_onPrimary,
    primaryContainer = md_theme_dark_primaryContainer,
    onPrimaryContainer = md_theme_dark_onPrimaryContainer,
    secondary = md_theme_dark_secondary,
    onSecondary = md_theme_dark_onSecondary,
    secondaryContainer = md_theme_dark_secondaryContainer,
    onSecondaryContainer = md_theme_dark_onSecondaryContainer,
    tertiary = md_theme_dark_tertiary,
    onTertiary = md_theme_dark_onTertiary,
    tertiaryContainer = md_theme_dark_tertiaryContainer,
    onTertiaryContainer = md_theme_dark_onTertiaryContainer,
    error = md_theme_dark_error,
    onError = md_theme_dark_onError,
    errorContainer = md_theme_dark_errorContainer,
    onErrorContainer = md_theme_dark_onErrorContainer,
    background = md_theme_dark_background,
    onBackground = md_theme_dark_onBackground,
    surface = md_theme_dark_surface,
    onSurface = md_theme_dark_onSurface,
    surfaceVariant = md_theme_dark_surfaceVariant,
    onSurfaceVariant = md_theme_dark_onSurfaceVariant,
    outline = md_theme_dark_outline
)