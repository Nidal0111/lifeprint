import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeprint/models/memory_model.dart';
import 'package:lifeprint/services/memory_service.dart';
import 'package:lifeprint/screens/family_tree_screen.dart';
import 'package:lifeprint/screens/memory_detail_screen.dart';
import 'package:lifeprint/screens/modern_home_screen.dart';
import 'package:lifeprint/screens/notes_calendar_screen.dart';
import 'package:lifeprint/screens/add_memory_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  String _selectedEmotion = 'All';
  final int _currentIndex = 1;

  // Predefined emotion categories
  final List<String> _emotionCategories = [
    'All',
    'Joy',
    'Nostalgia',
    'Sadness',
    'Excitement',
    'Love',
    'Gratitude',
    'Peace',
    'Adventure',
    'Achievement',
    'Family',
    'Friendship',
    'Romance',
    'Hope',
    'Pride',
    'Wonder',
    'Calm',
    'Energy',
    'Reflection',
    'Celebration',
  ];

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
              // Custom App Bar
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
                        'Memory Albums',
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
              // Content
              _buildEmotionChips(),
              Expanded(child: _buildMemoriesList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, _currentIndex),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmotionChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _emotionCategories.length,
        itemBuilder: (context, index) {
          final emotion = _emotionCategories[index];
          final isSelected = _selectedEmotion == emotion;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                emotion,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? const Color(0xFF667eea)
                      : const Color.fromARGB(255, 234, 126, 248),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedEmotion = emotion;
                });
              },
              backgroundColor: Colors.white.withOpacity(0.1),
              selectedColor: Colors.white,
              checkmarkColor: const Color(0xFF667eea),
              side: BorderSide(
                color: isSelected
                    ? Colors.white
                    : const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;
          Widget target;
          switch (index) {
            case 0:
              target = const ModernHomeScreen();
              break;
            case 1:
              target = const AlbumsScreen();
              break;
            case 2:
              target = const FamilyTreeScreen();
              break;
            case 3:
              target = const NotesCalendarScreen();
              break;
            default:
              target = const ModernHomeScreen();
          }

          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => target,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 250),
            ),
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Memories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom_outlined),
            activeIcon: Icon(Icons.family_restroom),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Notes',
          ),
        ],
      ),
    );
  }

  Widget _buildMemoriesList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your memories'));
    }

    return FutureBuilder<List<MemoryModel>>(
      future: _getMemories(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading memories',
                  style: TextStyle(fontSize: 18, color: Colors.red[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final memories = snapshot.data ?? [];

        if (memories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedEmotion == 'All'
                      ? Icons.photo_library_outlined
                      : _getEmotionIcon(_selectedEmotion),
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedEmotion == 'All'
                      ? 'No memories yet'
                      : 'No $_selectedEmotion memories',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedEmotion == 'All'
                      ? 'Tap "Add New Memory" to get started'
                      : 'Try selecting a different emotion or add memories with this emotion',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: memories.length,
          itemBuilder: (context, index) {
            final memory = memories[index];
            return buildMemoryCard(context, memory);
          },
        );
      },
    );
  }
Future<List<MemoryModel>> _getMemories(String userId) async {
  final memoryService = MemoryService();
  final allMemories = await memoryService.getAllMemories(userId);

  if (_selectedEmotion == 'All') {
    return allMemories;
  }

  return allMemories.where((memory) {
    return memory.emotion.toLowerCase() ==
        _selectedEmotion.toLowerCase(); // ✅ FIX
  }).toList();
}

Widget buildMemoryCard(BuildContext context, MemoryModel memory) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemoryDetailScreen(memory: memory),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- MEDIA ----------------
          if (memory.cloudinaryUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                memory.cloudinaryUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          // ---------------- CONTENT ----------------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  memory.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Type
                Text(
                  memory.type.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                // ---------------- EMOTION (STRING SAFE) ----------------
                if (memory.emotion.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(
                          memory.emotion,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getEmotionColor(memory.emotion),
                          ),
                        ),
                        backgroundColor:
                            _getEmotionColor(memory.emotion).withOpacity(0.2),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildMediaPreview(MemoryModel memory, bool isLocked) {
    if (memory.cloudinaryUrl == null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
            ),
            if (isLocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.lock, size: 48, color: Colors.white),
                ),
              ),
          ],
        ),
      );
    }

    Widget mediaWidget;

    switch (memory.type) {
      case MemoryType.photo:
        mediaWidget = ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.network(
            memory.cloudinaryUrl!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              );
            },
          ),
        );
        break;

      case MemoryType.video:
        mediaWidget = Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  memory.cloudinaryUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.videocam,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
        break;

      case MemoryType.audio:
        mediaWidget = Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple[300]!, Colors.deepPurple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: const Center(
            child: Icon(Icons.audiotrack, size: 64, color: Colors.white),
          ),
        );
        break;

      case MemoryType.text:
        mediaWidget = Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
          ),
          child: const Center(
            child: Icon(Icons.text_snippet, size: 64, color: Colors.deepPurple),
          ),
        );
        break;
    }

    if (isLocked) {
      return Stack(
        children: [
          mediaWidget,
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Center(
              child: Icon(Icons.lock, size: 48, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return mediaWidget;
  }

  IconData _getTypeIcon(MemoryType type) {
    switch (type) {
      case MemoryType.photo:
        return Icons.image;
      case MemoryType.video:
        return Icons.videocam;
      case MemoryType.audio:
        return Icons.audiotrack;
      case MemoryType.text:
        return Icons.text_snippet;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return Icons.sentiment_very_satisfied;
      case 'nostalgia':
        return Icons.history;
      case 'sadness':
        return Icons.sentiment_dissatisfied;
      case 'excitement':
        return Icons.celebration;
      case 'love':
        return Icons.favorite;
      case 'gratitude':
        return Icons.volunteer_activism;
      case 'peace':
        return Icons.spa;
      case 'adventure':
        return Icons.explore;
      case 'achievement':
        return Icons.emoji_events;
      case 'family':
        return Icons.family_restroom;
      case 'friendship':
        return Icons.people;
      case 'romance':
        return Icons.favorite_border;
      case 'hope':
        return Icons.lightbulb;
      case 'pride':
        return Icons.flag;
      case 'wonder':
        return Icons.auto_awesome;
      case 'calm':
        return Icons.waves;
      case 'energy':
        return Icons.bolt;
      case 'reflection':
        return Icons.self_improvement;
      case 'celebration':
        return Icons.party_mode;
      default:
        return Icons.emoji_emotions;
    }
  }

  Color _getEmotionColor(String emotion) {
    final emotionColors = {
      'joy': Colors.yellow,
      'nostalgia': Colors.brown,
      'sadness': Colors.blue,
      'excitement': Colors.orange,
      'love': Colors.red,
      'gratitude': Colors.teal,
      'peace': Colors.green,
      'adventure': Colors.purple,
      'achievement': Colors.indigo,
      'family': Colors.pink,
      'friendship': Colors.cyan,
      'romance': Colors.pinkAccent,
      'hope': Colors.lightGreen,
      'pride': Colors.amber,
      'wonder': Colors.deepPurple,
      'calm': Colors.lightBlue,
      'energy': Colors.redAccent,
      'reflection': Colors.grey,
      'celebration': Colors.orangeAccent,
    };
    return emotionColors[emotion.toLowerCase()] ?? Colors.grey;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getTimeUntilRelease(DateTime releaseDate) {
    final now = DateTime.now();
    final difference = releaseDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day(s)';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s)';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s)';
    } else {
      return 'less than a minute';
    }
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AddMemoryScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
