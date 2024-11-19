/*
 * Human Tasks:
 * 1. Test pull-to-refresh behavior across different Android versions and devices
 * 2. Verify accessibility features with TalkBack enabled
 * 3. Test location permission handling on different Android versions
 * 4. Validate color contrast ratios meet WCAG 2.1 AA standards
 * 5. Test filter interactions and state persistence
 */

package com.founditure.presentation.home

// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.*
import androidx.compose.material3.pullrefresh.PullRefreshIndicator
import androidx.compose.material3.pullrefresh.pullRefresh
import androidx.compose.material3.pullrefresh.rememberPullRefreshState

// androidx.lifecycle:lifecycle-runtime-compose:2.6.2
import androidx.lifecycle.compose.collectAsStateWithLifecycle

// androidx.hilt:hilt-navigation-compose:1.0.0
import androidx.hilt.navigation.compose.hiltViewModel

// androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.NavController

// Internal imports
import com.founditure.presentation.components.ListingCard
import com.founditure.presentation.components.LoadingIndicator
import com.founditure.domain.model.FurnitureCondition
import com.founditure.domain.model.ListingStatus

/**
 * Main composable for the home screen that displays nearby furniture listings.
 * 
 * Requirements addressed:
 * - Core Features - Location-based furniture discovery (1.3):
 *   Implements location-based furniture discovery with pull-to-refresh
 * - User Interface Design (3.1.1):
 *   Follows Material Design 3 principles with responsive layout
 * - User Engagement (1.2):
 *   Supports user retention through engaging home feed
 *
 * @param navController Navigation controller for handling screen transitions
 */
@Composable
fun HomeScreen(
    navController: NavController,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var isRefreshing by remember { mutableStateOf(false) }
    var showFilterSheet by remember { mutableStateOf(false) }

    // Handle pull-to-refresh
    val pullRefreshState = rememberPullRefreshState(
        refreshing = isRefreshing,
        onRefresh = {
            isRefreshing = true
            viewModel.loadListings()
        }
    )

    // Update refresh state based on UI state
    LaunchedEffect(uiState) {
        if (uiState !is HomeUiState.Loading) {
            isRefreshing = false
        }
    }

    Scaffold(
        topBar = {
            HomeTopAppBar(
                viewModel = viewModel,
                onFilterClick = { showFilterSheet = true }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .pullRefresh(pullRefreshState)
        ) {
            HomeContent(
                uiState = uiState,
                onListingClick = { listing ->
                    navController.navigate("listing/${listing.id}")
                }
            )

            // Pull-to-refresh indicator
            PullRefreshIndicator(
                refreshing = isRefreshing,
                state = pullRefreshState,
                modifier = Modifier.align(Alignment.TopCenter),
                contentColor = MaterialTheme.colorScheme.primary
            )

            // Filter bottom sheet
            if (showFilterSheet) {
                FilterBottomSheet(
                    onDismiss = { showFilterSheet = false },
                    onApplyFilter = { status, condition ->
                        viewModel.applyFilter(status, condition)
                        showFilterSheet = false
                    }
                )
            }
        }
    }
}

/**
 * Top app bar component with filter action.
 * 
 * Requirements addressed:
 * - User Interface Design (3.1.1):
 *   Implements Material Design 3 top app bar with proper elevation
 */
@Composable
private fun HomeTopAppBar(
    viewModel: HomeViewModel,
    onFilterClick: () -> Unit
) {
    TopAppBar(
        title = {
            Text(
                text = "Nearby Furniture",
                style = MaterialTheme.typography.titleLarge
            )
        },
        actions = {
            IconButton(
                onClick = onFilterClick,
                modifier = Modifier.semantics {
                    contentDescription = "Filter listings"
                }
            ) {
                Icon(
                    imageVector = Icons.Filled.FilterList,
                    contentDescription = null
                )
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = MaterialTheme.colorScheme.surface,
            titleContentColor = MaterialTheme.colorScheme.onSurface
        )
    )
}

/**
 * Main content area displaying the list of furniture listings.
 * 
 * Requirements addressed:
 * - Core Features - Location-based furniture discovery (1.3):
 *   Displays nearby furniture listings with proper loading and error states
 * - User Interface Design (3.1.1):
 *   Implements responsive layout with proper spacing
 */
@Composable
private fun HomeContent(
    uiState: HomeUiState,
    onListingClick: (Listing) -> Unit
) {
    when (uiState) {
        is HomeUiState.Loading -> {
            LoadingIndicator()
        }
        is HomeUiState.Error -> {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = uiState.message,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = { viewModel.loadListings() }
                ) {
                    Text("Retry")
                }
            }
        }
        is HomeUiState.Success -> {
            if (uiState.listings.isEmpty()) {
                EmptyState()
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(vertical = 8.dp)
                ) {
                    items(
                        items = uiState.listings,
                        key = { it.id }
                    ) { listing ->
                        ListingCard(
                            listing = listing,
                            onClick = onListingClick,
                            onMessageClick = { /* Navigate to messaging */ },
                            showActions = true
                        )
                    }
                }
            }
        }
    }
}

/**
 * Empty state component when no listings are available.
 * 
 * Requirements addressed:
 * - User Interface Design (3.1.1):
 *   Provides clear feedback for empty states
 */
@Composable
private fun EmptyState() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "No furniture listings found nearby",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Pull to refresh or adjust your filters",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Bottom sheet for filtering listings.
 * 
 * Requirements addressed:
 * - User Interface Design (3.1.1):
 *   Implements Material Design 3 bottom sheet with proper interaction
 */
@Composable
private fun FilterBottomSheet(
    onDismiss: () -> Unit,
    onApplyFilter: (ListingStatus?, FurnitureCondition?) -> Unit
) {
    var selectedStatus by remember { mutableStateOf<ListingStatus?>(null) }
    var selectedCondition by remember { mutableStateOf<FurnitureCondition?>(null) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "Filter Listings",
                style = MaterialTheme.typography.titleLarge
            )
            Spacer(modifier = Modifier.height(16.dp))

            // Status filter
            Text(
                text = "Status",
                style = MaterialTheme.typography.titleMedium
            )
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                mainAxisSpacing = 8.dp,
                crossAxisSpacing = 8.dp
            ) {
                ListingStatus.values().forEach { status ->
                    FilterChip(
                        selected = status == selectedStatus,
                        onClick = {
                            selectedStatus = if (status == selectedStatus) null else status
                        },
                        label = { Text(status.name) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Condition filter
            Text(
                text = "Condition",
                style = MaterialTheme.typography.titleMedium
            )
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                mainAxisSpacing = 8.dp,
                crossAxisSpacing = 8.dp
            ) {
                FurnitureCondition.values().forEach { condition ->
                    FilterChip(
                        selected = condition == selectedCondition,
                        onClick = {
                            selectedCondition = if (condition == selectedCondition) null else condition
                        },
                        label = { Text(condition.name) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Apply button
            Button(
                onClick = { onApplyFilter(selectedStatus, selectedCondition) },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Apply Filters")
            }
        }
    }
}