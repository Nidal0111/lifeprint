import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeprint/models/family_member_model.dart';
import 'package:lifeprint/services/family_tree_service.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final FamilyTreeService _familyTreeService = FamilyTreeService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  
  String _selectedRelation = 'parent';
  String? _selectedUserId;
  bool _isLoading = false;
  bool _isAddingMember = false;
  bool _isSearching = false;
  bool _isDeleting = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<FamilyMember> _existingMembers = [];

  final List<String> _relationTypes = [
    'parent',
    'child',
    'spouse',
    'sibling',
    'grandparent',
    'grandchild',
    'uncle',
    'aunt',
    'cousin',
    'nephew',
    'niece',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final relationships = await _familyTreeService.getUserRelationships(userId);
      
      // Get family member details for each relationship
      final members = <FamilyMember>[];
      for (final relationship in relationships) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(relationship.toUserId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final member = FamilyMember(
              id: relationship.id,
              name: userData['Full Name'] ?? 'Unknown',
              relation: relationship.relation,
              linkedUserId: relationship.toUserId,
              profileImageUrl: userData['Profile Image URL'],
              createdAt: relationship.createdAt,
              createdBy: relationship.fromUserId,
            );
            members.add(member);
          }
        } catch (e) {
          print('Error loading member ${relationship.toUserId}: $e');
        }
      }

      setState(() {
        _existingMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading family members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _familyTreeService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addFamilyMember() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user to add'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAddingMember = true;
    });

    try {
      await _familyTreeService.addFamilyMember(
        name: _nameController.text.trim(),
        relation: _selectedRelation,
        linkedUserId: _selectedUserId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family member added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _nameController.clear();
        _searchController.clear();
        _selectedUserId = null;
        _searchResults = [];
        
        // Reload existing members
        await _loadExistingMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding family member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingMember = false;
        });
      }
    }
  }

  Future<void> _deleteFamilyMember(String relationshipId) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _familyTreeService.deleteFamilyMember(relationshipId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family member deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload existing members
        await _loadExistingMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting family member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showDeleteConfirmation(String memberName, String relationshipId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Family Member'),
          content: Text('Are you sure you want to delete $memberName from your family tree?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFamilyMember(relationshipId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddMemberForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Family Member',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Relation dropdown
              DropdownButtonFormField<String>(
                value: _selectedRelation,
                decoration: const InputDecoration(
                  labelText: 'Relation Type',
                  border: OutlineInputBorder(),
                ),
                items: _relationTypes.map((String relation) {
                  return DropdownMenuItem<String>(
                    value: relation,
                    child: Text(relation.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRelation = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // User search field
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search for user (optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
                onChanged: _searchUsers,
              ),
              const SizedBox(height: 16),
              
              // Search results
              if (_searchResults.isNotEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isSelected = _selectedUserId == user['id'];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['profileImageUrl'] != null
                              ? NetworkImage(user['profileImageUrl'])
                              : null,
                          child: user['profileImageUrl'] == null
                              ? Text(user['name'][0].toUpperCase())
                              : null,
                        ),
                        title: Text(user['name']),
                        subtitle: Text(user['email']),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedUserId = user['id'];
                          });
                        },
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Add button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAddingMember ? null : _addFamilyMember,
                  child: _isAddingMember
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Adding...'),
                          ],
                        )
                      : const Text('Add Family Member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingMembersList() {
    if (_existingMembers.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No family members found. Add some family members to get started.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Existing Family Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _existingMembers.length,
              itemBuilder: (context, index) {
                final member = _existingMembers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.profileImageUrl != null
                          ? NetworkImage(member.profileImageUrl!)
                          : null,
                      child: member.profileImageUrl == null
                          ? Text(member.name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(member.name),
                    subtitle: Text(member.relation.toUpperCase()),
                    trailing: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(
                              member.name,
                              member.id,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Family Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExistingMembers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildAddMemberForm(),
                  _buildExistingMembersList(),
                ],
              ),
            ),
    );
  }
}
