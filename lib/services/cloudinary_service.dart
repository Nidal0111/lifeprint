import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String cloudName = 'dpfhr81ee';
  static const String uploadPreset = 'lifeprint';

  static const String imageUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static Future<String> uploadImage({
    File? file, // Android / iOS
    Uint8List? bytes, // Web
    String? fileName,
  }) async {
    if (file == null && bytes == null) {
      throw Exception('No file or bytes provided for upload');
    }

    final uri = Uri.parse(imageUploadUrl);
    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;

    request.fields['public_id'] =
        'lifeprint_image/img_${DateTime.now().millisecondsSinceEpoch}';

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );
    } else {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes!,
          filename: fileName ?? 'image.jpg',
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return data['secure_url']; 
    } else {
      throw Exception(
        'Cloudinary upload failed: ${data['error'] ?? response.statusCode}',
      );
    }
  }

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
      final extension = _getFileExtension(file.path);
      final resourceType = _getResourceType(extension);

      if (resourceType != 'image') {
        return await uploadImage(file: file);
      }

      final uri = Uri.parse(imageUploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;
      request.fields['resource_type'] = 'image';
      request.fields['public_id'] =
          'lifeprint_image/img_${DateTime.now().millisecondsSinceEpoch}';

      if (width != null) request.fields['width'] = width.toString();
      if (height != null) request.fields['height'] = height.toString();
      if (crop != null) request.fields['crop'] = crop;
      if (gravity != null) request.fields['gravity'] = gravity;
      if (quality != null) request.fields['quality'] = quality;
      if (format != null) request.fields['format'] = format;

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (response.statusCode == 200) {
        return data['secure_url'];
      }
      return null;
    } catch (e) {
      debugPrint('Cloudinary transform upload error: $e');
      return null;
    }
  }

  static bool get isWeb => kIsWeb;

  static String _getFileExtension(String path) {
    return path.contains('.') ? path.split('.').last.toLowerCase() : 'bin';
  }

  static String _getResourceType(String extension) {
    const imageExt = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
      'tiff',
      'tif'
    ];
    const videoExt = [
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'webm',
      'mkv',
      '3gp',
      'm4v'
    ];
    const audioExt = ['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a', 'wma', 'aiff'];

    if (imageExt.contains(extension)) return 'image';
    if (videoExt.contains(extension)) return 'video';
    if (audioExt.contains(extension)) return 'video'; // Cloudinary rule
    return 'raw';
  }

  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
