import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeprint/screens/add_memory_screen.dart';
import 'package:lifeprint/screens/memory_detail_screen.dart';
import 'package:lifeprint/screens/family_tree_screen.dart';
import 'package:lifeprint/models/memory_model.dart';

class HomeScreen extends StatelessWidget {
  final String? selectedUserId;

  const HomeScreen({super.key, this.selectedUserId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayUserId = selectedUserId ?? user?.uid;

    if (displayUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your memories')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedUserId != null ? 'Family Member\'s Memories' : 'LifePrint',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: selectedUserId == null
            ? [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FamilyTreeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.family_restroom),
                ),
                IconButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                ),
              ]
            : [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ],
      ),
      body: Column(
        children: [
          // Quick Actions Section (only show for current user)
          if (selectedUserId == null) ...[
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.memory,
                            size: 48,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to LifePrint',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Capture and preserve your precious memories',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add Memory Button
                  SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddMemoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 28),
                      label: const Text(
                        'Add New Memory',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Memories List
          Expanded(child: _buildMemoriesList(displayUserId)),
        ],
      ),
    );
  }

  Widget _buildMemoriesList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('memories')
          .orderBy('createdAt', descending: true)
          .snapshots(),
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
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No memories yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap "Add New Memory" to get started',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final memories = snapshot.data!.docs
            .map((doc) => MemoryModel.fromDocument(doc))
            .where((memory) {
              // Filter: show memories where releaseDate is null OR releaseDate <= now
              return memory.releaseDate == null ||
                  memory.releaseDate!.isBefore(now) ||
                  memory.releaseDate!.isAtSameMomentAs(now);
            })
            .toList();

        if (memories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No unlocked memories',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'All your memories are currently locked',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: memories.length,
          itemBuilder: (context, index) {
            final memory = memories[index];
            return _buildMemoryCard(context, memory);
          },
        );
      },
    );
  }

  Widget _buildMemoryCard(BuildContext context, MemoryModel memory) {
    final now = DateTime.now();
    final isLocked =
        memory.releaseDate != null && memory.releaseDate!.isAfter(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MemoryDetailScreen(memory: memory),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Preview
            _buildMediaPreview(memory, isLocked),

            // Memory Info
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                      children: memory.emotions.take(3).map((emotion) {
                        return Chip(
                          label: Text(
                            emotion,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: _getEmotionColor(
                            emotion,
                          ).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _getEmotionColor(emotion),
                            fontWeight: FontWeight.w500,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    if (memory.emotions.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '+${memory.emotions.length - 3} more',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
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
          // Small lock icon in top-right corner
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.lock, size: 16, color: Colors.white),
            ),
          ),
        ],
      );
    }

    // Add small lock icon for memories with release date (even if unlocked)
    if (memory.releaseDate != null) {
      return Stack(
        children: [
          mediaWidget,
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isLocked ? Colors.orange[600] : Colors.green[600],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isLocked ? Icons.lock : Icons.schedule,
                size: 16,
                color: Colors.white,
              ),
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

  Color _getEmotionColor(String emotion) {
    final emotionColors = {
      'happy': Colors.yellow,
      'sad': Colors.blue,
      'angry': Colors.red,
      'excited': Colors.orange,
      'calm': Colors.green,
      'anxious': Colors.purple,
      'grateful': Colors.teal,
      'nostalgic': Colors.brown,
      'proud': Colors.indigo,
      'hopeful': Colors.lightGreen,
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
