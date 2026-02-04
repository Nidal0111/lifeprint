import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeprint/services/chatbot_service.dart';
import 'package:lifeprint/services/memory_service.dart';
import 'package:lifeprint/screens/memory_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeprint/models/memory_model.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class LegacyChatbotScreen extends StatefulWidget {
  const LegacyChatbotScreen({super.key});

  @override
  State<LegacyChatbotScreen> createState() => _LegacyChatbotScreenState();
}

class _LegacyChatbotScreenState extends State<LegacyChatbotScreen> {
  final List<_Message> _messages = <_Message>[];
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    // Add initial greeting
    _messages.add(
      _Message(
        text:
            'Hi! I am your LifePrint assistant. I can help you explore your memories, family connections, and answer questions about your digital legacy. What would you like to know?',
        isBot: true,
      ),
    );
  }

  /// Initialize speech recognition service
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
    }
  }

  /// Start listening to microphone input
  void _startListening() async {
    if (!_speechEnabled) return;
    try {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _isListening = true;
      });
    } catch (e) {
      debugPrint('Error starting speech listen: $e');
    }
  }

  /// Stop listening
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  /// Update text controller with recognized speech
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _controller.text = result.recognizedWords;
    });
  }

  final ChatbotService _chatbotService = ChatbotService();
  final MemoryService _memoryService = MemoryService();
  bool _isTyping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'LifePrint Assistant',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }

                    final msg = _messages[index];
                    final align = msg.isBot
                        ? Alignment.centerLeft
                        : Alignment.centerRight;
                    final color = msg.isBot
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black;
                    final textColor = msg.isBot ? Colors.black : Colors.white;
                    // If bot message offers opening a memory, show an 'Open' button
                    final offersOpen =
                        msg.isBot &&
                        msg.text.contains('Want me to open that memory?');
                    return Align(
                      alignment: align,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                msg.text,
                                style: GoogleFonts.poppins(color: textColor),
                              ),
                            ),
                            if (offersOpen) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () =>
                                    _tryOpenMemoryFromBotText(msg.text),
                                child: const Text('Open'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _isListening ? 'Listening...' : 'Type a message',
                          hintStyle: GoogleFonts.poppins(
                            color: _isListening ? Colors.yellowAccent : Colors.white70,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Microphone Button
                    CircleAvatar(
                      backgroundColor: _isListening ? Colors.redAccent : Colors.white.withOpacity(0.2),
                      child: IconButton(
                        icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                        color: Colors.white,
                        onPressed: _speechEnabled
                            ? (_isListening ? _stopListening : _startListening)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      onPressed: _send,
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }

    setState(() {
      _messages.add(_Message(text: text, isBot: false));
      _isTyping = true;
      _controller.clear();
    });

    try {
      final response = await _chatbotService.processMessage(text);

      // The chatbot may return a JSON wrapper with { text, openMemoryTitle }
      String botText = response;
      String? openTitle;
      try {
        final parsed = jsonDecode(response);
        if (parsed is Map<String, dynamic> && parsed['text'] != null) {
          botText = parsed['text'].toString();
          openTitle = parsed['openMemoryTitle']?.toString();
        }
      } catch (_) {
        // not JSON
      }

      setState(() {
        _isTyping = false;
        _messages.add(
          _Message(text: botText, isBot: true, openMemoryTitle: openTitle),
        );
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(
          _Message(
            text: 'Sorry, I encountered an error. Please try again.',
            isBot: true,
          ),
        );
      });
    }
  }

  // Try to parse a quoted memory title from bot response and open it
  Future<void> _tryOpenMemoryFromBotText(
    String botText, {
    String? openTitle,
  }) async {
    try {
      // If the service provided an explicit title, use it first
      String? title = openTitle;
      if (title == null || title.isEmpty) {
        final match = RegExp(r'"([^\"]+)"').firstMatch(botText);
        if (match == null) return;
        title = match.group(1)?.trim();
      }
      if (title == null || title.isEmpty) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final memories = await _memoryService.getAllMemories(user.uid);
      MemoryModel? memoryFound;
      for (final m in memories) {
        if (m.title.toLowerCase() == title.toLowerCase()) {
          memoryFound = m;
          break;
        }
      }
      if (memoryFound == null) {
        for (final m in memories) {
          if (m.title.toLowerCase().contains(title.toLowerCase())) {
            memoryFound = m;
            break;
          }
        }
      }

      if (memoryFound == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Memory not found')));
        return;
      }

      // Navigate to detail screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryDetailScreen(memory: memoryFound!),
          ),
        );
      }
    } catch (e) {
      // ignore errors
    }
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isBot;
  final String? openMemoryTitle;
  _Message({required this.text, required this.isBot, this.openMemoryTitle});
}
