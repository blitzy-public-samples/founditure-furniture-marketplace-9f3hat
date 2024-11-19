/*
 * Human Tasks:
 * 1. Ensure AndroidManifest.xml includes all required permissions:
 *    - android.permission.CAMERA
 *    - android.permission.ACCESS_FINE_LOCATION
 *    - android.permission.ACCESS_COARSE_LOCATION
 *    - android.permission.READ_EXTERNAL_STORAGE
 *    - android.permission.WRITE_EXTERNAL_STORAGE
 * 2. For Android 10+ (API 29+), consider implementing scoped storage alternatives
 *    to READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE
 * 3. Configure proper security provider for Android < 10 if needed
 */

package com.founditure.util

// androidx.core:core-ktx:1.12.0
import androidx.core.content.ContextCompat
import androidx.core.app.ActivityCompat
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.app.Activity

/**
 * Utility object for handling Android runtime permissions required by the Founditure application.
 * Addresses requirements:
 * - Device Support: Support for Android 10+ devices with proper runtime permission handling
 * - AI-powered furniture recognition: Camera permissions for photo capture
 * - Location-based discovery: Location permissions for geofenced areas
 */
object PermissionUtils {

    // Permission request code for handling permission results
    private const val PERMISSION_REQUEST_CODE = 100

    // List of all required permissions for the application
    private val REQUIRED_PERMISSIONS = arrayOf(
        Manifest.permission.CAMERA,
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION,
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE
    )

    /**
     * Checks if a specific permission is granted to the application.
     * 
     * @param context Application or Activity context
     * @param permission The permission to check
     * @return Boolean indicating if the permission is granted
     */
    fun hasPermission(context: Context, permission: String): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Checks if all required permissions (camera, location, storage) are granted.
     * Required for core functionality including furniture photo capture and location-based discovery.
     *
     * @param context Application or Activity context
     * @return Boolean indicating if all required permissions are granted
     */
    fun hasPermissions(context: Context): Boolean {
        return REQUIRED_PERMISSIONS.all { permission ->
            hasPermission(context, permission)
        }
    }

    /**
     * Requests all required permissions that are not yet granted.
     * Implements Android 10+ permission handling requirements.
     *
     * @param activity Activity instance for permission request
     */
    fun requestPermissions(activity: Activity) {
        val permissionsToRequest = REQUIRED_PERMISSIONS.filter { permission ->
            !hasPermission(activity, permission)
        }.toTypedArray()

        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                activity,
                permissionsToRequest,
                PERMISSION_REQUEST_CODE
            )
        }
    }

    /**
     * Checks if permission rationale should be shown for a specific permission.
     * Used to provide additional context to users about why permissions are needed.
     *
     * @param activity Activity instance for checking rationale
     * @param permission The permission to check for rationale
     * @return Boolean indicating if rationale should be shown
     */
    fun shouldShowRationale(activity: Activity, permission: String): Boolean {
        return ActivityCompat.shouldShowRequestPermissionRationale(
            activity,
            permission
        )
    }
}