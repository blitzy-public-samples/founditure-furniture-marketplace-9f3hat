/*
 * Human Tasks:
 * 1. Test screen behavior with different data states (loading, error, success)
 * 2. Verify pull-to-refresh functionality across different Android versions
 * 3. Test accessibility features with TalkBack enabled
 * 4. Validate color contrast ratios in both light and dark themes
 * 5. Test offline functionality and data persistence
 */

package com.founditure.presentation.profile

// External dependencies
import androidx.compose.runtime.Composable // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.collectAsState // androidx.compose.runtime:1.5.0
import androidx.compose.foundation.layout.Column // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.layout.padding // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.layout.fillMaxSize // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.layout.Spacer // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.layout.height // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.lazy.LazyColumn // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.lazy.items // androidx.compose.foundation:1.5.0
import androidx.compose.material3.* // androidx.compose.material3:1.1.0
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel // androidx.lifecycle:lifecycle-viewmodel-compose:2.6.1

// Internal dependencies
import com.founditure.presentation.components.LoadingIndicator
import com.founditure.presentation.theme.FounditureTheme
import com.founditure.domain.model.Achievement

/**
 * Main profile screen composable implementing Material Design 3 principles.
 * 
 * Requirements addressed:
 * - User Profile Management (1.3 Scope/Core Features): Displays user profile information
 * - Gamification System (1.2 System Overview): Shows achievements and points
 * - User Engagement (1.2 System Overview/Success Criteria): Promotes engagement through profile features
 */
@Composable
fun ProfileScreen(
    navController: NavController,
    modifier: Modifier = Modifier
) {
    val viewModel: ProfileViewModel = viewModel()
    val uiState = viewModel.uiState.collectAsState()

    FounditureTheme {
        Surface(
            modifier = modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            when (val currentState = uiState.value) {
                is ProfileUiState.Loading -> {
                    LoadingIndicator(
                        size = 48.dp,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                is ProfileUiState.Success -> {
                    ProfileContent(
                        uiState = currentState,
                        onRefresh = { viewModel.refreshProfile() }
                    )
                }
                is ProfileUiState.Error -> {
                    ProfileError(
                        message = currentState.message,
                        onRetry = { viewModel.refreshProfile() }
                    )
                }
            }
        }
    }
}

/**
 * Composable for displaying the main profile content with Material Design 3 styling.
 */
@Composable
private fun ProfileContent(
    uiState: ProfileUiState.Success,
    onRefresh: () -> Unit,
    modifier: Modifier = Modifier
) {
    val pullRefreshState = rememberPullRefreshState(
        refreshing = false,
        onRefresh = onRefresh
    )

    Column(
        modifier = modifier
            .fillMaxSize()
            .pullRefresh(pullRefreshState)
    ) {
        // Profile Header Card
        Card(
            modifier = Modifier.padding(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = uiState.user.displayName,
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Points: ${uiState.user.totalPoints}",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Unlocked Achievements Section
        AchievementsSection(
            achievements = uiState.user.getUnlockedAchievements(),
            title = "Unlocked Achievements"
        )

        // Achievements in Progress Section
        AchievementsSection(
            achievements = uiState.user.getProgressingAchievements(),
            title = "Achievements in Progress"
        )
    }
}

/**
 * Composable for displaying achievement sections with Material Design 3 styling.
 */
@Composable
private fun AchievementsSection(
    achievements: List<Achievement>,
    title: String,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(horizontal = 16.dp)
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.padding(vertical = 8.dp)
        )

        LazyColumn {
            items(achievements) { achievement ->
                Card(
                    modifier = Modifier
                        .padding(vertical = 4.dp)
                        .fillMaxSize(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = achievement.name,
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = achievement.description,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        if (!achievement.isComplete()) {
                            Spacer(modifier = Modifier.height(8.dp))
                            LinearProgressIndicator(
                                progress = achievement.getProgressPercentage() / 100f,
                                modifier = Modifier.fillMaxSize(),
                                color = MaterialTheme.colorScheme.primary,
                                trackColor = MaterialTheme.colorScheme.surfaceVariant
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * Composable for displaying error state with Material Design 3 styling.
 */
@Composable
private fun ProfileError(
    message: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.error
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick = onRetry,
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary
            )
        ) {
            Text("Retry")
        }
    }
}