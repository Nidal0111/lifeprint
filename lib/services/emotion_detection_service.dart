import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmotionDetectionService {
  static const String _baseUrl = 'https://lifeprint.onrender.com';

  /// Detect emotions from an image
  Future<List<String>> detectEmotions(dynamic imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/predict');

      final request = http.MultipartRequest('POST', uri);

      // ✅ REQUIRED HEADERS FOR FLUTTER WEB
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // -------- IMAGE HANDLING --------
      if (kIsWeb) {
        if (imageFile is Uint8List) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageFile,
              filename: 'image.jpg',
              contentType: http_parser.MediaType('image', 'jpeg'),
            ),
          );
        } else {
          throw Exception('Web platform expects Uint8List image');
        }
      } else {
        if (imageFile is File) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
            ),
          );
        } else {
          throw Exception('Mobile/Desktop expects File image');
        }
      }

      // -------- SEND REQUEST --------
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final decoded = json.decode(responseBody);
        return _extractEmotionsFromResponse(decoded);
      } else {
        debugPrint(
          'Emotion API failed: ${streamedResponse.statusCode} → $responseBody',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Emotion detection error: $e');
      return [];
    }
  }

  /// Extract emotion labels safely
  List<String> _extractEmotionsFromResponse(dynamic jsonData) {
    final List<String> emotions = [];

    // Case 1: Face detected (list response)
    if (jsonData is List) {
      for (final item in jsonData) {
        if (item is Map && item.containsKey('emotion')) {
          emotions.add(item['emotion'].toString());
        }
      }
    }

    // Case 2: No face detected / message response
    else if (jsonData is Map && jsonData.containsKey('message')) {
      debugPrint('Emotion API message: ${jsonData['message']}');
    }

    return emotions;
  }
}
