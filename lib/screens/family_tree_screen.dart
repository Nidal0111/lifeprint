import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeprint/models/family_member_model.dart';
import 'package:lifeprint/services/family_tree_service.dart';
import 'package:lifeprint/screens/modern_home_screen.dart';
import 'package:lifeprint/screens/add_family_member_screen.dart';
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
      if (_familyMembers.containsKey(relationship.fromUserId) &&
          _familyMembers.containsKey(relationship.toUserId)) {
        _graph!.addEdge(
          Node.Id(relationship.fromUserId),
          Node.Id(relationship.toUserId),
        );
      }
    }
  }

  void _openUserMemories(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernHomeScreen(selectedUserId: userId),
      ),
    );
  }

  // Removed unused bottom nav builder (handled by respective screens)

  Widget _buildFamilyTreeInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Family Tree',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap on any family member to view their memories. Use the + button to add new family members.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  '${_familyMembers.length} family members',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[600],
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
    if (_graph == null || _graph!.nodeCount == 0) {
      return const Center(
        child: Text(
          'No family members found. Add some family members to see the tree.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_graph!.nodeCount == 1) {
      // Fallback UI for a single node to avoid GraphView layout issues
      final member = _familyMembers.values.first;
      return Center(
        child: GestureDetector(
          onTap: () => _openUserMemories(member.linkedUserId),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl == null
                      ? Text(
                          member.name[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  member.relation,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // On web, GraphView can produce NaN sizes. Use a grid fallback there.
    if (kIsWeb) {
      final members = _familyMembers.values.toList(growable: false);
      return Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = (constraints.maxWidth ~/ 180).clamp(1, 6);
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return GestureDetector(
                  onTap: () => _openUserMemories(member.linkedUserId),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: member.profileImageUrl != null
                              ? NetworkImage(member.profileImageUrl!)
                              : null,
                          child: member.profileImageUrl == null
                              ? Text(
                                  member.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          member.relation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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

        return SizedBox(
          width: width,
          height: height,
          child: InteractiveViewer(
            constrained: true,
            boundaryMargin: const EdgeInsets.all(24),
            minScale: 0.5,
            maxScale: 3.0,
            child: GraphView(
              graph: _graph!,
              algorithm: SugiyamaAlgorithm(
                SugiyamaConfiguration()
                  ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
                  ..nodeSeparation = 32
                  ..levelSeparation = 56,
              ),
              builder: (node) {
                final String keyStr =
                    node.key?.value?.toString() ?? node.key?.toString() ?? '';
                final member = _familyMembers[keyStr];
                if (member == null) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () => _openUserMemories(member.linkedUserId),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: member.profileImageUrl != null
                              ? NetworkImage(member.profileImageUrl!)
                              : null,
                          child: member.profileImageUrl == null
                              ? Text(
                                  member.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          member.relation,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
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
                        'Family Tree',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadFamilyTree,
                      tooltip: 'Refresh Family Tree',
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
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(12),
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
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}
