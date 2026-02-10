import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

class SpeechToTextScreen extends StatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  State<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _transcript = '';
  double _soundLevel = 0.0;
  String _lastStatus = '';
  String _lastError = '';
  Timer? _webLevelSimulationTimer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
    _initSpeech();
  }

  @override
  void dispose() {
    _webLevelSimulationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Initialize speech recognition service
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (e) {
          debugPrint('Speech error: ${e.errorMsg} - ${e.permanent}');
          if (mounted) {
            setState(() {
              _lastError = e.errorMsg;
              _isListening = false;
            });
          }
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (mounted) {
            setState(() {
              _lastStatus = status;
              if (status == 'notListening' || status == 'done') {
                _isListening = false;
                _webLevelSimulationTimer?.cancel();
                _soundLevel = 0.0;
              } else if (status == 'listening') {
                _isListening = true;
              }
            });
          }
        },
        debugLogging: true,
      );
      debugPrint('Speech initialized: $_speechEnabled');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
      if (mounted) setState(() => _lastError = 'Init failed: $e');
    }
  }

  /// Start listening
  void _startListening() async {
    if (!_speechEnabled) {
      debugPrint('Speech not enabled! Re-initializing...');
      _initSpeech();
      return;
    }

    if (mounted) {
      setState(() {
        _lastError = '';
        _transcript = '';
      });
    }

    try {
      debugPrint('Starting listen session...');
      // Start listening with parameters optimized for both mobile and web
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US',
        listenMode: ListenMode.dictation,
        onSoundLevelChange: _onSoundLevel,
      );

      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }

      // On Web, onSoundLevelChange is often not supported, so we simulate it
      if (kIsWeb) {
        _webLevelSimulationTimer?.cancel();
        _webLevelSimulationTimer = Timer.periodic(
          const Duration(milliseconds: 100),
          (timer) {
            if (_isListening && mounted) {
              final random = Random();
              setState(() {
                _soundLevel = -10.0 + random.nextDouble() * 20.0;
              });
            } else {
              timer.cancel();
            }
          },
        );
      }
    } catch (e) {
      debugPrint('Error starting speech listen: $e');
      if (mounted) setState(() => _lastError = 'Start failed: $e');
    }
  }

  /// Stop listening
  void _stopListening() async {
    try {
      await _speechToText.stop();
      _webLevelSimulationTimer?.cancel();
      if (mounted) {
        setState(() {
          _isListening = false;
          _soundLevel = 0.0;
          _lastStatus = 'Stopped';
        });
      }
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Callback for speech results
  void _onSpeechResult(SpeechRecognitionResult result) {
    debugPrint(
      'Got result: ${result.recognizedWords} (final: ${result.finalResult})',
    );
    if (mounted) {
      setState(() {
        _transcript = result.recognizedWords;
      });
    }
  }

  /// Callback for sound level changes
  void _onSoundLevel(double level) {
    if (mounted && !kIsWeb) {
      setState(() {
        _soundLevel = level;
      });
    }
  }

  void _toggleRecording() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
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
                        'Speech to Text',
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Status Area
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isListening
                                  ? 'Listening...'
                                  : 'Tap Record to speak',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_lastError.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Error: $_lastError',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Transcript Area
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _transcript.isEmpty
                                  ? 'Transcript will appear here...'
                                  : _transcript,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                height: 1.5,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Recorder Button
                      FloatingActionButton.extended(
                        onPressed: _speechEnabled ? _toggleRecording : null,
                        backgroundColor: _isListening
                            ? Colors.redAccent
                            : Colors.black,
                        foregroundColor: Colors.white,
                        icon: Icon(_isListening ? Icons.stop : Icons.mic),
                        label: Text(_isListening ? 'Stop' : 'Record'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundBar extends StatelessWidget {
  final int index;
  final double level;

  const _SoundBar({required this.index, required this.level});

  @override
  Widget build(BuildContext context) {
    // Generate height based on sound level and random variation for visualization
    final random = Random(index);
    // speech_to_text often returns level in range -10 roughly to 10? documentation varies.
    // We'll normalize it to a base height + dynamic component.

    // Base height
    double height = 20.0;

    // Add dynamic component if level is significant. Assuming level is often > -10 when talking.
    // If level is really dB, it might be -100 to 0.
    // Let's assume some variability. If we use built-in Random for now it will look active.
    if (level > -50) {
      // arbitrary threshold showing activity
      double boost = (level + 50) * 0.5; // Scale it
      height += boost * random.nextDouble();
    }

    // Clamp height
    height = height.clamp(10.0, 80.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
