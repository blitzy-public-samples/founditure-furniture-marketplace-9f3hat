/*
 * Human Tasks:
 * 1. Test button touch targets with Android's accessibility scanner
 * 2. Verify color contrast ratios meet WCAG 2.1 AA standards (4.5:1)
 * 3. Test button states (enabled, disabled, loading) across different devices
 * 4. Validate button behavior with screen readers and TalkBack
 */

package com.founditure.presentation.components

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.CircularProgressIndicator

// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.Composable

// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width

// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.material3.Text

// Internal theme imports
import com.founditure.presentation.theme.FounditureTheme

/**
 * A customizable Material3 button component that maintains consistent styling across the app
 * with WCAG 2.1 AA compliant touch targets and color contrast.
 *
 * Requirements addressed:
 * - Component Library (3.1.1): Custom Design System with atomic design principles
 * - Accessibility (3.1.1): Touch targets 44x44pt with WCAG 2.1 AA compliance
 * - Visual Hierarchy (3.1.1): Material Design 3 with dynamic color system
 *
 * @param text The button text to display
 * @param onClick Callback to be invoked when the button is clicked
 * @param enabled Whether the button is enabled
 * @param loading Whether to show a loading indicator
 */
@Composable
fun FounditureButton(
    text: String,
    onClick: () -> Unit,
    enabled: Boolean = true,
    loading: Boolean = false
) {
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        modifier = Modifier
            .height(44.dp) // WCAG 2.1 AA compliant touch target
            .width(200.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = FounditureTheme.colors.primary,
            contentColor = FounditureTheme.colors.onPrimary,
            disabledContainerColor = FounditureTheme.colors.primary.copy(alpha = 0.38f),
            disabledContentColor = FounditureTheme.colors.onPrimary.copy(alpha = 0.38f)
        ),
        shape = FounditureTheme.shapes.small
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        ) {
            if (loading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    color = FounditureTheme.colors.onPrimary,
                    strokeWidth = 2.dp
                )
            } else {
                Text(
                    text = text,
                    style = FounditureTheme.typography.labelLarge,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

/**
 * An outlined variant of the Founditure button component with WCAG 2.1 AA compliant styling.
 *
 * Requirements addressed:
 * - Component Library (3.1.1): Custom Design System with atomic design principles
 * - Accessibility (3.1.1): Touch targets 44x44pt with WCAG 2.1 AA compliance
 * - Visual Hierarchy (3.1.1): Material Design 3 with dynamic color system
 *
 * @param text The button text to display
 * @param onClick Callback to be invoked when the button is clicked
 * @param enabled Whether the button is enabled
 */
@Composable
fun FounditureOutlinedButton(
    text: String,
    onClick: () -> Unit,
    enabled: Boolean = true
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier
            .height(44.dp) // WCAG 2.1 AA compliant touch target
            .width(200.dp),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = FounditureTheme.colors.primary,
            disabledContentColor = FounditureTheme.colors.primary.copy(alpha = 0.38f)
        ),
        shape = FounditureTheme.shapes.small
    ) {
        Text(
            text = text,
            style = FounditureTheme.typography.labelLarge,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
    }
}