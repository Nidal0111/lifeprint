import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeprint/models/memory_model.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lifeprint/screens/edit_memory_screen.dart';

class MemoryDetailScreen extends StatefulWidget {
  final MemoryModel memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isVideoInitialized = false;
  bool _isAudioPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializeMedia() async {
    if (widget.memory.type == MemoryType.video &&
        widget.memory.cloudinaryUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.memory.cloudinaryUrl!),
      );
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    } else if (widget.memory.type == MemoryType.audio) {
      _audioPlayer = AudioPlayer();
      if (widget.memory.cloudinaryUrl != null) {
        await _audioPlayer!.setUrl(widget.memory.cloudinaryUrl!);
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_audioPlayer == null) return;

    if (_isAudioPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.play();
    }
    setState(() {
      _isAudioPlaying = !_isAudioPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memory.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _editMemory,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Memory',
          ),
          IconButton(
            onPressed: _deleteMemory,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Memory',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media Preview
                  _buildMediaPreview(),
                  const SizedBox(height: 24),

                  // Memory Details
                  _buildMemoryDetails(),
                  const SizedBox(height: 24),

                  // Emotions
                  if (widget.memory.emotions.isNotEmpty) ...[
                    _buildEmotionsSection(),
                    const SizedBox(height: 24),
                  ],

                  // Release Date Info
                  if (widget.memory.releaseDate != null) ...[
                    _buildReleaseDateSection(),
                    const SizedBox(height: 24),
                  ],

                  // Metadata
                  _buildMetadataSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildMediaPreview() {
    if (widget.memory.cloudinaryUrl == null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      );
    }

    switch (widget.memory.type) {
      case MemoryType.photo:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.memory.cloudinaryUrl!,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              );
            },
          ),
        );

      case MemoryType.video:
        return Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isVideoInitialized
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      VideoPlayer(_videoController!),
                      Center(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                            });
                          },
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        );

      case MemoryType.audio:
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple[300]!, Colors.deepPurple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.audiotrack, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'Audio Memory',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              IconButton(
                onPressed: _toggleAudio,
                icon: Icon(
                  _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          ),
        );

      case MemoryType.text:
        return Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.text_snippet, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  'Text Memory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildMemoryDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Memory Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.memory.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getTypeIcon(widget.memory.type),
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  widget.memory.type.displayName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            if (widget.memory.transcript != null) ...[
              const SizedBox(height: 16),
              Text(
                'Transcript:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.memory.transcript!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mood, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Emotions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.memory.emotions.map((emotion) {
                return Chip(
                  label: Text(emotion),
                  backgroundColor: _getEmotionColor(emotion).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getEmotionColor(emotion),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReleaseDateSection() {
    final now = DateTime.now();
    final isLocked = widget.memory.releaseDate!.isAfter(now);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  color: isLocked ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  isLocked ? 'Locked Memory' : 'Released Memory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Release Date: ${_formatDate(widget.memory.releaseDate!)}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (isLocked) ...[
              const SizedBox(height: 8),
              Text(
                'This memory will be unlocked in ${_getTimeUntilRelease()}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Metadata',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetadataRow('Created', _formatDate(widget.memory.createdAt)),
            _buildMetadataRow('Memory ID', widget.memory.id),
            _buildMetadataRow('Created By', widget.memory.createdBy),
            _buildMetadataRow(
              'Shared With',
              '${widget.memory.linkedUserIds.length} user(s)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
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
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeUntilRelease() {
    final now = DateTime.now();
    final releaseDate = widget.memory.releaseDate!;
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

  Future<void> _editMemory() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditMemoryScreen(memory: widget.memory),
      ),
    );

    if (result == true && mounted) {
      // Memory was updated or deleted, go back to home
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteMemory() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory'),
        content: const Text(
          'Are you sure you want to delete this memory? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Import FirebaseAuth and Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('memories')
          .doc(widget.memory.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory deleted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );

        // Go back to home screen
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting memory: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
