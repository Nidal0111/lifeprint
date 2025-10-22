import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:lifeprint/services/cloudinary_service.dart';
import 'package:lifeprint/services/memory_service.dart';
import 'package:lifeprint/services/family_tree_service.dart';
import 'package:lifeprint/models/memory_model.dart';
import 'package:lifeprint/models/family_member_model.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _releaseDateController = TextEditingController();
  final Set<String> _selectedEmotions = <String>{};
  final List<String> _allEmotions = const [
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
  final List<String> _linkedFamilyMemberNames = <String>[];
  final List<FamilyMember> _availableFamilyMembers = <FamilyMember>[];
  final FamilyTreeService _familyService = FamilyTreeService();

  dynamic _selectedFile; // Can be File (mobile) or Uint8List (web)
  String? _selectedFileName;
  MemoryType _selectedType = MemoryType.photo;
  DateTime? _releaseDate;
  bool _isLoading = false;
  bool _isUploading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _titleController.dispose();
    _releaseDateController.dispose();
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
              // Custom App Bar
              _buildCustomAppBar(context),
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Media Selection Section
                            _buildMediaSelectionSection(),
                            const SizedBox(height: 24),

                            // Memory Type Selection
                            _buildTypeSelectionSection(),
                            const SizedBox(height: 24),

                            // Title Input
                            _buildTitleInput(),
                            const SizedBox(height: 24),

                            // Release Date Input
                            _buildReleaseDateInput(),
                            const SizedBox(height: 24),

                            // Emotion Tags (UI-only)
                            _buildEmotionTagsSection(),
                            const SizedBox(height: 24),

                            // Link Family Members (UI-only)
                            _buildLinkFamilyMembersSection(),
                            const SizedBox(height: 32),

                            // Upload Button
                            _buildUploadButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Title
          Text(
            'Add Memory',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Placeholder for symmetry
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMediaSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Select Media',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
                    _getFileIcon(_selectedFileName),
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName ?? 'Selected file',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          kIsWeb
                              ? 'Web file selected'
                              : CloudinaryService.getFileSizeString(
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
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isUploading ? null : _selectImage,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Photo',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isUploading ? null : _selectVideo,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Video',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isUploading ? null : _selectAudio,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.audiotrack, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Audio File',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Memory Type',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MemoryType.values.map((type) {
              return ChoiceChip(
                label: Text(
                  type.displayName,
                  style: GoogleFonts.poppins(
                    color: _selectedType == type
                        ? Colors.black
                        : const Color.fromARGB(255, 222, 136, 241),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: _selectedType == type,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedType = type;
                    });
                  }
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.1),
                checkmarkColor: Colors.black,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.title, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Memory Title',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter a title for your memory',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.6),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 2),
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
    );
  }

  Widget _buildReleaseDateInput() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Release Date (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _releaseDateController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Select when this memory should be released',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.6),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              suffixIcon: IconButton(
                onPressed: _selectReleaseDate,
                icon: const Icon(Icons.calendar_today, color: Colors.white),
              ),
            ),
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionTagsSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Emotion Tags',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allEmotions.map((emotion) {
              final isSelected = _selectedEmotions.contains(emotion);
              return FilterChip(
                label: Text(
                  emotion,
                  style: GoogleFonts.poppins(
                    color: isSelected
                        ? Colors.black
                        : const Color.fromARGB(255, 222, 136, 241),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedEmotions.add(emotion);
                    } else {
                      _selectedEmotions.remove(emotion);
                    }
                  });
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.1),
                checkmarkColor: Colors.black,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkFamilyMembersSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Link Family Members',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_linkedFamilyMemberNames.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _linkedFamilyMemberNames.map((name) {
                final member = _availableFamilyMembers.firstWhere(
                  (m) => m.name == name,
                  orElse: () => FamilyMember(
                    id: '',
                    name: name,
                    relation: 'Unknown',
                    linkedUserId: '',
                    createdAt: DateTime.now(),
                    createdBy: '',
                  ),
                );
                return Chip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name),
                      Text(
                        member.relation,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.white.withOpacity(0.9),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _linkedFamilyMemberNames.remove(name);
                    });
                  },
                );
              }).toList(),
            ),
          if (_linkedFamilyMemberNames.isNotEmpty) const SizedBox(height: 12),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openLinkFamilySheet,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Choose Family Members',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final relationships = await _familyService.getUserRelationships(user.uid);
      final familyMembers = <FamilyMember>[];

      for (final relationship in relationships) {
        // Get user data for the linked user
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(relationship.toUserId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final familyMember = FamilyMember(
            id: relationship.toUserId,
            name: userData['name'] ?? 'Unknown',
            relation: relationship.relation,
            linkedUserId: relationship.toUserId,
            profileImageUrl: userData['Profile Image URL'],
            createdAt: relationship.createdAt,
            createdBy: relationship.fromUserId,
          );
          familyMembers.add(familyMember);
        }
      }

      setState(() {
        _availableFamilyMembers.clear();
        _availableFamilyMembers.addAll(familyMembers);
      });
    } catch (e) {
      print('Error loading family members: $e');
    }
  }

  void _openLinkFamilySheet() {
    if (_availableFamilyMembers.isEmpty) {
      _showSnackBar(
        'No family members found. Add family members first.',
        isError: true,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final Set<String> tempSelection = _linkedFamilyMemberNames.toSet();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Family Members',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableFamilyMembers.length,
                        itemBuilder: (context, index) {
                          final member = _availableFamilyMembers[index];
                          final selected = tempSelection.contains(member.name);
                          return CheckboxListTile(
                            title: Text(member.name),
                            subtitle: Text(member.relation),
                            value: selected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  tempSelection.add(member.name);
                                } else {
                                  tempSelection.remove(member.name);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _linkedFamilyMemberNames
                              ..clear()
                              ..addAll(tempSelection);
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUploadButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (_isLoading || _isUploading || _selectedFile == null)
              ? null
              : _uploadMemory,
          child: Center(
            child: _isLoading || _isUploading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isUploading ? 'Uploading...' : 'Saving...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Upload Memory',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String? filePath) {
    if (filePath == null) return Icons.insert_drive_file;

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
        // Web platform - use file picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _selectedFile = result.files.single.bytes!;
            _selectedFileName = result.files.single.name;
            _selectedType = MemoryType.photo;
          });
        }
      } else {
        // Mobile/Desktop platform
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedFile = File(image.path);
            _selectedFileName = image.name;
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
      if (kIsWeb) {
        // Web platform - use file picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _selectedFile = result.files.single.bytes!;
            _selectedFileName = result.files.single.name;
            _selectedType = MemoryType.video;
          });
        }
      } else {
        // Mobile/Desktop platform
        final ImagePicker picker = ImagePicker();
        final XFile? video = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 10),
        );

        if (video != null) {
          setState(() {
            _selectedFile = File(video.path);
            _selectedFileName = video.name;
            _selectedType = MemoryType.video;
          });
        }
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

      if (result != null) {
        if (kIsWeb) {
          // Web platform
          if (result.files.single.bytes != null) {
            setState(() {
              _selectedFile = result.files.single.bytes!;
              _selectedFileName = result.files.single.name;
              _selectedType = MemoryType.audio;
            });
          }
        } else {
          // Mobile/Desktop platform
          if (result.files.single.path != null) {
            setState(() {
              _selectedFile = File(result.files.single.path!);
              _selectedFileName = result.files.single.name;
              _selectedType = MemoryType.audio;
            });
          }
        }
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

  Future<void> _uploadMemory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      _showSnackBar('Please select a file', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      // Upload file to Cloudinary
      String? cloudinaryUrl = await CloudinaryService.uploadFile(
        _selectedFile!,
      );

      if (cloudinaryUrl == null) {
        throw Exception('Failed to upload file to Cloudinary');
      }

      setState(() {
        _isUploading = false;
      });

      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get linked family member IDs
      List<String> linkedUserIds = [user.uid]; // Always include creator

      // Add selected family members
      for (final familyMemberName in _linkedFamilyMemberNames) {
        final familyMember = _availableFamilyMembers.firstWhere(
          (member) => member.name == familyMemberName,
          orElse: () =>
              throw Exception('Family member not found: $familyMemberName'),
        );
        linkedUserIds.add(familyMember.linkedUserId);
      }

      // Create memory model
      MemoryModel memory = MemoryModel(
        id: '', // Will be generated by Firestore
        title: _titleController.text.trim(),
        type: _selectedType,
        cloudinaryUrl: cloudinaryUrl,
        emotions: _selectedEmotions.toList(),
        releaseDate: _releaseDate,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        linkedUserIds:
            linkedUserIds, // Include creator and selected family members
      );

      // Save to Firestore using MemoryService
      MemoryService memoryService = MemoryService();
      await memoryService.addMemory(memory);

      String successMessage = 'Memory uploaded successfully!';
      if (_linkedFamilyMemberNames.isNotEmpty) {
        successMessage +=
            ' Linked to ${_linkedFamilyMemberNames.length} family member(s).';
      }
      _showSnackBar(successMessage, isError: false);

      // Navigate back to home
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar('Error uploading memory: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
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
