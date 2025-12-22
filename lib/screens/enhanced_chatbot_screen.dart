import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:lifeprint/services/chatbot_service.dart';
import 'package:lifeprint/services/memory_service.dart';
import 'package:lifeprint/screens/memory_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeprint/models/memory_model.dart';
import 'dart:convert';

class EnhancedChatbotScreen extends StatefulWidget {
  const EnhancedChatbotScreen({super.key});

  @override
  State<EnhancedChatbotScreen> createState() => _EnhancedChatbotScreenState();
}

class _EnhancedChatbotScreenState extends State<EnhancedChatbotScreen>
    with TickerProviderStateMixin {
  final List<_Message> _messages = <_Message>[];
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _speechText = '';
  bool _speechAvailable = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);

    // Add initial greeting
    _messages.add(
      _Message(
        text:
            'Hi! I\'m your LifePrint AI assistant. I can help you explore your memories, family connections, and answer questions about your digital legacy. You can type or speak your questions!',
        isBot: true,
      ),
    );
  }

  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'notListening') {
          setState(() => _isListening = false);
          _pulseController.stop();
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
        setState(() => _isListening = false);
        _pulseController.stop();
      },
    );

    if (!_speechAvailable) {
      print('Speech recognition not available');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

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
                        'AI Assistant',
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
              // Speech recognition status indicator
              if (_isListening || _speechText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black.withOpacity(0.3),
                  child: Row(
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_off,
                        color: _isListening ? Colors.red : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isListening
                              ? 'Listening... Speak now'
                              : _speechText.isNotEmpty
                                  ? 'Heard: $_speechText'
                                  : 'Speech recognition ready',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_speechText.isNotEmpty && !_isListening)
                        IconButton(
                          onPressed: () {
                            _controller.text = _speechText;
                            setState(() => _speechText = '');
                          },
                          icon: const Icon(Icons.check, color: Colors.green),
                        ),
                    ],
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
                          hintText: 'Type your question...',
                          hintStyle: GoogleFonts.poppins(color: Colors.white70),
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
                    // Voice input button
                    if (_speechAvailable)
                      ScaleTransition(
                        scale: _pulseController,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _toggleListening,
                          backgroundColor: _isListening ? Colors.red : Colors.white,
                          foregroundColor: _isListening ? Colors.white : Colors.black,
                          child: Icon(_isListening ? Icons.mic_off : Icons.mic),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Send button
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

  void _toggleListening() async {
    if (!_speechAvailable) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
    } else {
      // Request microphone permission
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice input'),
          ),
        );
        return;
      }

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _speechText = result.recognizedWords;
          });

          // Auto-send if confidence is high and speech is final
          if (result.finalResult && result.confidence > 0.7) {
            _controller.text = result.recognizedWords;
            _send();
            setState(() => _speechText = '');
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US', // You can make this configurable
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
    }
  }

  bool _isTyping = false;
  final ChatbotService _chatbotService = ChatbotService();
  final MemoryService _memoryService = MemoryService();

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, isBot: false));
      _isTyping = true;
      _controller.clear();
      _speechText = '';
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
