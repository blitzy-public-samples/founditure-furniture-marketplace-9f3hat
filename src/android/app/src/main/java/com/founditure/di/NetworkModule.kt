/*
 * Human Tasks:
 * 1. Configure ProGuard rules for Retrofit, OkHttp, and Moshi
 * 2. Set up SSL certificate pinning for production environment
 * 3. Configure proper logging levels for different build variants
 * 4. Verify BASE_URL configuration matches environment settings
 * 5. Ensure proper network security configuration in Android Manifest
 */

package com.founditure.di

// Dagger Hilt v2.48
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

// Retrofit v2.9.0
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory

// OkHttp v4.11.0
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor

// Moshi v1.15.0
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory

// Internal imports
import com.founditure.data.api.ApiService
import com.founditure.data.api.AuthInterceptor

import java.util.concurrent.TimeUnit
import javax.inject.Singleton

/**
 * Dagger Hilt module providing network-related dependencies with security and monitoring features.
 * 
 * Requirements addressed:
 * - API Architecture (3.3.1): Implements REST/HTTP/2 protocol with JWT + OAuth2 authentication
 * - Security Controls (5.3.1): API Gateway with rate limiting, SSL termination
 */
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    private const val BASE_URL = "https://api.founditure.com/v1/"
    private const val NETWORK_TIMEOUT = 30L

    /**
     * Provides singleton OkHttpClient instance with authentication and logging interceptors.
     * 
     * Requirements addressed:
     * - API Architecture (3.3.1): Implements secure HTTP client with authentication
     * - Security Controls (5.3.1): Configures secure communication with timeouts
     */
    @Provides
    @Singleton
    fun provideOkHttpClient(authInterceptor: AuthInterceptor): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        }

        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            .addInterceptor(authInterceptor)
            .connectTimeout(NETWORK_TIMEOUT, TimeUnit.SECONDS)
            .readTimeout(NETWORK_TIMEOUT, TimeUnit.SECONDS)
            .writeTimeout(NETWORK_TIMEOUT, TimeUnit.SECONDS)
            .build()
    }

    /**
     * Provides singleton Moshi instance for JSON parsing with Kotlin support.
     * 
     * Requirements addressed:
     * - API Architecture (3.3.1): Implements standardized JSON parsing
     */
    @Provides
    @Singleton
    fun provideMoshi(): Moshi {
        return Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()
    }

    /**
     * Provides singleton Retrofit instance with Moshi converter.
     * 
     * Requirements addressed:
     * - API Architecture (3.3.1): Configures type-safe HTTP client
     * - Security Controls (5.3.1): Implements secure API communication
     */
    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, moshi: Moshi): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }

    /**
     * Provides singleton ApiService implementation using Retrofit.
     * 
     * Requirements addressed:
     * - API Architecture (3.3.1): Implements comprehensive API service
     * - Security Controls (5.3.1): Ensures secure API access
     */
    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): ApiService {
        return retrofit.create(ApiService::class.java)
    }
}