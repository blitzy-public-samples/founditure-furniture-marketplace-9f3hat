// Human Tasks:
// 1. Ensure Android Studio Electric Eel or newer is installed
// 2. Install Android SDK Platform 34 (Android 14) via SDK Manager
// 3. Configure local.properties with valid Android SDK path
// 4. Set up Firebase project and place google-services.json in app/
// 5. Configure signing keys for release builds

// Build script dependencies versions
buildscript {
    repositories {
        google() // Required for Android Gradle Plugin
        mavenCentral() // Required for Kotlin and other dependencies
    }
    dependencies {
        // Requirement: Android Development Environment - Android Gradle Plugin for building Android applications
        classpath("com.android.tools.build:gradle:8.1.2")
        
        // Requirement: Android Development Environment - Kotlin support with modern concurrency
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        
        // Requirement: Mobile Development Framework - Dependency injection support
        classpath("com.google.dagger:hilt-android-gradle-plugin:2.48")
        
        // Firebase integration support
        classpath("com.google.gms:google-services:4.4.0")
        
        // Kotlin Symbol Processing for code generation
        classpath("com.google.devtools.ksp:symbol-processing-gradle-plugin:1.9.0-1.0.13")
    }
}

// Project-wide Gradle settings and configurations
allprojects {
    repositories {
        google()
        mavenCentral()
        
        // Additional repositories for specific dependencies if needed
        maven { url = uri("https://jitpack.io") }
    }
}

// Project-wide properties and versions
// Requirement: Development Environment Setup - Kotlin 1.9+ and latest framework versions
extra.apply {
    set("KOTLIN_VERSION", "1.9.0")
    set("COMPOSE_VERSION", "1.5.4")
    set("HILT_VERSION", "2.48")
    set("MIN_SDK_VERSION", 29)
    set("TARGET_SDK_VERSION", 34)
    set("COMPILE_SDK_VERSION", 34)
    set("FIREBASE_BOM_VERSION", "32.3.1")
    set("COROUTINES_VERSION", "1.7.3")
    set("ROOM_VERSION", "2.6.0")
    set("LIFECYCLE_VERSION", "2.6.2")
}

// Root project configuration
plugins {
    // Requirement: Android Development Environment - Required for Android projects
    id("com.android.application") version "8.1.2" apply false
    id("com.android.library") version "8.1.2" apply false
    
    // Requirement: Android Development Environment - Kotlin support
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    
    // Requirement: Mobile Development Framework - Dependency injection
    id("com.google.dagger.hilt.android") version "2.48" apply false
    
    // Firebase support
    id("com.google.gms.google-services") version "4.4.0" apply false
    
    // Kotlin Symbol Processing
    id("com.google.devtools.ksp") version "1.9.0-1.0.13" apply false
}

// Clean task configuration
tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}

// Gradle configuration validation
tasks.register("validateGradleConfiguration") {
    doLast {
        // Verify minimum SDK version meets requirements
        require(extra["MIN_SDK_VERSION"] as Int >= 29) {
            "Minimum SDK version must be at least 29 (Android 10)"
        }
        
        // Verify Kotlin version meets requirements
        require((extra["KOTLIN_VERSION"] as String).startsWith("1.9")) {
            "Kotlin version must be 1.9 or higher"
        }
        
        // Verify Compose version meets requirements
        require((extra["COMPOSE_VERSION"] as String).startsWith("1.5")) {
            "Compose version must be 1.5 or higher"
        }
    }
}

// Configure default tasks
defaultTasks("clean", "validateGradleConfiguration")