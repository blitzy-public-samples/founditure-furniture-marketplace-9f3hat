/*
 * Human Tasks:
 * 1. Verify edge-to-edge display behavior on devices with different notch configurations
 * 2. Test dynamic color adaptation on Android 12+ devices
 * 3. Validate theme transitions between light and dark modes
 * 4. Test navigation state preservation across configuration changes
 */

package com.founditure

// Hilt dependency injection - dagger.hilt.android:hilt-android:2.48
import dagger.hilt.android.AndroidEntryPoint

// Compose activity - androidx.activity:activity-compose:1.7.2
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent

// Compose navigation - androidx.navigation:navigation-compose:2.7.1
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.rememberNavController

// Window insets - androidx.core:core:1.10.0
import androidx.core.view.WindowCompat

// Internal imports
import com.founditure.presentation.theme.FounditureTheme
import com.founditure.presentation.home.HomeScreen

/**
 * Main activity class that serves as the single-activity host for Jetpack Compose navigation
 * and implements Material Design 3 theming with edge-to-edge design.
 *
 * Requirements addressed:
 * - Core Features (1.3): Implements core application features including navigation and UI management
 * - Device Support (3.1.1): Supports Android 10+ devices with responsive design
 * - User Interface Design (3.1.1): Implements Material Design 3 with dynamic theming
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    /**
     * Initializes the activity and sets up the Compose UI with Material Design 3 theming
     * and edge-to-edge display support.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Enable edge-to-edge display
        WindowCompat.setDecorFitsSystemWindows(window, false)

        setContent {
            // Create and remember NavController instance
            val navController = rememberNavController()

            FounditureTheme {
                // Set up navigation with HomeScreen as the start destination
                NavHost(
                    navController = navController,
                    startDestination = "home"
                ) {
                    composable("home") {
                        HomeScreen(navController = navController)
                    }
                    // Additional navigation destinations will be added here
                }
            }
        }
    }

    /**
     * Handles activity resume lifecycle event, checking permissions
     * and refreshing user location.
     */
    override fun onResume() {
        super.onResume()
        // Check and request necessary permissions
        if (!PermissionUtils.hasPermissions(this)) {
            PermissionUtils.requestPermissions(this)
        }
    }
}