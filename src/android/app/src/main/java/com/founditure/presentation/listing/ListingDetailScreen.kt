/*
 * Human Tasks:
 * 1. Test screen behavior with different network conditions
 * 2. Verify accessibility features with TalkBack enabled
 * 3. Test screen with different device orientations
 * 4. Validate image loading performance with different image sizes
 */

package com.founditure.presentation.listing

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.*
import androidx.compose.material3.MaterialTheme

// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.*

// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items

// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.style.TextOverflow

// Internal imports
import com.founditure.presentation.components.ListingCard
import com.founditure.presentation.components.LoadingIndicator
import com.founditure.domain.model.Message
import com.founditure.presentation.theme.FounditureTheme

/**
 * Main composable screen that displays detailed information about a furniture listing.
 * 
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3): Detailed view of furniture listings
 * - Real-time messaging (1.3): Real-time communication between users
 * - Visual Hierarchy (3.1.1): Material Design 3 implementation
 *
 * @param viewModel ViewModel instance for managing listing details state
 * @param listingId Unique identifier of the listing to display
 * @param onNavigateBack Callback to handle navigation back
 */
@Composable
fun ListingDetailScreen(
    viewModel: ListingDetailViewModel,
    listingId: String,
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val messages by viewModel.messages.collectAsState()
    var messageInput by remember { mutableStateOf("") }

    // Load listing details on initial composition
    LaunchedEffect(listingId) {
        viewModel.loadListingDetails(listingId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = when (uiState) {
                            is ListingDetailUiState.Success -> (uiState as ListingDetailUiState.Success).listing.title
                            else -> "Listing Details"
                        },
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Navigate back"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when (uiState) {
                is ListingDetailUiState.Loading -> {
                    LoadingIndicator()
                }

                is ListingDetailUiState.Success -> {
                    val listing = (uiState as ListingDetailUiState.Success).listing
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Listing details card
                        item {
                            ListingCard(
                                listing = listing,
                                onClick = { /* Already on detail screen */ },
                                onMessageClick = { /* Handled in message section */ },
                                showActions = false
                            )
                        }

                        // Message thread section
                        if (listing.isAvailable()) {
                            item {
                                Text(
                                    text = "Messages",
                                    style = MaterialTheme.typography.titleLarge,
                                    modifier = Modifier.padding(vertical = 8.dp)
                                )
                            }

                            items(messages) { message ->
                                ListingMessageItem(message)
                            }

                            item {
                                MessageInput(
                                    value = messageInput,
                                    onValueChange = { messageInput = it },
                                    onSendMessage = {
                                        if (messageInput.isNotBlank()) {
                                            viewModel.sendMessage(messageInput)
                                            messageInput = ""
                                        }
                                    }
                                )
                            }
                        }
                    }
                }

                is ListingDetailUiState.Error -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = (uiState as ListingDetailUiState.Error).message,
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.error
                        )
                        Button(
                            onClick = { viewModel.refreshListing() },
                            modifier = Modifier.padding(top = 16.dp)
                        ) {
                            Text("Retry")
                        }
                    }
                }
            }
        }
    }
}

/**
 * Composable for displaying individual messages in the thread.
 *
 * Requirements addressed:
 * - Real-time messaging (1.3): Message display with Material Design styling
 * - Visual Hierarchy (3.1.1): Proper elevation and dynamic color system
 */
@Composable
private fun ListingMessageItem(message: Message) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.surfaceVariant,
        tonalElevation = 1.dp
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = message.content,
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = "Sent ${formatTimestamp(message.timestamp)}",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Composable for the message input field.
 *
 * Requirements addressed:
 * - Real-time messaging (1.3): Message input with Material Design styling
 * - Visual Hierarchy (3.1.1): Material Design 3 implementation
 */
@Composable
private fun MessageInput(
    value: String,
    onValueChange: (String) -> Unit,
    onSendMessage: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 2.dp
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = value,
                onValueChange = onValueChange,
                modifier = Modifier.weight(1f),
                placeholder = { Text("Type a message") },
                maxLines = 3
            )
            Button(
                onClick = onSendMessage,
                enabled = value.isNotBlank()
            ) {
                Text("Send")
            }
        }
    }
}

private fun formatTimestamp(timestamp: Long): String {
    // TODO: Implement proper timestamp formatting
    return android.text.format.DateUtils.getRelativeTimeSpanString(
        timestamp,
        System.currentTimeMillis(),
        android.text.format.DateUtils.MINUTE_IN_MILLIS
    ).toString()
}