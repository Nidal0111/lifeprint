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
  static const String _baseUrl = 'http://192.168.1.34:5000'; 

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

      // ✅ ADD NGROK BYPASS HEADER
      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      });

      // -------- SEND REQUEST --------
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final responseBody = await streamedResponse.stream.bytesToString();
      debugPrint('Emotion API Response: $responseBody'); // 🔍 DEBUG LOG

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

  /// Extract emotion labels safely (Handles multiple Python API formats)
  List<String> _extractEmotionsFromResponse(dynamic jsonData) {
    List<String> emotions = [];

    // Format A: List of objects (DeepFace style) [{"emotion": "happy"}, ...]
    if (jsonData is List) {
      for (var item in jsonData) {
        if (item is Map && item.containsKey('emotion')) {
          emotions.add(item['emotion'].toString());
        } else if (item is String) {
          emotions.add(item);
        }
      }
    }

    // Format B: Map with key {"emotions": ["happy", "sad"]}
    else if (jsonData is Map) {
      if (jsonData.containsKey('emotions') && jsonData['emotions'] is List) {
        emotions.addAll(List<String>.from(jsonData['emotions']));
      } 
      // Format C: Map with single key {"emotion": "happy"}
      else if (jsonData.containsKey('emotion')) {
        emotions.add(jsonData['emotion'].toString());
      }
      // Format D: Map with prediction key {"prediction": "happy"}
      else if (jsonData.containsKey('prediction')) {
        emotions.add(jsonData['prediction'].toString());
      }
    }

    // Fallback: If nothing was found
    if (emotions.isEmpty) {
      debugPrint('No emotions found in JSON, returning Neutral');
      emotions.add('Neutral');
    }

    // Normalize to Capital Case (e.g., happy -> Happy)
    return emotions.map((e) {
      if (e.isEmpty) return 'Neutral';
      return e[0].toUpperCase() + e.substring(1).toLowerCase();
    }).toSet().toList();
  }
}
