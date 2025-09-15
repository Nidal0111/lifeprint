import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeprint/models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Create a new event
  Future<String> createEvent(EventModel event) async {
    try {
      final now = DateTime.now();
      final data = event
          .copyWith(
            id: '',
            userId: _userId,
            createdAt: event.createdAt,
            updatedAt: now,
          )
          .toMap();

      // Ensure mandatory fields are present
      data['userId'] = _userId;
      data['createdAt'] = data['createdAt'] ?? Timestamp.fromDate(now);
      data['updatedAt'] = Timestamp.fromDate(now);

      final docRef = await _firestore.collection('events').add(data);

      // Update the event with the generated ID
      await _firestore.collection('events').doc(docRef.id).update({
        'id': docRef.id,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Get all events for the current user
  Future<List<EventModel>> getUserEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: _userId)
          .get();

      final list = querySnapshot.docs
          .map((doc) => EventModel.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    } catch (e) {
      throw Exception('Failed to get events: $e');
    }
  }

  // Get events for a specific date
  Future<List<EventModel>> getEventsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: _userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date')
          .get();

      final list = querySnapshot.docs
          .map((doc) => EventModel.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        // Fallback: fetch all user events and filter client-side to avoid index requirement
        final all = await getUserEvents();
        return all
            .where(
              (ev) =>
                  !ev.date.isBefore(startOfDay) && !ev.date.isAfter(endOfDay),
            )
            .toList();
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to get events for date: $e');
    }
  }

  // Get upcoming events (next 7 days)
  Future<List<EventModel>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      try {
        final querySnapshot = await _firestore
            .collection('events')
            .where('userId', isEqualTo: _userId)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(nextWeek))
            .orderBy('date')
            .get();

        final list = querySnapshot.docs
            .map((doc) => EventModel.fromMap(doc.data()))
            .toList();
        list.sort((a, b) => a.date.compareTo(b.date));
        return list;
      } on FirebaseException catch (e) {
        if (e.code == 'failed-precondition') {
          final all = await getUserEvents();
          return all
              .where(
                (ev) => !ev.date.isBefore(now) && !ev.date.isAfter(nextWeek),
              )
              .toList();
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Failed to get upcoming events: $e');
    }
  }

  // Get today's events
  Future<List<EventModel>> getTodaysEvents() async {
    try {
      final today = DateTime.now();
      return await getEventsForDate(today);
    } catch (e) {
      throw Exception('Failed to get today\'s events: $e');
    }
  }

  // Update an event
  Future<void> updateEvent(EventModel event) async {
    try {
      final now = DateTime.now();
      final data = event
          .copyWith(
            userId: event.userId.isEmpty ? _userId : event.userId,
            updatedAt: now,
          )
          .toMap();
      data['userId'] = data['userId'] ?? _userId;
      data['updatedAt'] = Timestamp.fromDate(now);

      await _firestore.collection('events').doc(event.id).update(data);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Get events stream for real-time updates
  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection('events')
        .where('userId', isEqualTo: _userId)
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get today's events stream
  Stream<List<EventModel>> getTodaysEventsStream() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection('events')
        .where('userId', isEqualTo: _userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get events by type
  Future<List<EventModel>> getEventsByType(String type) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: _userId)
          .where('type', isEqualTo: type)
          .get();

      final list = querySnapshot.docs
          .map((doc) => EventModel.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    } catch (e) {
      throw Exception('Failed to get events by type: $e');
    }
  }

  // Search events by title
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: _userId)
          .get();

      final allEvents = querySnapshot.docs
          .map((doc) => EventModel.fromMap(doc.data()))
          .toList();

      return allEvents
          .where(
            (event) =>
                event.title.toLowerCase().contains(query.toLowerCase()) ||
                event.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }
}
