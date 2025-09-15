import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeprint/models/memory_model.dart';
import 'package:lifeprint/screens/memory_detail_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  String _selectedEmotion = 'All';

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
      appBar: AppBar(
        title: Text(
          'Memory Albums',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Column(
        children: [
          // Emotion Filter Chips
          _buildEmotionChips(),

          // Memories List
          Expanded(child: _buildMemoriesList()),
        ],
      ),
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
              label: Text(emotion),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedEmotion = emotion;
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemoriesList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your memories'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getMemoriesStream(user.uid),
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

        final memories = snapshot.data!.docs
            .map((doc) => MemoryModel.fromDocument(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: memories.length,
          itemBuilder: (context, index) {
            final memory = memories[index];
            return _buildMemoryCard(context, memory);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getMemoriesStream(String userId) {
    if (_selectedEmotion == 'All') {
      // Return all memories ordered by createdAt
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('memories')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // Filter by emotion using array-contains
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('memories')
          .where('emotions', arrayContains: _selectedEmotion.toLowerCase())
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Widget _buildMemoryCard(BuildContext context, MemoryModel memory) {
    final now = DateTime.now();
    final isLocked =
        memory.releaseDate != null && memory.releaseDate!.isAfter(now);

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MemoryDetailScreen(memory: memory),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(
                          Tween(
                            begin: const Offset(0.0, 0.1),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeOut)),
                        ),
                        child: child,
                      ),
                    );
                  },
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Preview
            _buildMediaPreview(memory, isLocked),

            // Memory Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Type
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Locked',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Type and Date
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(memory.type),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        memory.type.displayName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(memory.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),

                  // Emotions
                  if (memory.emotions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: memory.emotions.map((emotion) {
                        final isHighlighted =
                            emotion.toLowerCase() ==
                            _selectedEmotion.toLowerCase();
                        return Chip(
                          label: Text(
                            emotion,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isHighlighted
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          backgroundColor: isHighlighted
                              ? Colors.deepPurple.withOpacity(0.2)
                              : _getEmotionColor(emotion).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isHighlighted
                                ? Colors.deepPurple
                                : _getEmotionColor(emotion),
                            fontWeight: isHighlighted
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],

                  // Countdown for locked memories
                  if (isLocked) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Unlocks in ${_getTimeUntilRelease(memory.releaseDate!)}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
}
