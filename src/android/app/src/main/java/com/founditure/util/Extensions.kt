package com.founditure.util

// Android SDK - Latest version
import android.view.View
import android.content.Context
import android.widget.ImageView
import android.graphics.Bitmap
// Material Components - Version 1.9.0
import com.google.android.material.textview.MaterialTextView
// Glide - Version 4.15.1
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
// Internal models
import com.founditure.domain.model.Listing.FurnitureCondition
import com.founditure.domain.model.User

/**
 * Human Tasks:
 * 1. Ensure Glide dependencies are properly configured in build.gradle
 * 2. Verify Material Design theme is properly applied in the application theme
 * 3. Configure Glide module if custom Glide configurations are needed
 * 4. Set up proper image caching strategy based on app requirements
 */

/**
 * Converts FurnitureCondition enum to user-friendly display string
 * 
 * Requirements addressed:
 * - Core Features (1.3 Scope/In-Scope Elements/Core Features):
 *   Provides standardized furniture condition display formatting
 *
 * @param condition The FurnitureCondition enum value to convert
 * @return Human readable condition string
 */
fun FurnitureCondition.toDisplayString(): String {
    return when (this) {
        FurnitureCondition.EXCELLENT -> "Excellent"
        FurnitureCondition.GOOD -> "Good"
        FurnitureCondition.FAIR -> "Fair"
        FurnitureCondition.POOR -> "Poor"
    }
}

/**
 * Extension function to set view visibility to VISIBLE
 * 
 * Requirements addressed:
 * - User Interface Design (3.1 User Interface Design/3.1.1 Design Specifications):
 *   Implements consistent view visibility control
 */
fun View.setVisible() {
    visibility = View.VISIBLE
}

/**
 * Extension function to set view visibility to GONE
 * 
 * Requirements addressed:
 * - User Interface Design (3.1 User Interface Design/3.1.1 Design Specifications):
 *   Implements consistent view visibility control
 */
fun View.setGone() {
    visibility = View.GONE
}

/**
 * Extension function to load and display images in ImageView using Glide
 * 
 * Requirements addressed:
 * - Core Features (1.3 Scope/In-Scope Elements/Core Features):
 *   Implements efficient image loading and caching
 *
 * @param url The URL of the image to load
 * @param placeholder Resource ID of the placeholder image
 */
fun ImageView.loadImage(url: String, placeholder: Int) {
    Glide.with(context)
        .load(url)
        .placeholder(placeholder)
        .error(placeholder)
        .diskCacheStrategy(DiskCacheStrategy.AUTOMATIC)
        .centerCrop()
        .into(this)
}

/**
 * Extension function to format user points with appropriate suffix
 * 
 * Requirements addressed:
 * - User Interface Design (3.1 User Interface Design/3.1.1 Design Specifications):
 *   Implements consistent points display formatting
 *
 * @param points The number of points to format
 * @return Formatted points string with suffix (K for thousands, M for millions)
 */
fun User.formatPoints(): String {
    return when {
        totalPoints >= 1_000_000 -> String.format("%.1fM pts", totalPoints / 1_000_000f)
        totalPoints >= 1_000 -> String.format("%.1fK pts", totalPoints / 1_000f)
        else -> "$totalPoints pts"
    }
}

/**
 * Extension function to convert density-independent pixels (dp) to pixels (px)
 * 
 * Requirements addressed:
 * - User Interface Design (3.1 User Interface Design/3.1.1 Design Specifications):
 *   Supports responsive UI layouts across different screen densities
 *
 * @param dp The value in density-independent pixels
 * @return The value in pixels based on screen density
 */
fun Context.dpToPx(dp: Float): Int {
    return (dp * resources.displayMetrics.density + 0.5f).toInt()
}