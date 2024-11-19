/*
 * Human Tasks:
 * 1. Ensure BuildConfig.DEBUG is properly configured in build.gradle for different build variants
 * 2. Verify API endpoints are correctly set up in Kong Gateway
 * 3. Configure database connection settings in PostgreSQL instance
 * 4. Set up Redis cache instance and verify connection settings
 * 5. Review and adjust timeout values based on network performance requirements
 * 6. Ensure AWS Rekognition service is properly configured for image processing
 */

package com.founditure.util

// com.android.tools.build:gradle:8.1.0
import com.android.tools.build.gradle.BuildConfig

/**
 * API-related constants for network communication
 * Addresses requirement: API Architecture (2.2.1 Core Components/API Gateway)
 */
object ApiConstants {
    const val BASE_URL = "https://api.founditure.com/"
    const val API_VERSION = "v1"
    const val AUTH_HEADER = "Authorization"
    const val CONTENT_TYPE_JSON = "application/json"
    const val CONTENT_TYPE_MULTIPART = "multipart/form-data"
    const val TIMEOUT_CONNECT = 30 // seconds
    const val TIMEOUT_READ = 30 // seconds
    const val TIMEOUT_WRITE = 30 // seconds

    private constructor() // Prevent instantiation
}

/**
 * Database-related constants for PostgreSQL integration
 * Addresses requirement: Data Storage (2.3.2 Data Storage Solutions)
 */
object DatabaseConstants {
    const val DATABASE_NAME = "founditure_db"
    const val DATABASE_VERSION = 1
    const val TABLE_USERS = "users"
    const val TABLE_LISTINGS = "listings"
    const val TABLE_MESSAGES = "messages"
    const val CACHE_SIZE_MB = 50 // Maximum cache size in megabytes

    private constructor() // Prevent instantiation
}

/**
 * Shared preferences related constants for local storage
 * Addresses requirement: Security Standards (5.2.1 Encryption Standards)
 */
object PreferenceConstants {
    const val PREF_NAME = "founditure_preferences"
    const val KEY_AUTH_TOKEN = "auth_token"
    const val KEY_USER_ID = "user_id"
    const val KEY_THEME_MODE = "theme_mode"
    const val KEY_NOTIFICATION_ENABLED = "notifications_enabled"

    private constructor() // Prevent instantiation
}

/**
 * Location service related constants for GPS tracking
 * Addresses requirement: Device Support (3.1.1 Design Specifications/Device Support)
 */
object LocationConstants {
    const val LOCATION_UPDATE_INTERVAL = 60000L // 1 minute in milliseconds
    const val FASTEST_LOCATION_INTERVAL = 30000L // 30 seconds in milliseconds
    const val LOCATION_DISTANCE_THRESHOLD = 100f // meters
    const val LOCATION_PERMISSION_REQUEST_CODE = 1001

    private constructor() // Prevent instantiation
}

/**
 * Image processing related constants for AWS Rekognition integration
 * Addresses requirement: Security Standards (5.2.1 Encryption Standards)
 */
object ImageConstants {
    const val MAX_IMAGE_SIZE = 10 * 1024 * 1024 // 10MB in bytes
    const val COMPRESSION_QUALITY = 85 // JPEG compression quality (0-100)
    const val IMAGE_FILE_FORMAT = "jpg"
    const val MAX_IMAGES_PER_LISTING = 5

    private constructor() // Prevent instantiation
}