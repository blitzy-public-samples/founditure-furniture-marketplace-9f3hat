/*
 * Human Tasks:
 * 1. Test text field behavior with different input methods (hardware keyboard, soft keyboard, etc.)
 * 2. Verify screen reader functionality and content descriptions
 * 3. Test text field with different font scale settings
 * 4. Validate error state colors meet WCAG contrast requirements
 */

package com.founditure.presentation.theme.components

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.Text

// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.remember

// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation

// Internal theme imports
import com.founditure.presentation.theme.lightColorScheme
import com.founditure.presentation.theme.Typography

/**
 * A customized Material3 OutlinedTextField component that follows Founditure's design system.
 * 
 * Requirements addressed:
 * - Component Library (3.1.1): Reusable text field component with consistent styling
 * - Accessibility (3.1.1): WCAG 2.1 AA compliant with screen reader support
 * - Visual Hierarchy (3.1.1): Material Design 3 with dynamic color system
 *
 * @param value Current text field value
 * @param onValueChange Callback invoked when text field value changes
 * @param label Label text displayed above the text field
 * @param modifier Modifier for customizing the text field's layout and appearance
 * @param isError Whether the text field is in error state
 * @param errorMessage Error message to display when isError is true
 * @param keyboardType Type of keyboard to show for text input
 * @param isPassword Whether the text field should hide input as password
 * @param maxLines Maximum number of lines for the text field
 */
@Composable
fun FounditureTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    isError: Boolean = false,
    errorMessage: String? = null,
    keyboardType: KeyboardType = KeyboardType.Text,
    isPassword: Boolean = false,
    maxLines: Int = 1
) {
    // Configure text field colors using Material3 defaults and our theme
    val colors = TextFieldDefaults.outlinedTextFieldColors(
        textColor = lightColorScheme.onSurface,
        focusedBorderColor = lightColorScheme.primary,
        unfocusedBorderColor = lightColorScheme.outline,
        errorBorderColor = lightColorScheme.error,
        errorLabelColor = lightColorScheme.error,
        errorLeadingIconColor = lightColorScheme.error,
        errorTrailingIconColor = lightColorScheme.error,
        errorSupportingTextColor = lightColorScheme.error,
        cursorColor = lightColorScheme.primary
    )

    // Set up visual transformation for password fields
    val visualTransformation = remember(isPassword) {
        if (isPassword) PasswordVisualTransformation() else VisualTransformation.None
    }

    // Create semantic description for accessibility
    val textFieldDescription = remember(label, isError, errorMessage) {
        buildString {
            append(label)
            if (isError && errorMessage != null) {
                append(", Error: $errorMessage")
            }
        }
    }

    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { 
            Text(
                text = label,
                style = Typography.labelMedium
            )
        },
        modifier = modifier.semantics {
            contentDescription = textFieldDescription
        },
        textStyle = Typography.bodyLarge,
        isError = isError,
        visualTransformation = visualTransformation,
        keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
            keyboardType = keyboardType
        ),
        colors = colors,
        maxLines = maxLines,
        supportingText = if (isError && errorMessage != null) {
            {
                Text(
                    text = errorMessage,
                    color = lightColorScheme.error,
                    style = Typography.labelMedium
                )
            }
        } else null,
        singleLine = maxLines == 1
    )
}