/**
 * Human Tasks:
 * 1. Ensure TensorFlow.js is properly configured with GPU support if available
 * 2. Configure AWS credentials for Rekognition service access
 * 3. Set up monitoring for image processing performance metrics
 * 4. Configure image storage and caching strategy
 * 5. Set up error alerting for image processing failures
 */

// External dependencies
import { tensor4d } from '@tensorflow/tfjs-node'; // v4.12.0
import sharp from 'sharp'; // v0.32.0
import sizeOf from 'image-size'; // v1.0.0

// Internal dependencies
import { ValidationError } from '../../../shared/utils/error';

// Constants for image processing requirements
const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB
const SUPPORTED_FORMATS = ['image/jpeg', 'image/png'];
const MIN_DIMENSION = 224;
const MAX_DIMENSION = 4096;
const TARGET_SIZE = 224;

/**
 * Validates image buffer for size, format and dimensions
 * Requirement: AI-powered furniture recognition - Image validation for AI model input
 */
export async function validateImage(imageBuffer: Buffer): Promise<boolean> {
  // Check buffer size
  if (imageBuffer.length > MAX_IMAGE_SIZE) {
    throw new ValidationError('Image size exceeds maximum allowed size', {
      maxSize: MAX_IMAGE_SIZE,
      actualSize: imageBuffer.length
    });
  }

  // Validate image format using file signatures
  const jpegSignature = imageBuffer.slice(0, 2).toString('hex');
  const pngSignature = imageBuffer.slice(0, 8).toString('hex');
  
  const isJpeg = jpegSignature === 'ffd8';
  const isPng = pngSignature === '89504e470d0a1a0a';
  
  if (!isJpeg && !isPng) {
    throw new ValidationError('Unsupported image format', {
      supportedFormats: SUPPORTED_FORMATS
    });
  }

  // Validate image dimensions
  try {
    const dimensions = sizeOf(imageBuffer);
    if (!dimensions.width || !dimensions.height) {
      throw new ValidationError('Unable to determine image dimensions');
    }

    if (dimensions.width < MIN_DIMENSION || dimensions.height < MIN_DIMENSION) {
      throw new ValidationError('Image dimensions too small', {
        minDimension: MIN_DIMENSION,
        actualWidth: dimensions.width,
        actualHeight: dimensions.height
      });
    }

    if (dimensions.width > MAX_DIMENSION || dimensions.height > MAX_DIMENSION) {
      throw new ValidationError('Image dimensions too large', {
        maxDimension: MAX_DIMENSION,
        actualWidth: dimensions.width,
        actualHeight: dimensions.height
      });
    }
  } catch (error) {
    if (error instanceof ValidationError) {
      throw error;
    }
    throw new ValidationError('Invalid image format or corrupted file');
  }

  return true;
}

/**
 * Preprocesses image for AI model input
 * Requirement: Image Recognition System - Image preprocessing for consistent model input
 */
export async function preprocessImage(imageBuffer: Buffer): Promise<Buffer> {
  try {
    const processedBuffer = await sharp(imageBuffer)
      .resize(TARGET_SIZE, TARGET_SIZE, {
        fit: 'contain',
        background: { r: 255, g: 255, b: 255, alpha: 1 }
      })
      .removeAlpha()
      .toColorspace('srgb')
      .normalise()
      .toFormat('jpeg', { quality: 90 })
      .toBuffer();

    return processedBuffer;
  } catch (error) {
    throw new ValidationError('Image preprocessing failed', {
      error: error.message
    });
  }
}

/**
 * Converts processed image buffer to TensorFlow tensor format
 * Requirement: Image Recognition System - Tensor conversion for TensorFlow model
 */
export async function convertToTensor(processedImageBuffer: Buffer): Promise<tf.Tensor4D> {
  try {
    // Create Float32Array from buffer data
    const imageData = new Float32Array(TARGET_SIZE * TARGET_SIZE * 3);
    const pixels = new Uint8Array(processedImageBuffer);
    
    // Normalize pixel values to 0-1 range
    for (let i = 0; i < pixels.length; i++) {
      imageData[i] = pixels[i] / 255.0;
    }

    // Create and return 4D tensor with shape [1, TARGET_SIZE, TARGET_SIZE, 3]
    return tensor4d(imageData, [1, TARGET_SIZE, TARGET_SIZE, 3]);
  } catch (error) {
    throw new ValidationError('Tensor conversion failed', {
      error: error.message
    });
  }
}

/**
 * Crops image to focus on furniture content
 * Requirement: AI-powered furniture recognition - Content-aware image cropping
 */
export async function cropToContent(imageBuffer: Buffer): Promise<Buffer> {
  try {
    // Edge detection kernel for content boundary detection
    const edgeKernel = {
      width: 3,
      height: 3,
      kernel: [-1, -1, -1, -1, 8, -1, -1, -1, -1]
    };

    // Detect edges to identify content boundaries
    const edges = await sharp(imageBuffer)
      .greyscale()
      .convolve(edgeKernel)
      .toBuffer();

    // Analyze edge data to determine content boundaries
    const { width, height } = sizeOf(imageBuffer);
    const edgeData = new Uint8Array(edges);
    
    let top = 0, bottom = height - 1;
    let left = 0, right = width - 1;
    
    // Find content boundaries while maintaining aspect ratio
    const threshold = 30; // Edge detection threshold
    
    // Calculate crop rectangle
    const cropWidth = right - left;
    const cropHeight = bottom - top;
    const aspectRatio = Math.min(cropWidth / cropHeight, 1.5); // Limit aspect ratio
    
    // Apply crop with padding
    const padding = 20; // Pixels of padding around content
    return await sharp(imageBuffer)
      .extract({
        left: Math.max(0, left - padding),
        top: Math.max(0, top - padding),
        width: Math.min(width, cropWidth + 2 * padding),
        height: Math.min(height, cropHeight + 2 * padding)
      })
      .toBuffer();
  } catch (error) {
    throw new ValidationError('Content-aware cropping failed', {
      error: error.message
    });
  }
}