package com.founditure.data.database.entity

// Room persistence library v2.6.0
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.TypeConverters

// Domain model imports
import com.founditure.domain.model.Listing
import com.founditure.domain.model.ListingStatus
import com.founditure.domain.model.FurnitureCondition

// JSON parsing for type conversion
import com.google.gson.Gson // gson:2.10.1
import com.google.gson.reflect.TypeToken

/**
 * Human Tasks:
 * 1. Ensure Room dependencies are properly configured in build.gradle
 * 2. Verify Gson dependency is included for JSON type conversion
 * 3. Configure database migration strategy if schema changes
 * 4. Set up database inspector in Android Studio for debugging
 */

/**
 * Room database entity representing a furniture listing
 * 
 * Requirements addressed:
 * - Data Storage Solutions (2.3.2): Implements structured data storage using Room
 * - Core Features - Furniture listings (1.3): Database persistence for furniture items
 */
@Entity(tableName = "listings")
@TypeConverters(ListingConverters::class)
data class ListingEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "user_id")
    val userId: String,
    
    @ColumnInfo(name = "title")
    val title: String,
    
    @ColumnInfo(name = "description")
    val description: String,
    
    @ColumnInfo(name = "status")
    val status: String,
    
    @ColumnInfo(name = "condition")
    val condition: String,
    
    @ColumnInfo(name = "image_urls")
    val imageUrls: String,
    
    @ColumnInfo(name = "latitude")
    val latitude: Double,
    
    @ColumnInfo(name = "longitude")
    val longitude: Double,
    
    @ColumnInfo(name = "address")
    val address: String,
    
    @ColumnInfo(name = "ai_tags")
    val aiTags: String,
    
    @ColumnInfo(name = "posted_at")
    val postedAt: Long,
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: Long
) {
    /**
     * Converts database entity to domain model
     * 
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Bi-directional conversion between domain and database layers
     */
    fun toListing(): Listing {
        return Listing(
            id = id,
            userId = userId,
            title = title,
            description = description,
            status = ListingStatus.valueOf(status),
            condition = FurnitureCondition.valueOf(condition),
            imageUrls = ListingConverters.jsonToStringList(imageUrls) ?: emptyList(),
            latitude = latitude,
            longitude = longitude,
            address = address,
            aiTags = ListingConverters.jsonToStringMap(aiTags) ?: emptyMap(),
            postedAt = postedAt,
            updatedAt = updatedAt
        )
    }
}

/**
 * Type converters for complex data types in Room database
 * 
 * Requirements addressed:
 * - Data Storage Solutions (2.3.2): Complex type conversion support for Room
 */
class ListingConverters {
    private val gson = Gson()

    @TypeConverter
    fun jsonToStringList(value: String?): List<String>? {
        if (value == null) return null
        val listType = object : TypeToken<List<String>>() {}.type
        return try {
            gson.fromJson(value, listType)
        } catch (e: Exception) {
            emptyList()
        }
    }

    @TypeConverter
    fun stringListToJson(list: List<String>?): String? {
        if (list == null) return null
        return try {
            gson.toJson(list)
        } catch (e: Exception) {
            "[]"
        }
    }

    @TypeConverter
    fun jsonToStringMap(value: String?): Map<String, String>? {
        if (value == null) return null
        val mapType = object : TypeToken<Map<String, String>>() {}.type
        return try {
            gson.fromJson(value, mapType)
        } catch (e: Exception) {
            emptyMap()
        }
    }

    @TypeConverter
    fun stringMapToJson(map: Map<String, String>?): String? {
        if (map == null) return null
        return try {
            gson.toJson(map)
        } catch (e: Exception) {
            "{}"
        }
    }
}