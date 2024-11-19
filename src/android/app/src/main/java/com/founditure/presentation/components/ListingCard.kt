/*
 * Human Tasks:
 * 1. Test touch targets with Android's accessibility scanner to verify 44dp minimum size
 * 2. Validate color contrast ratios meet WCAG 2.1 AA standards (4.5:1)
 * 3. Test card interactions with screen readers and TalkBack
 * 4. Verify image loading states and error handling across different network conditions
 */

package com.founditure.presentation.components

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text

// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.Composable

// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*

// coil-compose:2.4.0
import coil.compose.AsyncImage

// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp

// Internal imports
import com.founditure.domain.model.Listing
import com.founditure.domain.model.ListingStatus
import com.founditure.presentation.theme.FounditureTheme

/**
 * A Material3 card component that displays furniture listing information.
 * 
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3): Visual representation of listing items
 * - Visual Hierarchy (3.1.1): Material Design 3 card with elevation
 * - Component Library (3.1.1): Reusable card component
 * - Accessibility (3.1.1): WCAG 2.1 AA compliant
 *
 * @param listing The furniture listing to display
 * @param onClick Callback when the card is clicked
 * @param onMessageClick Callback when the message button is clicked
 * @param showActions Whether to show action buttons
 */
@Composable
fun ListingCard(
    listing: Listing,
    onClick: (Listing) -> Unit,
    onMessageClick: (Listing) -> Unit,
    showActions: Boolean = true
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .clickable { onClick(listing) }
            .semantics {
                contentDescription = "Furniture listing for ${listing.title}"
                role = Role.Button
            },
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        shape = FounditureTheme.shapes.medium
    ) {
        Column {
            // Image preview with error handling
            AsyncImage(
                model = listing.imageUrls.firstOrNull(),
                contentDescription = "Image of ${listing.title}",
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                contentScale = ContentScale.Crop,
                error = null // TODO: Add error placeholder
            )

            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Title and status row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = listing.title,
                        style = FounditureTheme.typography.titleLarge,
                        color = FounditureTheme.colors.onSurface
                    )
                    ListingStatusIndicator(listing.status)
                }

                // Description
                Text(
                    text = listing.description,
                    style = FounditureTheme.typography.bodyMedium,
                    color = FounditureTheme.colors.onSurfaceVariant,
                    maxLines = 2
                )

                // Condition
                Text(
                    text = "Condition: ${listing.condition.name}",
                    style = FounditureTheme.typography.labelMedium,
                    color = FounditureTheme.colors.onSurfaceVariant
                )

                // Action buttons
                if (showActions && listing.isAvailable()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FounditureButton(
                            text = "Message",
                            onClick = { onMessageClick(listing) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }
    }
}

/**
 * A status indicator component for furniture listings.
 * 
 * Requirements addressed:
 * - Visual Hierarchy (3.1.1): Material Design 3 color system
 * - Accessibility (3.1.1): WCAG 2.1 AA compliant contrast
 *
 * @param status The current status of the listing
 */
@Composable
private fun ListingStatusIndicator(status: ListingStatus) {
    val (backgroundColor, textColor) = when (status) {
        ListingStatus.AVAILABLE -> FounditureTheme.colors.primaryContainer to FounditureTheme.colors.onPrimaryContainer
        ListingStatus.PENDING -> FounditureTheme.colors.tertiaryContainer to FounditureTheme.colors.onTertiaryContainer
        ListingStatus.COLLECTED -> FounditureTheme.colors.secondaryContainer to FounditureTheme.colors.onSecondaryContainer
        else -> FounditureTheme.colors.surfaceVariant to FounditureTheme.colors.onSurfaceVariant
    }

    Surface(
        color = backgroundColor,
        contentColor = textColor,
        shape = FounditureTheme.shapes.small,
        modifier = Modifier.semantics {
            contentDescription = "Listing status: ${status.name}"
        }
    ) {
        Text(
            text = status.name,
            style = FounditureTheme.typography.labelMedium,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}