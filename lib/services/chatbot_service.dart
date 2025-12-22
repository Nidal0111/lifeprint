import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeprint/models/memory_model.dart';
import 'package:lifeprint/models/event_model.dart';
import 'package:lifeprint/models/family_member_model.dart';
import 'package:lifeprint/services/memory_service.dart';
import 'package:lifeprint/services/event_service.dart';
import 'package:lifeprint/services/family_tree_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ChatbotService {
  final MemoryService _memoryService = MemoryService();
  final EventService _eventService = EventService();
  final FamilyTreeService _familyTreeService = FamilyTreeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Process user message and generate appropriate response
  Future<String> processMessage(String userMessage) async {
    if (currentUserId == null) {
      return "I need you to be logged in to help you with your memories and family data.";
    }

    final message = userMessage.toLowerCase().trim();

    // Greeting responses
    if (_containsAny(message, [
      'hello',
      'hi',
      'hey',
      'good morning',
      'good afternoon',
      'good evening',
    ])) {
      return "Hi again! Feel free to ask me about your memories, family connections, or say 'help' to see what I can do.";
    }

    // Help responses
    if (_containsAny(message, [
      'help',
      'what can you do',
      'commands',
      'options',
    ])) {
      return "I can help you with:\n\n"
          "📷 **Memories**: Ask about your photos, videos, audio, or text memories\n"
          "👨‍👩‍👧‍👦 **Family**: Questions about your family members and relationships\n"
          "� **Events**: Ask about your events, appointments, and schedule\n"
          "�📊 **Stats**: Get statistics about your memories and family\n"
          "🔍 **Search**: Find specific memories or family members\n"
          "💡 **Suggestions**: Get recommendations for organizing your data\n\n"
          "Try asking: 'Show me my recent memories', 'Who are my family members?', or 'What events do I have today?'";
    }

    // Memory-related queries
    if (_containsAny(message, [
      'memory',
      'memories',
      'photo',
      'video',
      'audio',
      'picture',
      'image',
    ])) {
      return await _handleMemoryQuery(message);
    }

    // Family-related queries
    if (_containsAny(message, [
      'family',
      'relative',
      'parent',
      'child',
      'spouse',
      'sibling',
      'brother',
      'sister',
      'mother',
      'father',
    ])) {
      return await _handleFamilyQuery(message);
    }

    // Statistics queries
    if (_containsAny(message, [
      'stats',
      'statistics',
      'count',
      'how many',
      'total',
    ])) {
      return await _handleStatsQuery(message);
    }

    // Event-related queries
    if (_containsAny(message, [
      'event',
      'events',
      'appointment',
      'meeting',
      'birthday',
      'calendar',
      'schedule',
    ])) {
      return await _handleEventQuery(message);
    }

    // Search queries
    if (_containsAny(message, ['find', 'search', 'look for', 'show me'])) {
      return await _handleSearchQuery(message);
    }

    // Default response: if nothing matched above, send the query + serialized memories to Gemini
    String result = await _queryWithGemini(userMessage);

    // Post-process the result: if it includes an offer to open a memory and a quoted title,
    // return a JSON wrapper containing both the text and the machine-readable title so UI
    // can act on it. Otherwise return plain text.
    try {
      final match = RegExp(r'"([^\"]+)"').firstMatch(result);
      String? openTitle;
      if (match != null &&
          RegExp(r'open', caseSensitive: false).hasMatch(result)) {
        openTitle = match.group(1);
      }

      if (openTitle != null && openTitle.isNotEmpty) {
        return jsonEncode({'text': result, 'openMemoryTitle': openTitle});
      }
    } catch (_) {
      // ignore
    }

    return result;
  }

  /// Serialize memories and call the Gemini model to get a personalized reply.
  Future<String> _queryWithGemini(String userQuery) async {
    try {
      final memories = await _memoryService.getAllMemories(currentUserId!);

      // Limit number of memories sent to the model
      final limit = 20;
      final recent = memories.take(limit).toList();

      final serializedLines = recent
          .map((m) {
            return jsonEncode({
              'id': m.id,
              'title': m.title,
              'type': m.type.name,
              'emotions': m.emotions,
              'createdAt': m.createdAt.toIso8601String(),
            });
          })
          .join('\n');

      // Truncate to conservative prompt size
      final maxPromptLength = 12000;
      var memoryBlock = serializedLines;
      if (memoryBlock.length > maxPromptLength) {
        memoryBlock = memoryBlock.substring(0, maxPromptLength - 100) + '\n...';
      }

      final prompt =
          '''You are a human-like memory assistant.
Here are the user's saved memories (JSON lines):

$memoryBlock

User asked: "${_escape(userQuery)}"

Search deeply in their life memories and answer personally.

If memory found -> reply like an old friend with summary:
- Mention memory title
- Say emotion (joyful, nostalgic)
- Offer help: "Want me to open that memory?"

If nothing found -> reply kindly:
"I didn’t find anything like that — should I search differently?"''';

      // Read endpoint and key from dart-define environment variables
      final geminiUrl = const String.fromEnvironment('GEMINI_API_URL');
      final geminiKey = const String.fromEnvironment('GEMINI_API_KEY');

      if (geminiUrl.isNotEmpty) {
        try {
          final resp = await http
              .post(
                Uri.parse(geminiUrl),
                headers: {
                  'Content-Type': 'application/json',
                  if (geminiKey.isNotEmpty)
                    'Authorization': 'Bearer $geminiKey',
                },
                body: jsonEncode({'prompt': prompt}),
              )
              .timeout(const Duration(seconds: 15));

          if (resp.statusCode == 200) {
            // Try parse JSON
            try {
              final body = jsonDecode(resp.body);
              if (body is Map<String, dynamic>) {
                final result =
                    body['result'] ??
                    body['text'] ??
                    body['response'] ??
                    body['output'];
                if (result is String && result.trim().isNotEmpty)
                  return result.trim();
              }
            } catch (_) {
              if (resp.body.trim().isNotEmpty) return resp.body.trim();
            }
          }
        } catch (e) {
          debugPrint('Error calling Gemini endpoint: $e');
          // fall through to local fallback
        }
      }

      // Local fallback: simple heuristic search
      final lowerQuery = userQuery.toLowerCase();
      final found = memories.where((m) {
        return m.title.toLowerCase().contains(lowerQuery) ||
            m.emotions.any((e) => e.toLowerCase().contains(lowerQuery));
      }).toList();

      if (found.isNotEmpty) {
        final mem = found.first;
        final emotion = mem.emotions.isNotEmpty
            ? mem.emotions.first
            : 'nostalgic';
        return 'I remember "${mem.title}" — it feels ${emotion.toLowerCase()}. Want me to open that memory?';
      }

      return 'I didn’t find anything like that — should I search differently?';
    } catch (e) {
      debugPrint('Gemini query failed: $e');
      return 'Sorry, I had trouble searching your memories. Try rephrasing your question.';
    }
  }

  String _escape(String s) => s.replaceAll('"', '\\"');

  /// Handle memory-related queries
  Future<String> _handleMemoryQuery(String message) async {
    try {
      final memories = await _memoryService.getAllMemories(currentUserId!);

      if (memories.isEmpty) {
        return "You don't have any memories yet! Try adding some photos, videos, or audio recordings to get started.";
      }

      // Recent memories
      if (_containsAny(message, ['recent', 'latest', 'new', 'last'])) {
        final recent = memories.take(5).toList();
        String response = "Here are your 5 most recent memories:\n\n";
        for (int i = 0; i < recent.length; i++) {
          final memory = recent[i];
          final daysAgo = DateTime.now().difference(memory.createdAt).inDays;
          response +=
              "${i + 1}. **${memory.title}** (${memory.type.displayName})\n";
          response +=
              "   Created ${daysAgo == 0 ? 'today' : '$daysAgo days ago'}\n";
          if (memory.emotions.isNotEmpty) {
            response += "   Emotions: ${memory.emotions.join(', ')}\n";
          }
          response += "\n";
        }
        return response;
      }

      // Memory types
      if (_containsAny(message, ['photo', 'picture', 'image'])) {
        final photos = memories
            .where((m) => m.type == MemoryType.photo)
            .toList();
        return "You have ${photos.length} photo memories. ${photos.isNotEmpty ? 'Your most recent photo is "${photos.first.title}"' : ''}";
      }

      if (_containsAny(message, ['video'])) {
        final videos = memories
            .where((m) => m.type == MemoryType.video)
            .toList();
        return "You have ${videos.length} video memories. ${videos.isNotEmpty ? 'Your most recent video is "${videos.first.title}"' : ''}";
      }

      if (_containsAny(message, ['audio', 'sound', 'music'])) {
        final audios = memories
            .where((m) => m.type == MemoryType.audio)
            .toList();
        return "You have ${audios.length} audio memories. ${audios.isNotEmpty ? 'Your most recent audio is "${audios.first.title}"' : ''}";
      }

      // Emotions
      final emotionKeywords = [
        'joy',
        'happy',
        'sad',
        'excited',
        'love',
        'gratitude',
        'peace',
        'adventure',
        'achievement',
        'family',
        'friendship',
        'romance',
        'hope',
        'pride',
        'wonder',
        'calm',
        'energy',
        'reflection',
        'celebration',
      ];
      for (final emotion in emotionKeywords) {
        if (message.contains(emotion)) {
          final emotionMemories = memories
              .where(
                (m) => m.emotions.any((e) => e.toLowerCase().contains(emotion)),
              )
              .toList();
          return "You have ${emotionMemories.length} memories tagged with '$emotion'. ${emotionMemories.isNotEmpty ? 'Your most recent $emotion memory is "${emotionMemories.first.title}"' : ''}";
        }
      }

      // General memory info
      final totalMemories = memories.length;
      final photoCount = memories
          .where((m) => m.type == MemoryType.photo)
          .length;
      final videoCount = memories
          .where((m) => m.type == MemoryType.video)
          .length;
      final audioCount = memories
          .where((m) => m.type == MemoryType.audio)
          .length;
      final textCount = memories.where((m) => m.type == MemoryType.text).length;

      return "You have $totalMemories total memories:\n\n"
          "📷 Photos: $photoCount\n"
          "🎥 Videos: $videoCount\n"
          "🎵 Audio: $audioCount\n"
          "📝 Text: $textCount\n\n"
          "Your most recent memory is \"${memories.first.title}\" (${memories.first.type.displayName})";
    } catch (e) {
      return "Sorry, I couldn't access your memories right now. Please try again later.";
    }
  }

  /// Handle family-related queries
  Future<String> _handleFamilyQuery(String message) async {
    try {
      final userId = currentUserId!;
      final familyMembers = await _familyTreeService.getFamilyTree(userId);
      final relationships = await _familyTreeService.getFamilyRelationships(userId);

      if (familyMembers.isEmpty && relationships.isEmpty) {
        return "You haven't added any family members yet! Building your family tree is an important part of your digital legacy. Try adding some family members through the Family Tree section.";
      }

      // Handle specific relationship queries
      if (_containsAny(message, ['who are my', 'list my', 'show my'])) {
        String response = "👨‍👩‍👧‍👦 **Your Family Members** (${familyMembers.length - 1} connected):\n\n";

        // Get relationships for the user
        final userRelationships = await _familyTreeService.getUserRelationships(userId);

        if (userRelationships.isEmpty) {
          response += "You haven't connected with any family members yet. Start building your family tree!";
        } else {
          for (int i = 0; i < userRelationships.length; i++) {
            final relationship = userRelationships[i];
            final relatedUser = familyMembers[relationship.toUserId];

            if (relatedUser != null) {
              final relationDisplay = RelationshipType.getDisplayName(relationship.relation);
              response += "${i + 1}. **${relatedUser.name}** (${relationDisplay})\n";
            }
          }
        }

        return response;
      }

      // Handle specific relationship types
      final relationTypes = {
        'parent': ['parent', 'parents', 'mother', 'father', 'mom', 'dad'],
        'child': ['child', 'children', 'son', 'daughter', 'kids'],
        'spouse': ['spouse', 'husband', 'wife', 'partner'],
        'sibling': ['sibling', 'brother', 'sister', 'siblings'],
      };

      for (final entry in relationTypes.entries) {
        if (_containsAny(message, entry.value)) {
          final userRelationships = await _familyTreeService.getUserRelationships(userId);
          final matchingRelations = userRelationships
              .where((r) => r.relation == entry.key)
              .toList();

          if (matchingRelations.isEmpty) {
            return "You don't have any ${entry.key}s added to your family tree yet.";
          }

          String response = "👪 **Your ${entry.key[0].toUpperCase() + entry.key.substring(1)}s**:\n\n";
          for (int i = 0; i < matchingRelations.length; i++) {
            final relationship = matchingRelations[i];
            final relatedUser = familyMembers[relationship.toUserId];

            if (relatedUser != null) {
              response += "${i + 1}. **${relatedUser.name}**\n";
            }
          }

          return response;
        }
      }

      // General family info
      final userRelationships = await _familyTreeService.getUserRelationships(userId);
      final relationCounts = <String, int>{};

      for (final relationship in userRelationships) {
        relationCounts[relationship.relation] = (relationCounts[relationship.relation] ?? 0) + 1;
      }

      String response = "👨‍👩‍👧‍👦 **Your Family Tree Overview**\n\n";
      response += "📊 **Total Connections**: ${userRelationships.length}\n\n";

      if (relationCounts.isNotEmpty) {
        response += "🔗 **Relationships**:\n";
        for (final entry in relationCounts.entries) {
          final displayName = RelationshipType.getDisplayName(entry.key);
          response += "   • $displayName: ${entry.value}\n";
        }
      }

      return response;
    } catch (e) {
      return "Sorry, I couldn't access your family information right now. Please try again later.";
    }
  }

  /// Handle statistics queries
  Future<String> _handleStatsQuery(String message) async {
    try {
      final memories = await _memoryService.getAllMemories(currentUserId!);

      if (memories.isEmpty) {
        return "You don't have any memories yet, so there are no statistics to show. Start adding memories to see your digital legacy grow!";
      }

      final totalMemories = memories.length;
      final photoCount = memories
          .where((m) => m.type == MemoryType.photo)
          .length;
      final videoCount = memories
          .where((m) => m.type == MemoryType.video)
          .length;
      final audioCount = memories
          .where((m) => m.type == MemoryType.audio)
          .length;
      final textCount = memories.where((m) => m.type == MemoryType.text).length;

      // Calculate time span
      final oldestMemory = memories.reduce(
        (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
      );
      final newestMemory = memories.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
      );
      final daysSpan = newestMemory.createdAt
          .difference(oldestMemory.createdAt)
          .inDays;

      // Most common emotions
      final allEmotions = memories.expand((m) => m.emotions).toList();
      final emotionCounts = <String, int>{};
      for (final emotion in allEmotions) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
      final topEmotions = emotionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      String response = "📊 **Your Digital Legacy Statistics**\n\n";
      response += "📈 **Total Memories**: $totalMemories\n";
      response += "📷 **Photos**: $photoCount\n";
      response += "🎥 **Videos**: $videoCount\n";
      response += "🎵 **Audio**: $audioCount\n";
      response += "📝 **Text**: $textCount\n\n";

      if (daysSpan > 0) {
        response += "⏰ **Time Span**: ${daysSpan} days\n";
      }

      if (topEmotions.isNotEmpty) {
        response += "💭 **Top Emotions**:\n";
        for (
          int i = 0;
          i < (topEmotions.length > 3 ? 3 : topEmotions.length);
          i++
        ) {
          final emotion = topEmotions[i];
          response += "   ${i + 1}. ${emotion.key} (${emotion.value} times)\n";
        }
      }

      return response;
    } catch (e) {
      return "Sorry, I couldn't calculate your statistics right now. Please try again later.";
    }
  }

  /// Handle search queries
  Future<String> _handleSearchQuery(String message) async {
    try {
      final memories = await _memoryService.getAllMemories(currentUserId!);

      if (memories.isEmpty) {
        return "You don't have any memories to search through yet. Start adding memories to build your digital legacy!";
      }

      // Extract search terms
      final searchTerms = message
          .replaceAll(RegExp(r'\b(find|search|look for|show me)\b'), '')
          .trim()
          .split(' ')
          .where((word) => word.length > 2)
          .toList();

      if (searchTerms.isEmpty) {
        return "What would you like me to search for? Try something like 'find memories about family' or 'search for happy moments'.";
      }

      // Search in titles and emotions
      final results = memories.where((memory) {
        final titleMatch = searchTerms.any(
          (term) => memory.title.toLowerCase().contains(term.toLowerCase()),
        );
        final emotionMatch = searchTerms.any(
          (term) => memory.emotions.any(
            (emotion) => emotion.toLowerCase().contains(term.toLowerCase()),
          ),
        );
        return titleMatch || emotionMatch;
      }).toList();

      if (results.isEmpty) {
        return "I couldn't find any memories matching '${searchTerms.join(' ')}'. Try different keywords or check your spelling.";
      }

      String response = "🔍 **Search Results** (${results.length} found):\n\n";
      for (int i = 0; i < (results.length > 5 ? 5 : results.length); i++) {
        final memory = results[i];
        response +=
            "${i + 1}. **${memory.title}** (${memory.type.displayName})\n";
        if (memory.emotions.isNotEmpty) {
          response += "   Emotions: ${memory.emotions.join(', ')}\n";
        }
        response += "\n";
      }

      if (results.length > 5) {
        response += "... and ${results.length - 5} more results.";
      }

      return response;
    } catch (e) {
      return "Sorry, I couldn't search your memories right now. Please try again later.";
    }
  }

  /// Handle event-related queries
  Future<String> _handleEventQuery(String message) async {
    try {
      final events = await _eventService.getUserEvents();

      if (events.isEmpty) {
        return "You don't have any events scheduled yet! Try adding events through the Notes & Calendar section to stay organized.";
      }

      // Today's events
      if (_containsAny(message, ['today', 'todays', 'this day'])) {
        final todaysEvents = await _eventService.getTodaysEvents();

        if (todaysEvents.isEmpty) {
          return "You don't have any events scheduled for today. Enjoy your day!";
        }

        String response = "📅 **Today's Events** (${todaysEvents.length}):\n\n";
        for (int i = 0; i < todaysEvents.length; i++) {
          final event = todaysEvents[i];
          response += "${i + 1}. **${event.title}**\n";
          response += "   ${event.typeIcon} ${event.type}\n";
          if (event.time != null) {
            response += "   🕐 ${event.formattedTime}\n";
          }
          response += "   📝 ${event.description}\n\n";
        }

        return response;
      }

      // Upcoming events
      if (_containsAny(message, ['upcoming', 'next', 'coming', 'future'])) {
        final upcomingEvents = await _eventService.getUpcomingEvents();

        if (upcomingEvents.isEmpty) {
          return "You don't have any upcoming events in the next 7 days.";
        }

        String response = "📅 **Upcoming Events** (${upcomingEvents.length}):\n\n";
        for (int i = 0; i < (upcomingEvents.length > 5 ? 5 : upcomingEvents.length); i++) {
          final event = upcomingEvents[i];
          final daysUntil = event.date.difference(DateTime.now()).inDays;

          response += "${i + 1}. **${event.title}**\n";
          response += "   📅 ${event.formattedDate}\n";
          if (event.time != null) {
            response += "   🕐 ${event.formattedTime}\n";
          }
          response += "   ${event.typeIcon} ${event.type}\n";
          response += "   📝 ${event.description}\n\n";
        }

        if (upcomingEvents.length > 5) {
          response += "... and ${upcomingEvents.length - 5} more events.";
        }

        return response;
      }

      // Event types
      final eventTypes = {
        'birthday': ['birthday', 'birthdays'],
        'meeting': ['meeting', 'meetings'],
        'appointment': ['appointment', 'appointments'],
      };

      for (final entry in eventTypes.entries) {
        if (_containsAny(message, entry.value)) {
          final typeEvents = await _eventService.getEventsByType(entry.key);

          if (typeEvents.isEmpty) {
            return "You don't have any ${entry.key} events scheduled.";
          }

          String response = "📅 **Your ${entry.key[0].toUpperCase() + entry.key.substring(1)}s** (${typeEvents.length}):\n\n";
          for (int i = 0; i < (typeEvents.length > 5 ? 5 : typeEvents.length); i++) {
            final event = typeEvents[i];
            response += "${i + 1}. **${event.title}**\n";
            response += "   📅 ${event.formattedDate}\n";
            if (event.time != null) {
              response += "   🕐 ${event.formattedTime}\n";
            }
            response += "   📝 ${event.description}\n\n";
          }

          if (typeEvents.length > 5) {
            response += "... and ${typeEvents.length - 5} more ${entry.key}s.";
          }

          return response;
        }
      }

      // General events info
      final totalEvents = events.length;
      final upcomingCount = (await _eventService.getUpcomingEvents()).length;
      final todayCount = (await _eventService.getTodaysEvents()).length;

      // Count events by type
      final typeCounts = <String, int>{};
      for (final event in events) {
        typeCounts[event.type] = (typeCounts[event.type] ?? 0) + 1;
      }

      String response = "📅 **Your Events Overview**\n\n";
      response += "📊 **Total Events**: $totalEvents\n";
      response += "📅 **Today**: $todayCount\n";
      response += "🔜 **Upcoming (7 days)**: $upcomingCount\n\n";

      if (typeCounts.isNotEmpty) {
        response += "📋 **Event Types**:\n";
        for (final entry in typeCounts.entries) {
          final displayType = entry.key[0].toUpperCase() + entry.key.substring(1);
          response += "   • $displayType: ${entry.value}\n";
        }
      }

      return response;
    } catch (e) {
      return "Sorry, I couldn't access your events right now. Please try again later.";
    }
  }

  /// Check if message contains any of the given keywords
  bool _containsAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
}
