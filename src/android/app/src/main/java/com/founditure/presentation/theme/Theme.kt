/*
 * Human Tasks:
 * 1. Test dynamic color behavior on Android 12+ devices
 * 2. Verify theme transitions between light and dark modes
 * 3. Test theme application across all app screens and components
 * 4. Validate system bar colors match design specifications
 */

package com.founditure.presentation.theme

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme

// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect

// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.isSystemInDarkTheme

// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView

// com.google.accompanist:accompanist-systemuicontroller:0.30.1
import com.google.accompanist.systemuicontroller.rememberSystemUiController

/**
 * Main theme composable for the Founditure application that implements Material Design 3
 * with support for dynamic colors and dark/light themes.
 *
 * Requirements addressed:
 * - Visual Hierarchy (3.1.1): Material Design 3 with dynamic color system
 * - Theme Support (3.1.1): Light/dark mode and auto theme switching
 * - Component Library (3.1.1): Custom Design System with atomic design principles
 *
 * @param darkTheme Boolean indicating whether to use dark theme
 * @param dynamicColor Boolean indicating whether to use dynamic colors (Android 12+)
 * @param content Composable content to be themed
 */
@Composable
fun FounditureTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    // Determine if dynamic color is supported (Android 12+)
    val context = LocalContext.current
    val view = LocalView.current
    
    // Select color scheme based on dark theme and dynamic color support
    val colorScheme = when {
        dynamicColor && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S -> {
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> darkColorScheme
        else -> lightColorScheme
    }

    // Configure system bars color and appearance
    val systemUiController = rememberSystemUiController()
    SideEffect {
        if (view.isInEditMode) {
            return@SideEffect
        }
        
        // Set status bar colors
        systemUiController.setStatusBarColor(
            color = Color.Transparent,
            darkIcons = !darkTheme
        )
        
        // Set navigation bar colors
        systemUiController.setNavigationBarColor(
            color = colorScheme.surface,
            darkIcons = !darkTheme,
            navigationBarContrastEnforced = false
        )
    }

    // Apply Material Design 3 theme
    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = FounditureShapes,
        content = content
    )
}