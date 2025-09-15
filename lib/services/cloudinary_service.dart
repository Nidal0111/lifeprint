import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String cloudName = 'dpfhr81ee';
  static const String uploadPreset = 'lifeprint';
  static const String baseUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/upload';

  /// Upload any file (image, audio, video) to Cloudinary
  static Future<String?> uploadFile(File file) async {
    try {
      print('Starting Cloudinary upload...');

      // Read file bytes
      List<int> fileBytes = await file.readAsBytes();
      print('File size: ${fileBytes.length} bytes');

      // Determine file type and MIME type
      String fileExtension = _getFileExtension(file.path);
      String mimeType = _getMimeType(fileExtension);
      String resourceType = _getResourceType(fileExtension);

      print('File extension: $fileExtension');
      print('MIME type: $mimeType');
      print('Resource type: $resourceType');

      // Generate unique filename
      String fileName =
          '${_getFilePrefix(resourceType)}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // Prepare the request
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'lifeprint_$resourceType';
      request.fields['public_id'] = fileName;
      request.fields['resource_type'] = resourceType;

      // Add the file with proper MIME type
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      print('Sending request to Cloudinary...');
      print('Upload URL: $baseUrl');
      print('Cloud name: $cloudName');
      print('Upload preset: $uploadPreset');
      print('Resource type: $resourceType');

      var response = await request.send();
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        print('Upload successful! Response: $responseData');

        var jsonResponse = json.decode(responseData);
        String? secureUrl = jsonResponse['secure_url'] as String?;

        if (secureUrl != null) {
          print('Secure URL: $secureUrl');
          return secureUrl;
        } else {
          print('No secure URL in response');
          return null;
        }
      } else {
        print('Upload failed with status: ${response.statusCode}');
        var errorData = await response.stream.bytesToString();
        print('Error response: $errorData');
        return null;
      }
    } catch (e) {
      print('Error uploading file to Cloudinary: $e');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Upload file with specific transformations (for images)
  static Future<String?> uploadFileWithTransformations(
    File file, {
    int? width,
    int? height,
    String? crop,
    String? gravity,
    String? quality,
    String? format,
  }) async {
    try {
      print('Starting Cloudinary upload with transformations...');

      List<int> fileBytes = await file.readAsBytes();
      String fileExtension = _getFileExtension(file.path);
      String resourceType = _getResourceType(fileExtension);

      // Only apply transformations for images
      if (resourceType != 'image') {
        print(
          'Transformations only supported for images, using regular upload',
        );
        return await uploadFile(file);
      }

      String fileName =
          'image_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'lifeprint_images';
      request.fields['public_id'] = fileName;
      request.fields['resource_type'] = 'image';

      // Add transformation parameters
      if (width != null) request.fields['width'] = width.toString();
      if (height != null) request.fields['height'] = height.toString();
      if (crop != null) request.fields['crop'] = crop;
      if (gravity != null) request.fields['gravity'] = gravity;
      if (quality != null) request.fields['quality'] = quality;
      if (format != null) request.fields['format'] = format;

      print(
        'Transformations: width=$width, height=$height, crop=$crop, gravity=$gravity, quality=$quality, format=$format',
      );

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      var response = await request.send();
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        print('Upload successful! Response: $responseData');
        var jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'] as String?;
      } else {
        print('Upload failed with status: ${response.statusCode}');
        var errorData = await response.stream.bytesToString();
        print('Error response: $errorData');
        return null;
      }
    } catch (e) {
      print('Error uploading file with transformations: $e');
      return null;
    }
  }

  /// Get file extension from file path
  static String _getFileExtension(String filePath) {
    if (filePath.contains('.')) {
      return filePath.split('.').last.toLowerCase();
    }
    return 'bin';
  }

  /// Get MIME type based on file extension
  static String _getMimeType(String extension) {
    switch (extension) {
      // Image types
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      case 'tiff':
      case 'tif':
        return 'image/tiff';

      // Video types
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'flv':
        return 'video/x-flv';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case '3gp':
        return 'video/3gpp';
      case 'm4v':
        return 'video/x-m4v';

      // Audio types
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'm4a':
        return 'audio/mp4';
      case 'wma':
        return 'audio/x-ms-wma';
      case 'aiff':
        return 'audio/aiff';

      default:
        return 'application/octet-stream';
    }
  }

  /// Get Cloudinary resource type based on file extension
  static String _getResourceType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'svg':
      case 'tiff':
      case 'tif':
        return 'image';

      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case 'mkv':
      case '3gp':
      case 'm4v':
        return 'video';

      case 'mp3':
      case 'wav':
      case 'aac':
      case 'ogg':
      case 'flac':
      case 'm4a':
      case 'wma':
      case 'aiff':
        return 'video'; // Cloudinary treats audio as video resource type

      default:
        return 'raw';
    }
  }

  /// Get file prefix based on resource type
  static String _getFilePrefix(String resourceType) {
    switch (resourceType) {
      case 'image':
        return 'img';
      case 'video':
        return 'vid';
      case 'raw':
        return 'file';
      default:
        return 'file';
    }
  }

  /// Get optimized URL with transformations
  static String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String? crop,
    String? quality,
    String? format,
  }) {
    if (originalUrl.contains('cloudinary.com')) {
      // Extract the public ID from the URL
      Uri uri = Uri.parse(originalUrl);
      String path = uri.path;
      String publicId = path.split('/').last.split('.').first;

      // Build transformation string
      String transformations = '';
      if (width != null) transformations += 'w_$width,';
      if (height != null) transformations += 'h_$height,';
      if (crop != null) transformations += 'c_$crop,';
      if (quality != null) transformations += 'q_$quality,';
      if (format != null) transformations += 'f_$format,';

      // Remove trailing comma
      if (transformations.endsWith(',')) {
        transformations = transformations.substring(
          0,
          transformations.length - 1,
        );
      }

      // Return optimized URL with transformations
      return 'https://res.cloudinary.com/$cloudName/image/upload/$transformations/$publicId';
    }
    return originalUrl;
  }

  /// Test Cloudinary connection
  static Future<bool> testConnection() async {
    try {
      print('Testing Cloudinary connection...');
      print('Cloud name: $cloudName');
      print('Upload preset: $uploadPreset');
      print('Base URL: $baseUrl');

      var response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload_presets'),
      );

      print('Connection test response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Cloudinary connection successful!');
        return true;
      } else {
        print('Cloudinary connection failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Cloudinary connection test failed: $e');
      return false;
    }
  }

  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Validate file before upload
  static Map<String, dynamic> validateFile(File file) {
    String extension = _getFileExtension(file.path);
    String resourceType = _getResourceType(extension);
    String mimeType = _getMimeType(extension);

    return {
      'isValid': resourceType != 'raw',
      'extension': extension,
      'resourceType': resourceType,
      'mimeType': mimeType,
      'supported': ['image', 'video'].contains(resourceType),
    };
  }
}
