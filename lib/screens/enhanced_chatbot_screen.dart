import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:lifeprint/services/chatbot_service.dart';
import 'package:lifeprint/services/memory_service.dart';
import 'package:lifeprint/screens/memory_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeprint/models/memory_model.dart';

class EnhancedChatbotScreen extends StatefulWidget {
  const EnhancedChatbotScreen({super.key});

  @override
  State<EnhancedChatbotScreen> createState() => _EnhancedChatbotScreenState();
}

class _EnhancedChatbotScreenState extends State<EnhancedChatbotScreen>
    with TickerProviderStateMixin {
  final List<_Message> _messages = <_Message>[];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _translateMode = false;
  String _currentLocale = 'en_US';

  late AnimationController _pulseController;

  bool _isTyping = false;
  final ChatbotService _chatbotService = ChatbotService();
  final MemoryService _memoryService = MemoryService();
  final ImagePicker _imagePicker = ImagePicker();

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

    _messages.add(
      _Message(
        text:
            'Hi! I\'m your LifePrint AI assistant powered by Groq. I can help you explore your memories, family connections, and events. You can type, speak, or send a photo for emotion analysis! 🧠📸',
        isBot: true,
      ),
    );
  }

  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              if (status == 'notListening' || status == 'done') {
                _isListening = false;
                _pulseController.stop();
              } else if (status == 'listening') {
                _isListening = true;
                _pulseController.repeat(reverse: true);
              }
            });
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          if (mounted) {
            setState(() => _isListening = false);
            _pulseController.stop();
          }
        },
      );
    } catch (e) {
      debugPrint('Speech initialization exception: $e');
      _speechAvailable = false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Image emotion analysis ────────────────────────────────────────────────

  Future<void> _pickAndAnalyzeImage() async {
    // Show source picker dialog
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1B2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Analyze Emotions from Image',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceButton(
                  ctx,
                  Icons.camera_alt_rounded,
                  'Camera',
                  ImageSource.camera,
                ),
                _sourceButton(
                  ctx,
                  Icons.photo_library_rounded,
                  'Gallery',
                  ImageSource.gallery,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 800,
      );
      if (picked == null) return;

      // Show the image in chat as a user message
      Uint8List? imageBytes;
      String? imagePath;

      if (kIsWeb) {
        imageBytes = await picked.readAsBytes();
      } else {
        imagePath = picked.path;
        imageBytes = await File(imagePath).readAsBytes();
      }

      // Add user "image" message
      setState(() {
        _messages.add(
          _Message(
            text: '📸 Analyzing emotions in this image...',
            isBot: false,
            imageBytes: imageBytes,
          ),
        );
        _isTyping = true;
      });
      _scrollToBottom();

      // Convert to base64
      final base64Image = base64Encode(imageBytes!);

      // Call Groq vision
      final analysis = await _chatbotService.analyzeImageEmotions(base64Image);

      setState(() {
        _isTyping = false;
        _messages.add(
          _Message(
            text: '🎭 Emotion Analysis:\n\n$analysis',
            isBot: true,
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(
          _Message(
            text: 'Sorry, I couldn\'t analyze the image. Please try again.',
            isBot: true,
          ),
        );
      });
      debugPrint('Image analysis error: $e');
    }
  }

  Widget _sourceButton(
    BuildContext ctx,
    IconData icon,
    String label,
    ImageSource source,
  ) {
    return GestureDetector(
      onTap: () => Navigator.of(ctx).pop(source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Send message ──────────────────────────────────────────────────────────

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, isBot: false));
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await _chatbotService.processMessage(text);

      String botText = response;
      String? openTitle;
      String? imageUrl;
      try {
        final parsed = jsonDecode(response);
        if (parsed is Map<String, dynamic> && parsed['text'] != null) {
          botText = parsed['text'].toString();
          openTitle = parsed['openMemoryTitle']?.toString();
          imageUrl = parsed['imageUrl']?.toString();
        }
      } catch (_) {
        // not JSON
      }

      setState(() {
        _isTyping = false;
        _messages.add(
          _Message(
            text: botText,
            isBot: true,
            openMemoryTitle: openTitle,
            imageUrl: imageUrl,
          ),
        );
      });
      _scrollToBottom();
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

  // ─── Speech ───────────────────────────────────────────────────────────────

  void _toggleListening() async {
    if (!_speechAvailable) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
    } else {
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
          if (mounted) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          }
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _handleSpeechResult(result.recognizedWords.trim());
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: _currentLocale,
        listenMode: stt.ListenMode.dictation,
      );

      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
    }
  }

  void _handleSpeechResult(String speechText) async {
    if (speechText.isEmpty) return;

    await _speech.stop();
    setState(() {
      _isListening = false;
      _controller.text = speechText;
    });
    _pulseController.stop();

    if (_translateMode) {
      setState(() => _isTyping = true);
      final translated = await _chatbotService.translateToEnglish(speechText);
      if (mounted) {
        setState(() {
          _controller.text = translated;
          _isTyping = false;
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _send();
  }

  // ─── Open memory ───────────────────────────────────────────────────────────

  Future<void> _tryOpenMemoryFromBotText(
    String botText, {
    String? openTitle,
  }) async {
    try {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Memory not found')),
          );
        }
        return;
      }

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

  // ─── Build ─────────────────────────────────────────────────────────────────

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
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'AI Assistant',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Powered by Groq',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Messages list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),

              // Listening indicator
              if (_isListening)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.black.withOpacity(0.3),
                  child: Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Listening...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Input bar
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
                    // Image upload button
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Analyze image emotions',
                        onPressed: _pickAndAnalyzeImage,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type your question...',
                          hintStyle:
                              GoogleFonts.poppins(color: Colors.white70),
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

                    // Speech buttons
                    if (_speechAvailable) ...[
                      // Language toggle
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentLocale = _currentLocale == 'en_US'
                                ? 'ml_IN'
                                : 'en_US';
                            if (_currentLocale == 'ml_IN') {
                              _translateMode = true;
                            }
                          });
                        },
                        icon: Text(
                          _currentLocale == 'en_US' ? 'EN' : 'ML',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        tooltip: 'Change Language',
                      ),

                      // Translate toggle
                      IconButton(
                        onPressed: () {
                          setState(() => _translateMode = !_translateMode);
                        },
                        icon: Icon(
                          _translateMode
                              ? Icons.translate
                              : Icons.g_translate,
                          color: _translateMode
                              ? Colors.cyanAccent
                              : Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Translation Mode',
                      ),
                      const SizedBox(width: 4),

                      // Mic button
                      ScaleTransition(
                        scale: _pulseController,
                        child: FloatingActionButton(
                          mini: true,
                          heroTag: 'mic_btn',
                          onPressed: _toggleListening,
                          backgroundColor:
                              _isListening ? Colors.red : Colors.white,
                          foregroundColor:
                              _isListening ? Colors.white : Colors.black,
                          child: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),

                    // Send button
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'send_btn',
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

  Widget _buildMessageBubble(_Message msg) {
    final isBot = msg.isBot;
    final align = isBot ? Alignment.centerLeft : Alignment.centerRight;
    final bgColor =
        isBot ? Colors.white.withOpacity(0.9) : Colors.black;
    final textColor = isBot ? Colors.black87 : Colors.white;
    final offersOpen =
        isBot && msg.text.contains('Want me to open that memory?');

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text
            Text(
              msg.text,
              style: GoogleFonts.poppins(color: textColor, fontSize: 13.5),
            ),

            // Attached image (user upload preview)
            if (msg.imageBytes != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  msg.imageBytes!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            // Memory image (from Cloudinary)
            if (msg.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  msg.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],

            // Open Memory button
            if (offersOpen) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _tryOpenMemoryFromBotText(
                    msg.text,
                    openTitle: msg.openMemoryTitle,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Open Memory'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
                fontSize: 13,
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
  final String? imageUrl;
  final Uint8List? imageBytes;

  _Message({
    required this.text,
    required this.isBot,
    this.openMemoryTitle,
    this.imageUrl,
    this.imageBytes,
  });
}
