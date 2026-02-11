import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

class EmotionDetectionService {
  // 🚀 LOCAL NETWORK CONFIGURATION
  // 1. Ensure phone and laptop are on the SAME Wi-Fi.
  // 2. Python server host must be '0.0.0.0'.
  static const String _baseUrl =
      'https://facial-expressions-recognition-master-4.onrender.com';

  Future<List<String>> detectEmotions(
    dynamic imageFile, {
    String? fileName,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/predict-emotion/');

      final request = http.MultipartRequest('POST', uri);

      // ✅ REQUIRED HEADERS FOR FLUTTER WEB
      request.headers.addAll({'Accept': 'application/json'});

      // -------- IMAGE HANDLING --------
      if (kIsWeb) {
        if (imageFile is Uint8List) {
          final String fname = fileName ?? 'image.jpg';
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              imageFile,
              filename: fname,
              contentType: _getMediaType(fname),
            ),
          );
        } else {
          throw Exception('Web platform expects Uint8List image');
        }
      } else {
        if (imageFile is File) {
          request.files.add(
            await http.MultipartFile.fromPath('file', imageFile.path),
          );
        } else {
          throw Exception('Mobile/Desktop expects File image');
        }
      }

      // ✅ ADD NGROK BYPASS HEADER
      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      });

      // -------- SEND REQUEST --------
      final streamedResponse = await request.send().timeout(
        // Increased timeout for Render Free Tier Cold Starts (can take >50s)
        const Duration(seconds: 90),
      );

      final responseBody = await streamedResponse.stream.bytesToString();

      // 🔍 ENHANCED DEBUG LOGGING
      debugPrint('=== EMOTION API DEBUG ===');
      debugPrint('Status Code: ${streamedResponse.statusCode}');
      debugPrint('Response Body: $responseBody');
      debugPrint('Response Headers: ${streamedResponse.headers}');
      debugPrint('========================');

      if (streamedResponse.statusCode == 200) {
        final decoded = json.decode(responseBody);
        debugPrint('Decoded JSON: $decoded');

        // Check for error in response
        if (decoded is Map && decoded.containsKey('error')) {
          debugPrint('API returned error: ${decoded['error']}');
          return []; // No face detected
        }

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

  /// Extract emotion labels safely (Handles multiple Python API formats)
  List<String> _extractEmotionsFromResponse(dynamic jsonData) {
    List<String> emotions = [];

    // Format for current FastAPI app.py: {"emotion": "Happy", "confidence": 0.95}
    if (jsonData is Map) {
      if (jsonData.containsKey('emotion')) {
        emotions.add(jsonData['emotion'].toString());
      }
      // Format B: Map with key {"emotions": ["happy", "sad"]}
      else if (jsonData.containsKey('emotions') &&
          jsonData['emotions'] is List) {
        emotions.addAll(List<String>.from(jsonData['emotions']));
      }
      // Format D: Map with prediction key {"prediction": "happy"}
      else if (jsonData.containsKey('prediction')) {
        emotions.add(jsonData['prediction'].toString());
      }
    }
    // Format A: List of objects (DeepFace style) [{"emotion": "happy"}, ...]
    else if (jsonData is List) {
      for (var item in jsonData) {
        if (item is Map && item.containsKey('emotion')) {
          emotions.add(item['emotion'].toString());
        } else if (item is String) {
          emotions.add(item);
        }
      }
    }

    // Fallback: If nothing was found
    if (emotions.isEmpty) {
      debugPrint('No emotions found in JSON, returning Neutral');
      emotions.add('Neutral');
    }

    // Normalize to Capital Case (e.g., happy -> Happy)
    return emotions
        .map((e) {
          if (e.isEmpty) return 'Neutral';
          return e[0].toUpperCase() + e.substring(1).toLowerCase();
        })
        .toSet()
        .toList();
  }

  http_parser.MediaType _getMediaType(String filename) {
    String ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return http_parser.MediaType('image', 'png');
      case 'webp':
        return http_parser.MediaType('image', 'webp');
      case 'gif':
        return http_parser.MediaType('image', 'gif');
      default:
        return http_parser.MediaType('image', 'jpeg');
    }
  }
}
