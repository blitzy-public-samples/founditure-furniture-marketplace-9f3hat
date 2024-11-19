/*
 * External dependencies:
 * dagger.hilt.android:2.48
 * com.jakewharton.timber:5.0.1
 * com.google.firebase.crashlytics:18.5.1
 */

package com.founditure

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber
import com.google.firebase.crashlytics.FirebaseCrashlytics

/**
 * Human Tasks:
 * 1. Configure Firebase project and add google-services.json
 * 2. Set up ProGuard rules for Timber and Firebase
 * 3. Configure proper notification icons in resources
 * 4. Set up Firebase Crashlytics dashboard monitoring
 * 5. Configure proper logging levels for production environment
 */

/**
 * Main Application class for the Founditure app that initializes core components and configurations.
 * 
 * Requirements addressed:
 * - Core Features (1.3 Scope/Core Features): Initializes core application features including 
 *   authentication, AI-powered recognition, location services, and real-time messaging
 * - System Architecture (2.1 High-Level Architecture/Mobile Applications): Implements Android native 
 *   application initialization and configuration
 * - Cross-Cutting Concerns (2.4 Cross-Cutting Concerns/2.4.1 System Monitoring): Sets up application 
 *   monitoring, logging, and crash reporting
 */
@HiltAndroidApp
class FounditureApplication : Application() {

    private val isDebug: Boolean by lazy { BuildConfig.DEBUG }
    private lateinit var notificationManager: NotificationManager
    private lateinit var crashlytics: FirebaseCrashlytics

    /**
     * Initializes application components on app startup.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Initializes essential services and configurations
     * - System Monitoring (2.4.1): Sets up logging and crash reporting
     */
    override fun onCreate() {
        super.onCreate()

        // Initialize logging
        setupLogging()

        // Configure Crashlytics
        crashlytics = FirebaseCrashlytics.getInstance().apply {
            setCrashlyticsCollectionEnabled(!isDebug)
        }

        // Set up notification channels
        setupNotificationChannels()
    }

    /**
     * Configures Timber logging for debug and release builds.
     * 
     * Requirements addressed:
     * - System Monitoring (2.4.1): Implements comprehensive logging strategy
     */
    private fun setupLogging() {
        if (isDebug) {
            // Use debug logging tree in debug builds
            Timber.plant(Timber.DebugTree())
        } else {
            // Use Crashlytics logging tree in release builds
            Timber.plant(object : Timber.Tree() {
                override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
                    crashlytics.log(message)
                    t?.let { crashlytics.recordException(it) }
                }
            })
        }
    }

    /**
     * Creates and configures notification channels for different types of notifications.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Implements real-time messaging and notification system
     */
    private fun setupNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Message notification channel
            NotificationChannel(
                CHANNEL_MESSAGES,
                "Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Real-time messaging notifications"
                enableVibration(true)
                notificationManager.createNotificationChannel(this)
            }

            // Listing notification channel
            NotificationChannel(
                CHANNEL_LISTINGS,
                "Listings",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Furniture listing updates and matches"
                notificationManager.createNotificationChannel(this)
            }

            // Achievement notification channel
            NotificationChannel(
                CHANNEL_ACHIEVEMENTS,
                "Achievements",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Achievement and gamification updates"
                notificationManager.createNotificationChannel(this)
            }
        }
    }

    companion object {
        private const val CHANNEL_MESSAGES = "channel_messages"
        private const val CHANNEL_LISTINGS = "channel_listings"
        private const val CHANNEL_ACHIEVEMENTS = "channel_achievements"
    }
}