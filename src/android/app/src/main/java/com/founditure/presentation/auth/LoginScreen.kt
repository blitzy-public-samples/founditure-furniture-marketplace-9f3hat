/*
 * Human Tasks:
 * 1. Test screen reader functionality with TalkBack enabled
 * 2. Verify color contrast ratios meet WCAG 2.1 AA standards
 * 3. Test form validation behavior across different devices
 * 4. Validate keyboard navigation and input method handling
 */

package com.founditure.presentation.auth

// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.collectAsState

// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text

// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

// androidx.hilt:hilt-navigation-compose:1.0.0
import androidx.hilt.navigation.compose.hiltViewModel

// Internal imports
import com.founditure.presentation.components.FounditureButton
import com.founditure.presentation.components.FounditureTextField
import com.founditure.presentation.components.LoadingIndicator

/**
 * Main composable function that renders the login screen UI with Material Design 3 components
 * and WCAG 2.1 AA compliance.
 *
 * Requirements addressed:
 * - User Authentication (1.3 Scope/Core Features): User authentication and profile management
 * - Visual Hierarchy (3.1.1 Design Specifications): Material Design 3 with dynamic color system
 * - Accessibility (3.1.1 Design Specifications): WCAG 2.1 AA compliance with screen reader support
 *
 * @param onLoginSuccess Callback invoked when login is successful
 * @param onNavigateToRegister Callback invoked when user wants to navigate to registration
 */
@Composable
fun LoginScreen(
    onLoginSuccess: () -> Unit,
    onNavigateToRegister: () -> Unit,
    viewModel: LoginViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    // Handle successful login
    if (uiState.user != null) {
        onLoginSuccess()
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
            .semantics { contentDescription = "Login Screen" },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(48.dp))

        // App logo and welcome text
        Text(
            text = "Founditure",
            style = MaterialTheme.typography.headlineLarge,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.semantics { contentDescription = "Founditure Logo" }
        )

        Text(
            text = "Welcome back",
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.padding(top = 8.dp)
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Email input field
        FounditureTextField(
            value = email,
            onValueChange = { email = it },
            label = "Email",
            keyboardType = KeyboardType.Email,
            isError = uiState.error != null,
            errorMessage = if (uiState.error?.contains("email", ignoreCase = true) == true) {
                uiState.error
            } else null,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Password input field
        FounditureTextField(
            value = password,
            onValueChange = { password = it },
            label = "Password",
            isPassword = true,
            isError = uiState.error != null,
            errorMessage = if (uiState.error?.contains("password", ignoreCase = true) == true) {
                uiState.error
            } else null,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Error message
        if (uiState.error != null && 
            !uiState.error.contains("email", ignoreCase = true) && 
            !uiState.error.contains("password", ignoreCase = true)) {
            Text(
                text = uiState.error,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .semantics { contentDescription = "Error: ${uiState.error}" }
            )
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Login button
        FounditureButton(
            text = "Login",
            onClick = { viewModel.login(email, password) },
            enabled = email.isNotBlank() && password.isNotBlank(),
            loading = uiState.isLoading,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Register navigation button
        FounditureButton(
            text = "Create Account",
            onClick = onNavigateToRegister,
            enabled = !uiState.isLoading,
            modifier = Modifier.fillMaxWidth()
        )

        // Loading indicator
        if (uiState.isLoading) {
            LoadingIndicator(
                size = 48.dp,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}