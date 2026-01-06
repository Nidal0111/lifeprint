import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmotionDetectionService {
  static const String _baseUrl = 'https://lifeprint.onrender.com';
  
  Future<List<String>> detectEmotions(dynamic imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/predict');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);
      
      // Add image file to request
      if (kIsWeb) {
        // Web platform - imageFile is Uint8List
        if (imageFile is Uint8List) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageFile,
              filename: 'image.jpg',
            ),
          );
        } else {
          throw Exception('Invalid image data for web platform');
        }
      } else {
        // Mobile/Desktop platform - imageFile is File
        if (imageFile is File) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
            ),
          );
        } else {
          throw Exception('Invalid image file');
        }
      }
      
      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        
        // Extract emotions from response
        List<String> emotions = _extractEmotionsFromResponse(jsonData);
        return emotions;
      } else {
        throw Exception('Emotion detection failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detecting emotions: $e');
      // Return empty list on error to prevent blocking the upload process
      return [];
    }
  }
  
  /// Extract emotions from API response
  List<String> _extractEmotionsFromResponse(dynamic jsonData) {
    List<String> emotions = [];
    
    try {
      // Handle different possible response formats
      if (jsonData is Map) {
        // Check for 'emotions' key
        if (jsonData['emotions'] != null) {
          final emotionsData = jsonData['emotions'];
          if (emotionsData is List) {
            emotions = emotionsData.cast<String>();
          } else if (emotionsData is Map) {
            // If emotions are in a map with scores, extract keys
            emotions = emotionsData.keys.cast<String>().toList();
          }
        }
        // Check for 'predicted_emotions' key
        else if (jsonData['predicted_emotions'] != null) {
          final predictedEmotions = jsonData['predicted_emotions'];
          if (predictedEmotions is List) {
            emotions = predictedEmotions.cast<String>();
          }
        }
        // Check for 'top_emotions' key
        else if (jsonData['top_emotions'] != null) {
          final topEmotions = jsonData['top_emotions'];
          if (topEmotions is List) {
            emotions = topEmotions.cast<String>();
          }
        }
        // Check for direct string result
        else if (jsonData['emotion'] != null) {
          emotions = [jsonData['emotion'].toString()];
        } else if (jsonData['result'] != null) {
          emotions = [jsonData['result'].toString()];
        }
      } else if (jsonData is List) {
        // If response is a list of results (e.g., [{"emotion": "Happy", "confidence": 0.5}])
        for (var item in jsonData) {
          if (item is Map && item.containsKey('emotion')) {
            emotions.add(item['emotion'].toString());
          } else if (item is String) {
            emotions.add(item);
          }
        }
      }
    } catch (e) {
      print('Error parsing emotion response: $e');
    }
    
    // Clean up emotions - remove empty strings and normalize
    emotions = emotions
        .where((emotion) => emotion.isNotEmpty)
        .map((emotion) => _normalizeEmotion(emotion))
        .toSet() // Remove duplicates
        .toList();
    
    // If no emotions detected, return a default list
    if (emotions.isEmpty) {
      emotions = ['Neutral'];
    }
    
    return emotions;
  }
  
  /// Normalize emotion names to match the app's emotion list
  String _normalizeEmotion(String emotion) {
    final emotionLower = emotion.toLowerCase().trim();
    
    // Map common variations to standard emotions
    final emotionMap = {
      'happy': 'Joy',
      'joyful': 'Joy',
      'joy': 'Joy',
      'sad': 'Sadness',
      'sadness': 'Sadness',
      'angry': 'Anger',
      'anger': 'Anger',
      'disgusted': 'Disgust',
      'disgust': 'Disgust',
      'fearful': 'Fear',
      'fear': 'Fear',
      'surprised': 'Surprise',
      'surprise': 'Surprise',
      'neutral': 'Neutral',
      'calm': 'Peace',
      'peaceful': 'Peace',
      'peace': 'Peace',
      'excited': 'Excitement',
      'excitement': 'Excitement',
      'love': 'Love',
      'loving': 'Love',
      'nostalgic': 'Nostalgia',
      'nostalgia': 'Nostalgia',
      'grateful': 'Gratitude',
      'gratitude': 'Gratitude',
      'adventurous': 'Adventure',
      'adventure': 'Adventure',
      'proud': 'Pride',
      'pride': 'Pride',
      'hopeful': 'Hope',
      'hope': 'Hope',
      'wonder': 'Wonder',
      'wonderful': 'Wonder',
      'celebration': 'Celebration',
      'celebrate': 'Celebration',
      'energetic': 'Energy',
      'energy': 'Energy',
      'reflective': 'Reflection',
      'reflection': 'Reflection',
      'romantic': 'Romance',
      'romance': 'Romance',
      'friendship': 'Friendship',
      'family': 'Family',
      'achievement': 'Achievement',
      'accomplished': 'Achievement',
    };
    
    return emotionMap[emotionLower] ?? emotion;
  }
  
  /// Check if the emotion detection service is available
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Emotion detection service not available: $e');
      return false;
    }
  }
  
  /// Test the emotion detection service with a sample image
  Future<String> testService() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/test'),
      );
      if (response.statusCode == 200) {
        return 'Emotion detection service is working!';
      } else {
        return 'Service returned status: ${response.statusCode}';
      }
    } catch (e) {
      return 'Service connection failed: $e';
    }
  }
}
