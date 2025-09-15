import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeprint/models/memory_model.dart';

class MemoryService {
  static const String _collectionName = 'memories';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new memory to Firestore
  Future<String> addMemory(MemoryModel memory) async {
    try {
      // Generate a unique ID if not provided
      String memoryId = memory.id.isEmpty
          ? _firestore.collection(_collectionName).doc().id
          : memory.id;

      // Create memory with generated ID
      MemoryModel memoryWithId = memory.copyWith(id: memoryId);

      // Add to Firestore
      await _firestore
          .collection(_collectionName)
          .doc(memoryId)
          .set(memoryWithId.toMap());

      print('Memory added successfully with ID: $memoryId');
      return memoryId;
    } catch (e) {
      print('Error adding memory: $e');
      throw Exception('Failed to add memory: $e');
    }
  }

  /// Get all memories for a specific user
  Future<List<MemoryModel>> getMemories(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<MemoryModel> memories = snapshot.docs
          .map((doc) => MemoryModel.fromDocument(doc))
          .toList();

      print('Retrieved ${memories.length} memories for user: $userId');
      return memories;
    } catch (e) {
      print('Error getting memories: $e');
      throw Exception('Failed to get memories: $e');
    }
  }

  /// Get memories shared with a specific user
  Future<List<MemoryModel>> getSharedMemories(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('linkedUserIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<MemoryModel> memories = snapshot.docs
          .map((doc) => MemoryModel.fromDocument(doc))
          .toList();

      print('Retrieved ${memories.length} shared memories for user: $userId');
      return memories;
    } catch (e) {
      print('Error getting shared memories: $e');
      throw Exception('Failed to get shared memories: $e');
    }
  }

  /// Get all memories (own + shared) for a user
  Future<List<MemoryModel>> getAllMemories(String userId) async {
    try {
      // Get own memories
      List<MemoryModel> ownMemories = await getMemories(userId);

      // Get shared memories
      List<MemoryModel> sharedMemories = await getSharedMemories(userId);

      // Combine and remove duplicates
      List<MemoryModel> allMemories = [...ownMemories, ...sharedMemories];
      allMemories = allMemories.toSet().toList(); // Remove duplicates

      // Sort by creation date
      allMemories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Retrieved ${allMemories.length} total memories for user: $userId');
      return allMemories;
    } catch (e) {
      print('Error getting all memories: $e');
      throw Exception('Failed to get all memories: $e');
    }
  }

  /// Get a specific memory by ID
  Future<MemoryModel?> getMemory(String memoryId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(memoryId)
          .get();

      if (doc.exists) {
        return MemoryModel.fromDocument(doc);
      } else {
        print('Memory not found: $memoryId');
        return null;
      }
    } catch (e) {
      print('Error getting memory: $e');
      throw Exception('Failed to get memory: $e');
    }
  }

  /// Update a memory
  Future<void> updateMemory(String memoryId, Map<String, dynamic> data) async {
    try {
      // Add updatedAt timestamp
      data['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore.collection(_collectionName).doc(memoryId).update(data);

      print('Memory updated successfully: $memoryId');
    } catch (e) {
      print('Error updating memory: $e');
      throw Exception('Failed to update memory: $e');
    }
  }

  /// Update a memory using MemoryModel
  Future<void> updateMemoryModel(MemoryModel memory) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(memory.id)
          .update(memory.toMap());

      print('Memory updated successfully: ${memory.id}');
    } catch (e) {
      print('Error updating memory: $e');
      throw Exception('Failed to update memory: $e');
    }
  }

  /// Delete a memory
  Future<void> deleteMemory(String memoryId) async {
    try {
      await _firestore.collection(_collectionName).doc(memoryId).delete();

      print('Memory deleted successfully: $memoryId');
    } catch (e) {
      print('Error deleting memory: $e');
      throw Exception('Failed to delete memory: $e');
    }
  }

  /// Search memories by title or transcript
  Future<List<MemoryModel>> searchMemories(String userId, String query) async {
    try {
      // Get all memories for the user
      List<MemoryModel> allMemories = await getAllMemories(userId);

      // Filter memories based on search query
      List<MemoryModel> filteredMemories = allMemories.where((memory) {
        return memory.title.toLowerCase().contains(query.toLowerCase()) ||
            (memory.transcript?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();

      print('Found ${filteredMemories.length} memories matching query: $query');
      return filteredMemories;
    } catch (e) {
      print('Error searching memories: $e');
      throw Exception('Failed to search memories: $e');
    }
  }

  /// Get memories by type
  Future<List<MemoryModel>> getMemoriesByType(
    String userId,
    MemoryType type,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('createdBy', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .get();

      List<MemoryModel> memories = snapshot.docs
          .map((doc) => MemoryModel.fromDocument(doc))
          .toList();

      print(
        'Retrieved ${memories.length} ${type.name} memories for user: $userId',
      );
      return memories;
    } catch (e) {
      print('Error getting memories by type: $e');
      throw Exception('Failed to get memories by type: $e');
    }
  }

  /// Get memories by date range
  Future<List<MemoryModel>> getMemoriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('createdBy', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('createdAt', descending: true)
          .get();

      List<MemoryModel> memories = snapshot.docs
          .map((doc) => MemoryModel.fromDocument(doc))
          .toList();

      print(
        'Retrieved ${memories.length} memories for date range: $startDate to $endDate',
      );
      return memories;
    } catch (e) {
      print('Error getting memories by date range: $e');
      throw Exception('Failed to get memories by date range: $e');
    }
  }

  /// Share memory with other users
  Future<void> shareMemory(String memoryId, List<String> userIds) async {
    try {
      await _firestore.collection(_collectionName).doc(memoryId).update({
        'linkedUserIds': FieldValue.arrayUnion(userIds),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('Memory shared with ${userIds.length} users: $memoryId');
    } catch (e) {
      print('Error sharing memory: $e');
      throw Exception('Failed to share memory: $e');
    }
  }

  /// Unshare memory with users
  Future<void> unshareMemory(String memoryId, List<String> userIds) async {
    try {
      await _firestore.collection(_collectionName).doc(memoryId).update({
        'linkedUserIds': FieldValue.arrayRemove(userIds),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('Memory unshared with ${userIds.length} users: $memoryId');
    } catch (e) {
      print('Error unsharing memory: $e');
      throw Exception('Failed to unshare memory: $e');
    }
  }

  /// Get memory statistics for a user
  Future<Map<String, int>> getMemoryStats(String userId) async {
    try {
      List<MemoryModel> allMemories = await getAllMemories(userId);

      Map<String, int> stats = {
        'total': allMemories.length,
        'photo': allMemories.where((m) => m.type == MemoryType.photo).length,
        'video': allMemories.where((m) => m.type == MemoryType.video).length,
        'audio': allMemories.where((m) => m.type == MemoryType.audio).length,
        'text': allMemories.where((m) => m.type == MemoryType.text).length,
        'shared': allMemories.where((m) => m.linkedUserIds.isNotEmpty).length,
      };

      print('Memory stats for user $userId: $stats');
      return stats;
    } catch (e) {
      print('Error getting memory stats: $e');
      throw Exception('Failed to get memory stats: $e');
    }
  }
}
