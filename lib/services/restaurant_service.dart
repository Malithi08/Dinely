import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── TABLES ────────────────────────────────────────────────────────────────

  /// Stream real-time tables for a given restaurant
  Stream<List<Map<String, dynamic>>> streamTables(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .orderBy('number')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Update table status (Available, Occupied, Reserved, Cleaning)
  Future<void> updateTableStatus(String restaurantId, String tableDocId, String newStatus) async {
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .doc(tableDocId)
        .update({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Seed initial tables if collection is empty
  Future<void> seedDefaultTables(String restaurantId) async {
    final ref = _db.collection('restaurants').doc(restaurantId).collection('tables');
    final existing = await ref.limit(1).get();
    if (existing.docs.isEmpty) {
      final batch = _db.batch();
      for (int i = 1; i <= 15; i++) {
        final docRef = ref.doc('T${i < 10 ? '0$i' : i}');
        String status = 'Available';
        if (i % 3 == 0) {
          status = 'Occupied';
        } else if (i % 5 == 0) {
          status = 'Reserved';
        } else if (i == 14) {
          status = 'Cleaning';
        }

        String zone = 'Main Hall';
        if (i >= 6 && i < 11) zone = 'Patio';
        if (i >= 11) zone = 'VIP Lounge';

        batch.set(docRef, {
          'number': i,
          'capacity': (i % 3 == 0) ? 4 : (i % 2 == 0 ? 2 : 6),
          'status': status,
          'zone': zone,
          'server': i % 2 == 0 ? 'Marco D.' : 'Elena R.',
        });
      }
      await batch.commit();
    }
  }

  // ─── QUEUE / WAITLIST ─────────────────────────────────────────────────────

  /// Stream active queue list
  Stream<List<Map<String, dynamic>>> streamQueue(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('queue')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'docId': doc.id, ...doc.data()}).toList());
  }

  /// Add guest to waitlist queue
  Future<void> addQueueGuest({
    required String restaurantId,
    required String name,
    required int partySize,
    required String phone,
    required String quotedTime,
  }) async {
    final queueRef = _db.collection('restaurants').doc(restaurantId).collection('queue');
    final snapshot = await queueRef.get();
    final qNumber = 'Q-${(snapshot.docs.length + 1).toString().padLeft(2, '0')}';

    await queueRef.add({
      'qId': qNumber,
      'name': name,
      'party': partySize,
      'phone': phone,
      'quoted': quotedTime,
      'status': 'Waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove or seat guest from waitlist
  Future<void> updateQueueStatus(String restaurantId, String queueDocId, String status) async {
    if (status == 'Seated' || status == 'Cancelled') {
      await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('queue')
          .doc(queueDocId)
          .delete();
    } else {
      await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('queue')
          .doc(queueDocId)
          .update({'status': status});
    }
  }

  /// Seed initial queue items if empty
  Future<void> seedDefaultQueue(String restaurantId) async {
    final ref = _db.collection('restaurants').doc(restaurantId).collection('queue');
    final existing = await ref.limit(1).get();
    if (existing.docs.isEmpty) {
      await ref.add({
        'qId': 'Q-01',
        'name': 'David Smith',
        'party': 4,
        'phone': '+1 555-0192',
        'quoted': '15m',
        'status': 'Waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await ref.add({
        'qId': 'Q-02',
        'name': 'Sarah Jenkins',
        'party': 2,
        'phone': '+1 555-0143',
        'quoted': '20m',
        'status': 'Notified',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await ref.add({
        'qId': 'Q-03',
        'name': 'Robert Fox',
        'party': 6,
        'phone': '+1 555-0188',
        'quoted': '30m',
        'status': 'Waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ─── RESERVATIONS ─────────────────────────────────────────────────────────

  /// Add new reservation
  Future<void> addReservation({
    required String restaurantId,
    required String name,
    required int partySize,
    required String phone,
  }) async {
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reservations')
        .add({
      'name': name,
      'party': partySize,
      'phone': phone,
      'status': 'Confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
