/*
 * Human Tasks:
 * 1. Test loading indicator performance on low-end Android devices
 * 2. Verify animation smoothness across different Android versions
 * 3. Validate accessibility features with TalkBack enabled
 * 4. Review loading indicator contrast ratios in both light and dark themes
 */

package com.founditure.presentation.components

// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.Composable
// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
// Internal imports
import com.founditure.presentation.theme.lightColorScheme

/**
 * A reusable loading indicator component that provides visual feedback during asynchronous operations.
 * 
 * Requirement: Component Library - Custom Design System with atomic design principles
 * This component follows Material Design 3 specifications and supports customization of size and color.
 * 
 * Requirement: Visual Hierarchy - Material Design 3 with dynamic color system
 * Uses Material Theme's primary color by default with support for custom colors.
 *
 * @param size The diameter of the circular progress indicator in Dp. Defaults to 48.dp
 * @param color Optional custom color for the progress indicator. If not provided, uses the theme's primary color
 */
@Composable
fun LoadingIndicator(
    size: Dp = 48.dp,
    color: Color? = null
) {
    // Create a full-size container with centered content
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        // Use CircularProgressIndicator with specified size and color
        CircularProgressIndicator(
            modifier = Modifier,
            color = color ?: MaterialTheme.colorScheme.primary,
            strokeWidth = (size * 0.1f).coerceAtLeast(2.dp), // Maintain proportional stroke width with minimum of 2.dp
            trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.2f),
            progress = 0f // Indeterminate progress indicator
        )
    }
}