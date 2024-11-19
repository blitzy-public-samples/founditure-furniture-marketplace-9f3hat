# Founditure Android Application ProGuard Rules
# Version: 1.0
# Last Updated: 2024

# Human Tasks:
# 1. Verify Firebase configuration in google-services.json
# 2. Ensure Google Maps API key is properly configured
# 3. Check TensorFlow Lite model files are in assets folder
# 4. Validate signing configuration in build.gradle
# 5. Test ProGuard configuration with release build before deployment

# Requirement: Security Architecture
# Location: Technical Specification/2.5 Security Architecture/2.5.1 Security Controls
# Description: Code obfuscation and protection implementation
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*

# Requirement: Development Environment Setup
# Location: Technical Specification/Appendices/A.1 Development Environment Setup
# Description: Android build configuration for production
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# General Application Rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses

# Keep the application class and main components
-keep class com.founditure.** { *; }
-keep interface com.founditure.** { *; }

# Android Framework Rules
-keep class * extends android.app.Activity
-keep class * extends android.app.Application
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider
-keep class * extends android.preference.Preference
-keep class * extends android.view.View

# Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Enum classes
-keepclassmembers class * extends java.lang.Enum {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Data Models
-keep class com.founditure.domain.model.** { *; }
-keep class com.founditure.data.database.entity.** { *; }
-keepclassmembers class com.founditure.data.** { *; }

# Firebase Rules (v22.0.0)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Maps Rules (v18.0.0)
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.maps.**

# TensorFlow Lite Rules (v2.9.0)
-keep class org.tensorflow.lite.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
-dontwarn org.tensorflow.lite.**

# Kotlin Rules (v1.9+)
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlin.reflect.** { *; }
-dontwarn kotlin.**
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.** {
    volatile <fields>;
}

# Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keep,includedescriptorclasses class com.founditure.**$$serializer { *; }
-keepclassmembers class com.founditure.** {
    *** Companion;
}
-keepclasseswithmembers class com.founditure.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Reflection
-keepattributes RuntimeVisible*Annotations
-keepattributes AnnotationDefault

# JSON Parsing
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Logging for debugging
-keepnames class com.founditure.** { *; }
-keepnames interface com.founditure.** { *; }

# WebView
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# Crash Reporting
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }

# Image Loading
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule {
    <init>(...);
}
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}

# Database
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# Network
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-dontwarn org.codehaus.mojo.animal_sniffer.*
-dontwarn okhttp3.internal.platform.ConscryptPlatform
-keepnames class com.founditure.network.** { *; }

# Security
-keep class javax.crypto.** { *; }
-keep class javax.security.** { *; }
-keep class java.security.** { *; }
-keep class org.bouncycastle.** { *; }

# Location Services
-keep class * extends android.location.LocationListener { *; }
-keep class com.google.android.gms.location.** { *; }
-keep interface com.google.android.gms.location.** { *; }

# Notifications
-keep class com.founditure.notification.** { *; }
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationCompat$* { *; }

# Media
-keep class android.media.** { *; }
-keep class android.support.media.** { *; }

# Permissions
-keep class androidx.core.app.ActivityCompat { *; }
-keep class androidx.core.content.ContextCompat { *; }