/*
 * Founditure Android Application
 * Shape System Implementation
 * 
 * Requirements Addressed:
 * - Visual Hierarchy (3. SYSTEM DESIGN/3.1 User Interface Design/3.1.1 Design Specifications)
 *   Implementation of Material Design 3 with 8dp grid system
 * - Component Library (3. SYSTEM DESIGN/3.1 User Interface Design/3.1.1 Design Specifications)
 *   Custom Design System with atomic design principles
 */

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.Shapes

// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.shape.RoundedCornerShape

// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.unit.dp

/**
 * Defines the shape system for the Founditure application following Material Design 3 principles.
 * The shape system uses a consistent corner radius scale based on the 8dp grid system:
 * - extraSmall: 4dp (half grid)
 * - small: 8dp (single grid)
 * - medium: 12dp (1.5 grid)
 * - large: 16dp (double grid)
 * - extraLarge: 24dp (triple grid)
 */
val FounditureShapes = Shapes(
    extraSmall = RoundedCornerShape(4.dp),  // Used for small UI elements like chips and badges
    small = RoundedCornerShape(8.dp),       // Used for cards and buttons
    medium = RoundedCornerShape(12.dp),     // Used for dialogs and bottom sheets
    large = RoundedCornerShape(16.dp),      // Used for large cards and modals
    extraLarge = RoundedCornerShape(24.dp)  // Used for full-screen dialogs and expanded components
)