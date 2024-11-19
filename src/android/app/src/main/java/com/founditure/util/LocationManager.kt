/*
 * Human Tasks:
 * 1. Ensure Google Play Services is properly configured in the project
 * 2. Add the following to AndroidManifest.xml:
 *    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
 *    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
 * 3. Configure Google Maps API key in local.properties
 * 4. Verify minimum Android SDK version is set to API 29 (Android 10)
 */

package com.founditure.util

// com.google.android.gms:play-services-location:21.0.1
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.Task
import android.content.Context
import android.location.Geocoder
import android.location.Location
import android.os.Build
import android.Manifest
import java.util.Locale
import kotlin.properties.Lazy
import kotlin.lazy

/**
 * Singleton class managing location services for the Founditure application.
 * Addresses requirements:
 * - Location-based discovery: Provides high-accuracy GPS tracking for furniture discovery
 * - Device Support: Implements Android 10+ compatible location services
 */
object LocationManager {
    private lateinit var fusedLocationClient: Lazy<FusedLocationProviderClient>
    
    /**
     * Default location request configuration using constants for optimal battery performance
     * and accuracy for furniture discovery feature.
     */
    private val defaultLocationRequest = LocationRequest.Builder()
        .setIntervalMillis(LocationConstants.LOCATION_UPDATE_INTERVAL)
        .setMinUpdateIntervalMillis(LocationConstants.FASTEST_LOCATION_INTERVAL)
        .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
        .build()

    /**
     * Initializes the LocationManager with application context.
     * Must be called before using any location services.
     *
     * @param context Application context
     */
    fun initialize(context: Context) {
        fusedLocationClient = lazy {
            LocationServices.getFusedLocationProviderClient(context.applicationContext)
        }
    }

    /**
     * Checks if fine location permission is granted.
     * Required for high-accuracy location tracking in furniture discovery.
     *
     * @param context Application context
     * @return Boolean indicating if permission is granted
     */
    fun checkLocationPermission(context: Context): Boolean {
        return PermissionUtils.hasPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
    }

    /**
     * Starts location updates with specified callback.
     * Implements high-accuracy location tracking for nearby furniture discovery.
     *
     * @param context Application context
     * @param callback LocationCallback for receiving location updates
     * @throws SecurityException if location permission is not granted
     */
    fun requestLocationUpdates(context: Context, callback: LocationCallback) {
        if (!checkLocationPermission(context)) {
            throw SecurityException("Location permission not granted")
        }

        try {
            fusedLocationClient.value.requestLocationUpdates(
                defaultLocationRequest,
                callback,
                context.mainLooper
            )
        } catch (e: SecurityException) {
            // Handle permission-related exceptions
            throw SecurityException("Failed to request location updates: ${e.message}")
        }
    }

    /**
     * Stops ongoing location updates.
     * Should be called in lifecycle destroy/stop to prevent battery drain.
     *
     * @param callback LocationCallback to remove
     */
    fun stopLocationUpdates(callback: LocationCallback) {
        fusedLocationClient.value.removeLocationUpdates(callback)
    }

    /**
     * Retrieves last known device location.
     * Used for initial furniture discovery radius calculation.
     *
     * @param context Application context
     * @return Task<Location> containing the last known location
     * @throws SecurityException if location permission is not granted
     */
    fun getLastKnownLocation(context: Context): Task<Location> {
        if (!checkLocationPermission(context)) {
            throw SecurityException("Location permission not granted")
        }

        return fusedLocationClient.value.lastLocation
    }

    /**
     * Converts GPS coordinates to human-readable address.
     * Used for displaying furniture location details to users.
     *
     * @param context Application context
     * @param latitude Location latitude
     * @param longitude Location longitude
     * @return Formatted address string or null if geocoding fails
     */
    fun getAddressFromLocation(context: Context, latitude: Double, longitude: Double): String? {
        val geocoder = Geocoder(context, Locale.getDefault())
        
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Use the new Android 13+ Geocoder API
                geocoder.getFromLocation(latitude, longitude, 1) { addresses ->
                    addresses.firstOrNull()?.let { address ->
                        buildString {
                            append(address.thoroughfare ?: "")
                            append(", ")
                            append(address.locality ?: "")
                            append(", ")
                            append(address.adminArea ?: "")
                            append(" ")
                            append(address.postalCode ?: "")
                        }
                    }
                }
            } else {
                // Legacy Geocoder API for Android 10-12
                @Suppress("DEPRECATION")
                geocoder.getFromLocation(latitude, longitude, 1)?.firstOrNull()?.let { address ->
                    buildString {
                        append(address.thoroughfare ?: "")
                        append(", ")
                        append(address.locality ?: "")
                        append(", ")
                        append(address.adminArea ?: "")
                        append(" ")
                        append(address.postalCode ?: "")
                    }
                }
            }
        } catch (e: Exception) {
            null // Return null if geocoding fails
        }
    }
}