import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lifeprint/app_secrets.dart';

class EmotionDetectionService {
 
  static const String _groqApiKey = AppSecrets.groqApiKey;
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqVisionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  Future<List<String>> detectEmotions(
    dynamic imageFile, {
    String? fileName,
  }) async {
    try {
      Uint8List imageBytes;
      if (kIsWeb) {
        if (imageFile is Uint8List) {
          imageBytes = imageFile;
        } else {
          throw Exception('Web platform expects Uint8List image');
        }
      } else {
        if (imageFile is File) {
          imageBytes = await imageFile.readAsBytes();
        } else {
          throw Exception('Mobile/Desktop expects File image');
        }
      }

      final base64Image = base64Encode(imageBytes);

      final resp = await http.post(
        Uri.parse(_groqBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': _groqVisionModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
                {
                  'type': 'text',
                  'text': 'Identify the primary emotion shown in this image. Return ONLY a single word (e.g. Happy, Sad, Neutral, Angry, Surprise, Fear, Disgust, Joy, Love, Pride, Excitement). If multiple people, identify the dominant mood.',
                },
              ],
            },
          ],
          'max_tokens': 10,
        }),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final content = body['choices'][0]['message']['content'] as String;
        // Clean up the response (Groq might still add some text)
        final emotion = content.split(RegExp(r'\W+')).firstWhere((s) => s.isNotEmpty, orElse: () => 'Neutral');
        return [_normalizeEmotion(emotion)];
      } else {
        debugPrint('Groq Vision API failed: ${resp.statusCode} -> ${resp.body}');
        return ['Neutral'];
      }
    } catch (e) {
      debugPrint('Emotion detection error: $e');
      return ['Neutral'];
    }
  }

  String _normalizeEmotion(String e) {
    if (e.isEmpty) return 'Neutral';
    return e[0].toUpperCase() + e.substring(1).toLowerCase();
  }
}
