import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeprint/models/family_member_model.dart';
import 'package:lifeprint/services/family_tree_service.dart';
import 'package:lifeprint/screens/home_screen.dart';
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
    _graph = Graph();

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
        builder: (context) => HomeScreen(selectedUserId: userId),
      ),
    );
  }

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

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: GraphView(
        graph: _graph!,
        algorithm: SugiyamaAlgorithm(
          SugiyamaConfiguration()
            ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM,
        ),
        builder:
            (context, node) {
                  final member = _familyMembers[node.key.toString()];
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
                }
                as NodeWidgetBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Tree'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFamilyTree,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildFamilyTreeInfo(),
                  const SizedBox(height: 16),
                  Container(
                    height: 600,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildFamilyTree(),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const AddFamilyMemberScreen(),
                ),
              )
              .then((_) {
                // Reload family tree when returning from add member screen
                _loadFamilyTree();
              });
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}
