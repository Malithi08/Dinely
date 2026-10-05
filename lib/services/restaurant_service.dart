import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── TABLES ────────────────────────────────────────────────────────────────

  /// Stream real-time tables
  Stream<List<Map<String, dynamic>>> streamTables(String restaurantId) {
    return _db
        .collection('tables')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            // Handle number stored as String or num
            int parsedNum = 0;
            if (data['number'] is num) {
              parsedNum = (data['number'] as num).toInt();
            } else if (data['number'] is String) {
              parsedNum = int.tryParse(data['number']) ?? 0;
            }

            // Handle capacity stored as String or num
            int parsedCap = 4;
            if (data['capacity'] is num) {
              parsedCap = (data['capacity'] as num).toInt();
            } else if (data['capacity'] is String) {
              parsedCap = int.tryParse(data['capacity']) ?? 4;
            }

            return {
              'id': doc.id,
              ...data,
              'number': parsedNum,
              'capacity': parsedCap,
            };
          }).toList();

          docs.sort((a, b) {
            final numA = a['number'] as int;
            final numB = b['number'] as int;
            return numA.compareTo(numB);
          });
          return docs;
        });
  }

  /// Update table status (Available, Occupied, Reserved, Cleaning)
  Future<void> updateTableStatus(String restaurantId, String tableDocId, String newStatus) async {
    await _db
        .collection('tables')
        .doc(tableDocId)
        .set({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  /// Delete table from Firestore
  Future<void> deleteTable(String tableDocId) async {
    await _db.collection('tables').doc(tableDocId).delete();
  }

  /// Add a new table to Firestore
  Future<void> addTable({
    required String restaurantId,
    required int tableNumber,
    required int capacity,
    required String zone,
    String? assignedServer,
  }) async {
    final tableId = 'table_${tableNumber < 10 ? '00$tableNumber' : (tableNumber < 100 ? '0$tableNumber' : '$tableNumber')}';
    await _db
        .collection('tables')
        .doc(tableId)
        .set({
      'tableId': tableId,
      'number': tableNumber,
      'capacity': capacity,
      'status': 'Available',
      'zone': zone,
      'server': (assignedServer != null && assignedServer.trim().isNotEmpty) ? assignedServer : 'Unassigned',
      'restaurantId': restaurantId,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
