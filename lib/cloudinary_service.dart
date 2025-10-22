import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dpfhr81ee';
  static const String uploadPreset = 'lifeprint';
  static const String baseUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Upload image to Cloudinary
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      // Convert file to bytes
      List<int> imageBytes = await imageFile.readAsBytes();

      // Prepare the request
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] =
          'lifeprint_profiles'; // Optional: organize in folder

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        // Return the secure URL of the uploaded image
        return jsonResponse['secure_url'] as String?;
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  /// Upload image with additional transformations
  static Future<String?> uploadImageWithTransformations(
    XFile imageFile, {
    int? width,
    int? height,
    String? crop,
    String? gravity,
  }) async {
    try {
      print('Starting Cloudinary upload with transformations...');
      List<int> imageBytes = await imageFile.readAsBytes();
      print('Image size: ${imageBytes.length} bytes');

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'lifeprint_profiles';

      // Add transformation parameters
      if (width != null) request.fields['width'] = width.toString();
      if (height != null) request.fields['height'] = height.toString();
      if (crop != null) request.fields['crop'] = crop;
      if (gravity != null) request.fields['gravity'] = gravity;

      print(
        'Transformations: width=$width, height=$height, crop=$crop, gravity=$gravity',
      );

      // Determine file extension
      String fileExtension = 'jpg';
      String filePath = imageFile.path.toLowerCase();
      if (filePath.contains('.')) {
        fileExtension = filePath.split('.').last;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename:
              'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
        ),
      );

      print('Sending request to Cloudinary...');
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
      print('Error uploading image to Cloudinary: $e');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Upload image with web-specific optimizations
  static Future<String?> uploadImageWebOptimized(XFile imageFile) async {
    try {
      print('Starting Cloudinary upload...');
      List<int> imageBytes = await imageFile.readAsBytes();
      print('Image size: ${imageBytes.length} bytes');

      // Generate unique filename with original extension
      String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      String fileExtension = 'jpg'; // Default to jpg

      // Try to determine file extension from the file path
      String filePath = imageFile.path.toLowerCase();
      if (filePath.contains('.')) {
        fileExtension = filePath.split('.').last;
      }

      print('Upload URL: $baseUrl');
      print('Cloud name: $cloudName');
      print('Upload preset: $uploadPreset');

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'lifeprint_profiles';
      request.fields['public_id'] = fileName;

      // Add the image file with proper content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: '$fileName.$fileExtension',
        ),
      );

      print('Sending request to Cloudinary...');
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
      print('Error uploading image to Cloudinary: $e');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Get optimized profile picture URL with transformations
  static String getOptimizedProfileUrl(String originalUrl, {int size = 200}) {
    if (originalUrl.contains('cloudinary.com')) {
      // Extract the public ID from the URL
      Uri uri = Uri.parse(originalUrl);
      String path = uri.path;
      String publicId = path.split('/').last.split('.').first;

      // Return optimized URL with transformations
      return 'https://res.cloudinary.com/$cloudName/image/upload/w_$size,h_$size,c_fill,g_face,r_max,f_auto,q_auto/$publicId';
    }
    return originalUrl;
  }

  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Test Cloudinary connection and upload preset
  static Future<bool> testConnection() async {
    try {
      print('Testing Cloudinary connection...');
      print('Cloud name: $cloudName');
      print('Upload preset: $uploadPreset');
      print('Base URL: $baseUrl');

      // Test with a simple request
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

  /// Fallback upload method without transformations
  static Future<String?> uploadImageSimple(XFile imageFile, String name) async {
    try {
      print('Using fallback upload method...');
      List<int> imageBytes = await imageFile.readAsBytes();
      print('Image size: ${imageBytes.length} bytes');

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['upload_preset'] = uploadPreset;

      // Determine file extension
      String fileExtension = 'jpg';
      String filePath = imageFile.path.toLowerCase();
      if (filePath.contains('.')) {
        fileExtension = filePath.split('.').last;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename:
              'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
        ),
      );

      print('Sending fallback request to Cloudinary...');
      var response = await request.send();
      print('Fallback response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        print('Fallback upload successful! Response: $responseData');
        var jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'] as String?;
      } else {
        print('Fallback upload failed with status: ${response.statusCode}');
        var errorData = await response.stream.bytesToString();
        print('Fallback error response: $errorData');
        return null;
      }
    } catch (e) {
      print('Fallback upload error: $e');
      return null;
    }
  }
}
