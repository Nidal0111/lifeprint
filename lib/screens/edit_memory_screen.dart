import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lifeprint/services/cloudinary_service.dart';
import 'package:lifeprint/services/memory_service.dart';
import 'package:lifeprint/models/memory_model.dart';

class EditMemoryScreen extends StatefulWidget {
  final MemoryModel memory;

  const EditMemoryScreen({super.key, required this.memory});

  @override
  State<EditMemoryScreen> createState() => _EditMemoryScreenState();
}

class _EditMemoryScreenState extends State<EditMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _transcriptController = TextEditingController();
  final _releaseDateController = TextEditingController();
String? _currentCloudinaryUrl;

  File? _selectedFile;
  MemoryType _selectedType = MemoryType.photo;
  DateTime? _releaseDate;
  bool _isLoading = false;
  bool _isUploading = false;
late String _emotion;



  @override
  void initState() {
    super.initState();
    _currentCloudinaryUrl = widget.memory.cloudinaryUrl;
    _initializeFields();
  }

  
  void _initializeFields() {
    _titleController.text = widget.memory.title;
    _transcriptController.text = widget.memory.transcript ?? '';
    _selectedType = widget.memory.type;
   _emotion = widget.memory.emotion;


    if (widget.memory.releaseDate != null) {
      _releaseDate = widget.memory.releaseDate;
      _releaseDateController.text =
          '${_releaseDate!.day}/${_releaseDate!.month}/${_releaseDate!.year}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptController.dispose();
    _releaseDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Memory'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveChanges,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Media Preview
              _buildCurrentMediaPreview(),
              const SizedBox(height: 24),

              // Change Media Section
              _buildChangeMediaSection(),
              const SizedBox(height: 24),

              // Memory Type Selection
              _buildTypeSelectionSection(),
              const SizedBox(height: 24),

              // Title Input
              _buildTitleInput(),
              const SizedBox(height: 24),

              // Transcript Input
              _buildTranscriptInput(),
              const SizedBox(height: 24),

              // Emotions Section
              _buildEmotionsSection(),
              const SizedBox(height: 24),

              // Release Date Input
              _buildReleaseDateInput(),
              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMediaPreview() {
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
                Icon(Icons.visibility, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Current Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.memory.cloudinaryUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.memory.cloudinaryUrl!,
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
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeMediaSection() {
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
                Icon(Icons.swap_horiz, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Change Media (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected File Preview
            if (_selectedFile != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(_selectedFile!.path),
                      color: Colors.deepPurple,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            CloudinaryService.getFileSizeString(
                              _selectedFile!.readAsBytesSync().length,
                            ),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Media Selection Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _selectImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _selectVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _selectAudio,
                icon: const Icon(Icons.audiotrack),
                label: const Text('Audio File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelectionSection() {
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
                Icon(Icons.category, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Memory Type',
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
  children: [
    Chip(
      label: Text(_emotion),
      backgroundColor: _getEmotionColor(_emotion).withOpacity(0.2),
      labelStyle: TextStyle(
        color: _getEmotionColor(_emotion),
        fontWeight: FontWeight.w500,
      ),
    ),
  ],
),

          ],
        ),
      ),
    );
  }

  Widget _buildTitleInput() {
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
                Icon(Icons.title, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Memory Title',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter a title for your memory',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptInput() {
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
                Icon(Icons.description, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Transcript (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _transcriptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter transcript or description...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ),
                ),
              ),
            ),
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

          // ✅ FIX: emotion is STRING → single chip
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(_emotion),
                backgroundColor:
                    _getEmotionColor(_emotion).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _getEmotionColor(_emotion),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🔒 UI SAME, LOGIC DISABLED
          ElevatedButton.icon(
            onPressed: null, // emotion is auto-detected
            icon: const Icon(Icons.add),
            label: const Text('Add Emotion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildReleaseDateInput() {
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
                Icon(Icons.calendar_today, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Release Date (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _releaseDateController,
              decoration: InputDecoration(
                hintText: 'Select when this memory should be released',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ),
                ),
                suffixIcon: IconButton(
                  onPressed: _selectReleaseDate,
                  icon: const Icon(Icons.calendar_today),
                ),
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveChanges,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _deleteMemory,
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String filePath) {
    String extension = filePath.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
      return Icons.image;
    } else if ([
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'webm',
    ].contains(extension)) {
      return Icons.videocam;
    } else if ([
      'mp3',
      'wav',
      'aac',
      'ogg',
      'flac',
      'm4a',
    ].contains(extension)) {
      return Icons.audiotrack;
    }
    return Icons.insert_drive_file;
  }
Future<void> _selectImage() async {
  try {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFile = null; // no File on web
          _selectedType = MemoryType.photo;
        });

        // Store bytes temporarily using Cloudinary directly
        final url = await CloudinaryService.uploadImage(
          bytes: result.files.single.bytes!,
          fileName: result.files.single.name,
        );

      setState(() {
  _currentCloudinaryUrl = url;
});

      }
    } else {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _selectedType = MemoryType.photo;
        });
      }
    }
  } catch (e) {
    _showSnackBar('Error selecting image: $e', isError: true);
  }
}

  Future<void> _selectVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        setState(() {
          _selectedFile = File(video.path);
          _selectedType = MemoryType.video;
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting video: $e', isError: true);
    }
  }

  Future<void> _selectAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedType = MemoryType.audio;
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting audio: $e', isError: true);
    }
  }

  Future<void> _selectReleaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _releaseDate = picked;
        _releaseDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }


  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String? cloudinaryUrl = widget.memory.cloudinaryUrl;

      // Upload new file if selected
      if (_selectedFile != null) {
        setState(() {
          _isUploading = true;
        });

       cloudinaryUrl = await CloudinaryService.uploadImage(
  file: _selectedFile, // Android / iOS
);


        if (cloudinaryUrl == null) {
          throw Exception('Failed to upload new file to Cloudinary');
        }

        setState(() {
          _isUploading = false;
        });
      }

      // Update memory in Firestore
      await MemoryService().updateMemory(widget.memory.id, {
        'title': _titleController.text.trim(),
        'type': _selectedType.name,
        'cloudinaryUrl': cloudinaryUrl,
        'transcript': _transcriptController.text.trim().isEmpty
            ? null
            : _transcriptController.text.trim(),
        'emotion': _emotion,
        'releaseDate': _releaseDate?.toIso8601String(),
      });

      _showSnackBar('Memory updated successfully!', isError: false);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      _showSnackBar('Error updating memory: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
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
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await MemoryService().deleteMemory(widget.memory.id);

      _showSnackBar('Memory deleted successfully!', isError: false);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      _showSnackBar('Error deleting memory: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}
