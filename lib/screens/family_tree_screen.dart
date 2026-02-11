import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeprint/models/family_member_model.dart';
import 'package:lifeprint/services/family_tree_service.dart';
import 'package:lifeprint/screens/modern_home_screen.dart';
import 'package:lifeprint/screens/add_family_member_screen.dart';
import 'package:lifeprint/screens/albums_screen.dart';
import 'package:lifeprint/screens/notes_calendar_screen.dart';
import 'package:graphview/graphview.dart';

class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final FamilyTreeService _familyTreeService = FamilyTreeService();

  bool _isLoading = false;
  Map<String, FamilyMember> _familyMembers = {};
  List<Relationship> _relationships = [];
  Graph? _graph;
  int _currentIndex = 2; // Family tab

  @override
  void initState() {
    super.initState();
    _loadFamilyTree();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFamilyTree() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final familyMembers = await _familyTreeService.getFamilyTree(
        userId,
        maxDepth: 3,
      );
      final relationships = await _familyTreeService.getFamilyRelationships(
        userId,
        maxDepth: 3,
      );

      setState(() {
        _familyMembers = familyMembers;
        _relationships = relationships;
        _buildGraph();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading family tree: $e'),
            backgroundColor: Colors.red,
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

  void _buildGraph() {
    _graph = Graph()..isTree = false;

    // Add nodes for all family members
    for (final member in _familyMembers.values) {
      _graph!.addNode(Node.Id(member.id));
    }

    // Add edges for relationships
    for (final relationship in _relationships) {
      final targetId = relationship.toUserId ?? 'unlinked_${relationship.id}';

      if (_familyMembers.containsKey(relationship.fromUserId) &&
          _familyMembers.containsKey(targetId)) {
        _graph!.addEdge(Node.Id(relationship.fromUserId), Node.Id(targetId));
      }
    }
  }

  void _openUserMemories(String? userId) {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This family member is not linked to a user account.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernHomeScreen(selectedUserId: userId),
      ),
    );
  }

  // Removed unused bottom nav builder (handled by respective screens)

  Widget _buildFamilyTreeInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final cardPadding = isSmallScreen ? 12.0 : 16.0;
    final titleFontSize = isSmallScreen ? 18.0 : 20.0;
    final bodyFontSize = isSmallScreen ? 13.0 : 14.0;
    final countFontSize = isSmallScreen ? 14.0 : 16.0;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 12,
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Tree',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'Tap on any family member to view their memories. Use the + button to add new family members.',
              style: TextStyle(fontSize: bodyFontSize, color: Colors.grey[600]),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Colors.blue[600],
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Flexible(
                  child: Text(
                    '${_familyMembers.length} family members',
                    style: TextStyle(
                      fontSize: countFontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyTree() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;

    if (_graph == null || _graph!.nodeCount == 0) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Text(
            'No family members found. Add some family members to see the tree.',
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_graph!.nodeCount == 1) {
      // Fallback UI for a single node to avoid GraphView layout issues
      final member = _familyMembers.values.first;
      final avatarRadius = isSmallScreen ? 24.0 : 28.0;
      final nameFontSize = isSmallScreen ? 13.0 : 14.0;
      final relationFontSize = isSmallScreen ? 11.0 : 12.0;

      return Center(
        child: GestureDetector(
          onTap: () => _openUserMemories(member.linkedUserId),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.white,
                  backgroundImage: member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl == null
                      ? Text(
                          member.name[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 20 : 24,
                            color: const Color(0xFF764ba2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                member.name,
                style: GoogleFonts.poppins(
                  fontSize: nameFontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                RelationshipType.getDisplayName(member.relation),
                style: GoogleFonts.poppins(
                  fontSize: relationFontSize + 1,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    // On web, GraphView can produce NaN sizes. Use a grid fallback there.
    if (kIsWeb) {
      final members = _familyMembers.values.toList(growable: false);
      return Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            if (isSmallScreen) {
              crossAxisCount = (constraints.maxWidth ~/ 140).clamp(2, 4);
            } else if (isMediumScreen) {
              crossAxisCount = (constraints.maxWidth ~/ 160).clamp(3, 5);
            } else {
              crossAxisCount = (constraints.maxWidth ~/ 180).clamp(4, 6);
            }

            final avatarRadius = isSmallScreen
                ? 20.0
                : (isMediumScreen ? 22.0 : 24.0);
            final nameFontSize = isSmallScreen ? 11.0 : 12.0;
            final relationFontSize = isSmallScreen ? 9.0 : 10.0;
            final cardPadding = isSmallScreen ? 6.0 : 8.0;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isSmallScreen ? 8 : 12,
                mainAxisSpacing: isSmallScreen ? 8 : 12,
                childAspectRatio: isSmallScreen ? 1.1 : 1.2,
              ),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return GestureDetector(
                  onTap: () => _openUserMemories(member.linkedUserId),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.white,
                          backgroundImage: member.profileImageUrl != null
                              ? NetworkImage(member.profileImageUrl!)
                              : null,
                          child: member.profileImageUrl == null
                              ? Text(
                                  member.name[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: const Color(0xFF764ba2),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        RelationshipType.getDisplayName(member.relation),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: relationFontSize,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 400;

        final nodeSeparation = isSmallScreen ? 60.0 : 80.0;
        final levelSeparation = isSmallScreen ? 80.0 : 100.0;
        final boundaryMargin = isSmallScreen ? 20.0 : 30.0;
        final avatarRadius = isSmallScreen ? 28.0 : 34.0;
        final nameFontSize = isSmallScreen ? 11.0 : 13.0;
        final relationFontSize = isSmallScreen ? 10.0 : 11.0;

        return SizedBox(
          width: width,
          height: height,
          child: InteractiveViewer(
            constrained: true,
            boundaryMargin: EdgeInsets.all(boundaryMargin),
            minScale: 0.5,
            maxScale: 3.0,
            child: GraphView(
              graph: _graph!,
              paint: Paint()
                ..color = Colors.white.withOpacity(0.8)
                ..strokeWidth = 3.0
                ..style = PaintingStyle.stroke,
              algorithm: SugiyamaAlgorithm(
                SugiyamaConfiguration()
                  ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
                  ..nodeSeparation = nodeSeparation.toInt()
                  ..levelSeparation = levelSeparation.toInt(),
              ),
              builder: (node) {
                final String keyStr =
                    node.key?.value?.toString() ?? node.key?.toString() ?? '';
                final member = _familyMembers[keyStr];
                if (member == null) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () => _openUserMemories(member.linkedUserId),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.white,
                          backgroundImage: member.profileImageUrl != null
                              ? NetworkImage(member.profileImageUrl!)
                              : null,
                          child: member.profileImageUrl == null
                              ? Text(
                                  member.name[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 18 : 22,
                                    color: const Color(0xFF764ba2),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        member.name,
                        style: GoogleFonts.poppins(
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        RelationshipType.getDisplayName(member.relation),
                        style: GoogleFonts.poppins(
                          fontSize: relationFontSize,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
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
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Navigate to different screens based on index
          switch (index) {
            case 0:
              // Home
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ModernHomeScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(-1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
              break;
            case 1:
              // Memories - navigate to albums screen
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const AlbumsScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(-1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
              break;
            case 2:
              // Family - already here
              break;
            case 3:
              // Notes - navigate to notes calendar screen
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const NotesCalendarScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
              break;
          }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;

    // Responsive padding and sizing
    final appBarHorizontalPadding = isSmallScreen ? 8.0 : 16.0;
    final appBarVerticalPadding = isSmallScreen ? 8.0 : 12.0;
    final titleFontSize = isSmallScreen ? 20.0 : 24.0;
    final iconSize = isSmallScreen ? 22.0 : 24.0;
    final containerMargin = isSmallScreen
        ? 8.0
        : (isMediumScreen ? 12.0 : 16.0);
    final fabIconSize = isSmallScreen ? 20.0 : 24.0;
    final fabLabelSize = isSmallScreen ? 13.0 : 14.0;

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
                padding: EdgeInsets.symmetric(
                  horizontal: appBarHorizontalPadding,
                  vertical: appBarVerticalPadding,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: iconSize,
                      ),
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: Text(
                        'Family Tree',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: titleFontSize,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: iconSize,
                      ),
                      onPressed: _loadFamilyTree,
                      tooltip: 'Refresh Family Tree',
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          _buildFamilyTreeInfo(),
                          SizedBox(height: isSmallScreen ? 8 : 16),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(containerMargin),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 8 : 12,
                                ),
                              ),
                              child: _buildFamilyTree(),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isSmallScreen
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const AddFamilyMemberScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: animation.drive(
                                  Tween(
                                    begin: const Offset(0.0, 1.0),
                                    end: Offset.zero,
                                  ).chain(CurveTween(curve: Curves.easeInOut)),
                                ),
                                child: child,
                              );
                            },
                      ),
                    )
                    .then((_) => _loadFamilyTree());
              },
              child: Icon(Icons.person_add, size: fabIconSize),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              tooltip: 'Add Member',
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const AddFamilyMemberScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: animation.drive(
                                  Tween(
                                    begin: const Offset(0.0, 1.0),
                                    end: Offset.zero,
                                  ).chain(CurveTween(curve: Curves.easeInOut)),
                                ),
                                child: child,
                              );
                            },
                      ),
                    )
                    .then((_) => _loadFamilyTree());
              },
              icon: Icon(Icons.person_add, size: fabIconSize),
              label: Text(
                'Add Member',
                style: TextStyle(fontSize: fabLabelSize),
              ),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
