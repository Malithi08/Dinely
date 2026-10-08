import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dining_table.dart';

class DiningTableService {
  final _db = FirebaseFirestore.instance;

  Stream<List<DiningTable>> tablesStream(String restaurantId) {
    print('>>> tablesStream called for restaurantId: $restaurantId');
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('dining_tables')
        .snapshots()
        .map((snap) {
      print('>>> Firestore returned ${snap.docs.length} tables');
      return snap.docs.map(DiningTable.fromDoc).toList();
    });
  }

  Future<DiningTable?> getTable(String restaurantId, String tableId) async {
    final doc = await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('dining_tables')
        .doc(tableId)
        .get();
    if (!doc.exists) return null;
    return DiningTable.fromDoc(doc);
  }

  /// Fetch the restaurant name for display.
  Future<String> getRestaurantName(String restaurantId) async {
    try {
      final doc = await _db.collection('restaurants').doc(restaurantId).get();
      if (!doc.exists) {
        print('>>> restaurant doc $restaurantId does NOT exist');
        return 'Restaurant';
      }
      final data = doc.data();
      final name = (data?['name'] ?? 'Restaurant').toString();
      print('>>> restaurant name loaded: $name');
      return name;
    } catch (e) {
      print('>>> getRestaurantName failed: $e');
      return 'Restaurant';
    }
  }

  /// Reserve a table atomically and create a reservation document.
  Future<String?> reserveTable({
    required String restaurantId,
    required String tableId,
    required String customerId,
  }) async {
    try {
      final tableRef = _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dining_tables')
          .doc(tableId);

      await _db.runTransaction((tx) async {
        final snap = await tx.get(tableRef);
        if (!snap.exists) throw Exception('Table not found');

        final data = snap.data() as Map<String, dynamic>;
        if (data['status'] != 'available') {
          throw Exception('Table is no longer available');
        }

        tx.update(tableRef, {
          'status': 'reserved',
          'reservedBy': customerId,
          'reservedAt': FieldValue.serverTimestamp(),
        });

        final resRef = _db.collection('reservations').doc();
        tx.set(resRef, {
          'customerId': customerId,
          'restaurantId': restaurantId,
          'tableId': tableId,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'confirmed',
        });
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Cancel a reservation: free the table AND delete the reservation document.
  Future<String?> cancelReservation({
    required String restaurantId,
    required String tableId,
    required String customerId,
  }) async {
    try {
      final tableRef = _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dining_tables')
          .doc(tableId);

      await _db.runTransaction((tx) async {
        final snap = await tx.get(tableRef);
        if (!snap.exists) throw Exception('Table not found');

        final data = snap.data() as Map<String, dynamic>;
        if (data['reservedBy'] != customerId) {
          throw Exception('You did not reserve this table');
        }

        // 1. Free the table
        tx.update(tableRef, {
          'status': 'available',
          'reservedBy': null,
          'reservedAt': null,
        });

        // 2. Find matching reservation documents
        final resQuery = await _db
            .collection('reservations')
            .where('customerId', isEqualTo: customerId)
            .where('restaurantId', isEqualTo: restaurantId)
            .where('tableId', isEqualTo: tableId)
            .get();

        for (final doc in resQuery.docs) {
          tx.delete(doc.reference);
        }
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Staff marks a reserved table as occupied when the customer arrives.
  Future<String?> markTableOccupied({
    required String restaurantId,
    required String tableId,
  }) async {
    try {
      await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dining_tables')
          .doc(tableId)
          .update({'status': 'occupied'});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Staff frees a table when the customer leaves.
  Future<String?> freeTable({
    required String restaurantId,
    required String tableId,
  }) async {
    try {
      await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dining_tables')
          .doc(tableId)
          .update({
        'status': 'available',
        'reservedBy': null,
        'reservedAt': null,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}