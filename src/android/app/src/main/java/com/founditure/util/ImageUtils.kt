package com.founditure.util

// android.graphics library - Android SDK latest
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.content.Context
import android.net.Uri
import java.io.File
import java.io.FileOutputStream
import java.io.ByteArrayOutputStream
import com.founditure.util.ImageConstants.MAX_IMAGE_SIZE
import com.founditure.util.ImageConstants.COMPRESSION_QUALITY
import com.founditure.util.ImageConstants.IMAGE_FILE_FORMAT

/*
 * Human Tasks:
 * 1. Verify AWS Rekognition service is properly configured and accessible
 * 2. Ensure sufficient storage permissions are granted in AndroidManifest.xml
 * 3. Monitor memory usage patterns during image processing operations
 * 4. Validate color space compatibility with AWS Rekognition requirements
 * 5. Test image processing performance on various Android device tiers
 */

/**
 * Utility object providing image processing functions optimized for furniture recognition.
 * Addresses requirements:
 * - AI-powered furniture recognition (1.3 Scope/Core Features)
 * - Image Processing (4.1 PROGRAMMING LANGUAGES/Android)
 */
object ImageUtils {

    /**
     * Processes an image to prepare it for AWS Rekognition furniture analysis
     */
    fun prepareForAI(bitmap: Bitmap): Bitmap {
        require(bitmap.width > 0 && bitmap.height > 0) { "Invalid bitmap dimensions" }

        // Calculate target dimensions while maintaining aspect ratio
        val scale = calculateScaleFactor(bitmap.width, bitmap.height, MAX_IMAGE_SIZE)
        val targetWidth = (bitmap.width * scale).toInt()
        val targetHeight = (bitmap.height * scale).toInt()

        // Create scaled bitmap with RGB_565 format for AWS Rekognition compatibility
        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
        val processedBitmap = scaledBitmap.copy(Bitmap.Config.RGB_565, true)
        
        if (scaledBitmap != bitmap) {
            scaledBitmap.recycle()
        }

        return processedBitmap
    }

    /**
     * Compresses a bitmap image while maintaining acceptable quality
     */
    fun compressImage(bitmap: Bitmap, quality: Int = COMPRESSION_QUALITY): Bitmap {
        require(quality in 0..100) { "Quality must be between 0 and 100" }
        require(!bitmap.isRecycled) { "Cannot compress recycled bitmap" }

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)
        val byteArray = stream.toByteArray()
        return BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)
    }

    /**
     * Saves a bitmap image to a file in the app's private storage
     */
    fun saveImageToFile(context: Context, bitmap: Bitmap, fileName: String): Uri {
        require(context.filesDir != null) { "Invalid application context" }
        require(!bitmap.isRecycled) { "Cannot save recycled bitmap" }

        val file = File(context.filesDir, "$fileName.$IMAGE_FILE_FORMAT")
        FileOutputStream(file).use { outputStream ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, COMPRESSION_QUALITY, outputStream)
            outputStream.flush()
        }

        return Uri.fromFile(file)
    }

    /**
     * Rotates a bitmap according to the image's EXIF orientation metadata
     */
    fun rotateBitmap(bitmap: Bitmap, orientation: Int): Bitmap {
        require(!bitmap.isRecycled) { "Cannot rotate recycled bitmap" }

        val matrix = Matrix()
        when (orientation) {
            android.media.ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            android.media.ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            android.media.ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            else -> return bitmap
        }

        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true
        )
    }

    /**
     * Calculates the optimal sample size for memory-efficient bitmap decoding
     */
    fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int
    ): Int {
        require(reqWidth > 0 && reqHeight > 0) { "Invalid required dimensions" }

        val (height: Int, width: Int) = options.run { outHeight to outWidth }
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2

            while (halfHeight / inSampleSize >= reqHeight && 
                   halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }

        return inSampleSize
    }

    /**
     * Private helper function to calculate scale factor for image resizing
     */
    private fun calculateScaleFactor(width: Int, height: Int, maxSize: Int): Float {
        val maxDimension = maxOf(width, height)
        return if (maxDimension > maxSize) {
            maxSize.toFloat() / maxDimension
        } else {
            1.0f
        }
    }
}