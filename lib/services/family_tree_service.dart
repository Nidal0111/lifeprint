import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeprint/models/family_member_model.dart';

class FamilyTreeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Add a family member relationship
  Future<String> addFamilyMember({
    required String name,
    required String relation,
    required String linkedUserId,
    String? profileImageUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception("User not logged in.");
    }

    try {
      final relationshipId = _firestore.collection('relationships').doc().id;

      // Create relationship document
      final relationship = Relationship(
        id: relationshipId,
        fromUserId: currentUserId!,
        toUserId: linkedUserId,
        relation: relation,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('relationships')
          .doc(relationshipId)
          .set(relationship.toMap());

      // Add to user's relationships array
      await _firestore.collection('users').doc(currentUserId!).update({
        'relationships': FieldValue.arrayUnion([relationshipId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Family member added successfully with ID: $relationshipId');
      return relationshipId;
    } catch (e) {
      print('Error adding family member: $e');
      rethrow;
    }
  }

  /// Get all relationships for a user
  Future<List<Relationship>> getUserRelationships(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final relationshipIds = List<String>.from(
        userData['relationships'] ?? [],
      );

      if (relationshipIds.isEmpty) {
        return [];
      }

      final relationships = await _firestore
          .collection('relationships')
          .where(FieldPath.documentId, whereIn: relationshipIds)
          .get();

      return relationships.docs
          .map((doc) => Relationship.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error getting user relationships: $e');
      rethrow;
    }
  }

  /// Recursively fetch family members to a specified depth
  Future<Map<String, FamilyMember>> getFamilyTree(
    String userId, {
    int maxDepth = 3,
  }) async {
    final familyMembers = <String, FamilyMember>{};
    final visited = <String>{};
    final queue = <String, int>{}; // userId -> depth

    queue[userId] = 0;
    visited.add(userId);

    while (queue.isNotEmpty) {
      final currentUserId = queue.keys.first;
      final currentDepth = queue[currentUserId]!;
      queue.remove(currentUserId);

      if (currentDepth >= maxDepth) continue;

      try {
        // Get user data
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data() as Map<String, dynamic>;

        // Create family member from user data
        final familyMember = FamilyMember(
          id: currentUserId,
          name: userData['Full Name'] ?? 'Unknown',
          relation: currentDepth == 0 ? 'Self' : 'Family Member',
          linkedUserId: currentUserId,
          profileImageUrl: userData['Profile Image URL'],
          createdAt: DateTime.now(),
          createdBy: currentUserId,
        );

        familyMembers[currentUserId] = familyMember;

        // Get relationships for this user
        final relationships = await getUserRelationships(currentUserId);

        for (final relationship in relationships) {
          final relatedUserId = relationship.toUserId;

          if (!visited.contains(relatedUserId) && currentDepth < maxDepth - 1) {
            visited.add(relatedUserId);
            queue[relatedUserId] = currentDepth + 1;
          }
        }
      } catch (e) {
        print('Error fetching family member $currentUserId: $e');
        continue;
      }
    }

    return familyMembers;
  }

  /// Get relationships for building the tree structure
  Future<List<Relationship>> getFamilyRelationships(
    String userId, {
    int maxDepth = 3,
  }) async {
    final allRelationships = <Relationship>[];
    final visited = <String>{};
    final queue = <String, int>{}; // userId -> depth

    queue[userId] = 0;
    visited.add(userId);

    while (queue.isNotEmpty) {
      final currentUserId = queue.keys.first;
      final currentDepth = queue[currentUserId]!;
      queue.remove(currentUserId);

      if (currentDepth >= maxDepth) continue;

      try {
        final relationships = await getUserRelationships(currentUserId);
        allRelationships.addAll(relationships);

        for (final relationship in relationships) {
          final relatedUserId = relationship.toUserId;

          if (!visited.contains(relatedUserId) && currentDepth < maxDepth - 1) {
            visited.add(relatedUserId);
            queue[relatedUserId] = currentDepth + 1;
          }
        }
      } catch (e) {
        print('Error fetching relationships for $currentUserId: $e');
        continue;
      }
    }

    return allRelationships;
  }

  /// Delete a family member relationship
  Future<void> deleteFamilyMember(String relationshipId) async {
    if (currentUserId == null) {
      throw Exception("User not logged in.");
    }

    try {
      // Get the relationship to find the fromUserId
      final relationshipDoc = await _firestore
          .collection('relationships')
          .doc(relationshipId)
          .get();

      if (!relationshipDoc.exists) {
        throw Exception("Relationship not found.");
      }

      final relationship = Relationship.fromDocument(relationshipDoc);

      // Remove from user's relationships array
      await _firestore.collection('users').doc(relationship.fromUserId).update({
        'relationships': FieldValue.arrayRemove([relationshipId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Delete the relationship document
      await _firestore.collection('relationships').doc(relationshipId).delete();

      print('Family member deleted successfully: $relationshipId');
    } catch (e) {
      print('Error deleting family member: $e');
      rethrow;
    }
  }

  /// Search for users by name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      // Search by name
      final nameQuery = await _firestore
          .collection('users')
          .where('Full Name', isGreaterThanOrEqualTo: query)
          .where('Full Name', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      // Search by email
      final emailQuery = await _firestore
          .collection('users')
          .where('Email Address', isGreaterThanOrEqualTo: query)
          .where('Email Address', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      final results = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      // Add name results
      for (final doc in nameQuery.docs) {
        final data = doc.data();
        final userId = doc.id;

        if (!seenIds.contains(userId)) {
          seenIds.add(userId);
          results.add({
            'id': userId,
            'name': data['Full Name'] ?? 'Unknown',
            'email': data['Email Address'] ?? '',
            'profileImageUrl': data['Profile Image URL'],
          });
        }
      }

      // Add email results
      for (final doc in emailQuery.docs) {
        final data = doc.data();
        final userId = doc.id;

        if (!seenIds.contains(userId)) {
          seenIds.add(userId);
          results.add({
            'id': userId,
            'name': data['Full Name'] ?? 'Unknown',
            'email': data['Email Address'] ?? '',
            'profileImageUrl': data['Profile Image URL'],
          });
        }
      }

      return results;
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  /// Get user's family tree statistics
  Future<Map<String, int>> getFamilyTreeStats(String userId) async {
    try {
      final familyMembers = await getFamilyTree(userId, maxDepth: 3);
      final relationships = await getFamilyRelationships(userId, maxDepth: 3);

      return {
        'totalMembers': familyMembers.length,
        'totalRelationships': relationships.length,
        'depth': 3,
      };
    } catch (e) {
      print('Error getting family tree stats: $e');
      rethrow;
    }
  }
}
