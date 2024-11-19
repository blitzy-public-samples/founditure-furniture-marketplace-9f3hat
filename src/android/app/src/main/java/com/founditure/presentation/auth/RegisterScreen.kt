/*
 * Human Tasks:
 * 1. Test screen reader functionality and content descriptions
 * 2. Verify form validation behavior across different input methods
 * 3. Test keyboard navigation and input field focus handling
 * 4. Validate error state colors meet WCAG contrast requirements
 */

package com.founditure.presentation.auth

// androidx.compose.material3:1.1.0
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.IconButton
import androidx.compose.material3.Icon

// androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding

// androidx.compose.runtime:1.5.0
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue

// androidx.compose.ui:1.5.0
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

// androidx.hilt.navigation.compose:1.0.0
import androidx.hilt.navigation.compose.hiltViewModel

// Internal imports
import com.founditure.R
import com.founditure.presentation.components.FounditureTextField
import com.founditure.presentation.components.FounditureButton
import com.founditure.presentation.theme.Typography

/**
 * Composable screen implementation for user registration in the Founditure app.
 * 
 * Requirements addressed:
 * - User Authentication (1.3 Scope/Core Features): User authentication and profile management
 * - Component Library (3.1.1): Custom Design System with atomic design principles
 * - Visual Hierarchy (3.1.1): Material Design 3 with 8dp grid system
 *
 * @param onRegisterSuccess Callback invoked when registration is successful
 * @param onNavigateBack Callback invoked when user wants to navigate back
 */
@Composable
fun RegisterScreen(
    onRegisterSuccess: () -> Unit,
    onNavigateBack: () -> Unit
) {
    val viewModel: RegisterViewModel = hiltViewModel()

    // Collect state flows
    val email by viewModel.email.collectAsState()
    val password by viewModel.password.collectAsState()
    val name by viewModel.name.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Create Account", style = Typography.titleLarge) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            painter = painterResource(id = R.drawable.ic_arrow_back),
                            contentDescription = "Navigate back"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp)
        ) {
            Spacer(modifier = Modifier.height(24.dp))

            // Display name input
            FounditureTextField(
                value = name,
                onValueChange = viewModel::updateName,
                label = "Display Name",
                modifier = Modifier.fillMaxWidth(),
                isError = error?.contains("name", ignoreCase = true) == true,
                errorMessage = if (error?.contains("name", ignoreCase = true) == true) error else null
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Email input
            FounditureTextField(
                value = email,
                onValueChange = viewModel::updateEmail,
                label = "Email",
                keyboardType = KeyboardType.Email,
                modifier = Modifier.fillMaxWidth(),
                isError = error?.contains("email", ignoreCase = true) == true,
                errorMessage = if (error?.contains("email", ignoreCase = true) == true) error else null
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Password input
            FounditureTextField(
                value = password,
                onValueChange = viewModel::updatePassword,
                label = "Password",
                isPassword = true,
                modifier = Modifier.fillMaxWidth(),
                isError = error?.contains("password", ignoreCase = true) == true,
                errorMessage = if (error?.contains("password", ignoreCase = true) == true) error else null
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Register button
            FounditureButton(
                text = "Create Account",
                onClick = {
                    viewModel.register()
                    if (error == null && !isLoading) {
                        onRegisterSuccess()
                    }
                },
                enabled = email.isNotBlank() && password.isNotBlank() && name.isNotBlank(),
                loading = isLoading
            )

            // General error message
            if (error != null && !error.contains("email", ignoreCase = true) &&
                !error.contains("password", ignoreCase = true) &&
                !error.contains("name", ignoreCase = true)) {
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = error,
                    style = Typography.bodyMedium,
                    color = androidx.compose.material3.MaterialTheme.colorScheme.error,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}