import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dining_table.dart';
import '../models/t_reservation.dart';

class TReservationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════
  // CREATE RESERVATION
  // ══════════════════════════════════════════════════════════
  Future<String?> createReservation({
    required String restaurantId,
    required String restaurantName,
    required DiningTable table,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required int guestCount,
    required DateTime reservedDate,
    required String reservedTime,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Please sign in again';

    try {
      final tableRef = _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dining_tables')
          .doc(table.id);

      final reservationRef = _db.collection('reservations').doc();

      await _db.runTransaction((tx) async {
        final snap = await tx.get(tableRef);
        if (!snap.exists) throw Exception('Table no longer exists');

        final data = snap.data()!;
        if (data['isAvailable'] == false || data['status'] == 'reserved') {
          throw Exception('This table was just reserved. Please pick another.');
        }

        tx.update(tableRef, {
          'isAvailable': false,
          'status': 'reserved',
          'reservedBy': uid,
          'reservedAt': FieldValue.serverTimestamp(),
        });

        tx.set(reservationRef, {
          'restaurantId': restaurantId,
          'restaurantName': restaurantName,
          'tableId': table.id,
          'tableNumber': table.tableNumber,
          'customerId': uid,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'customerEmail': customerEmail,
          'seats': guestCount,
          'area': table.area,
          'reservedDate': Timestamp.fromDate(
            DateTime(reservedDate.year, reservedDate.month, reservedDate.day),
          ),
          'reservedTime': reservedTime,
          'reservedAt': FieldValue.serverTimestamp(),
          'status': 'confirmed',
        });
      });

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to create reservation';
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ══════════════════════════════════════════════════════════
  // CANCEL BY TABLE ID
  // ══════════════════════════════════════════════════════════
  Future<String?> cancelReservationByTable({
    required String restaurantId,
    required String tableId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Please sign in again';

    try {
      final tableRef = _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dining_tables')
          .doc(tableId);

      // ⚠️ Composite index ඕන නෑ නම් — client-side filter
      final q = await _db
          .collection('reservations')
          .where('customerId', isEqualTo: uid)
          .get();

      final matchingDocs = q.docs.where((d) {
        final data = d.data();
        return data['tableId'] == tableId &&
            data['status'] == 'confirmed';
      }).toList();

      if (matchingDocs.isEmpty) return 'No active reservation found';

      final resRef = matchingDocs.first.reference;

      await _db.runTransaction((tx) async {
        tx.update(resRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        tx.update(tableRef, {
          'isAvailable': true,
          'status': 'available',
          'reservedBy': FieldValue.delete(),
          'reservedAt': FieldValue.delete(),
        });
      });

      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ══════════════════════════════════════════════════════════
  // CANCEL BY RESERVATION ID
  // ══════════════════════════════════════════════════════════
  Future<String?> cancelReservation({
    required String reservationId,
    required String restaurantId,
    required String tableId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Please sign in again';

    try {
      final reservationRef =
          _db.collection('reservations').doc(reservationId);
      final tableRef = _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dining_tables')
          .doc(tableId);

      await _db.runTransaction((tx) async {
        final resSnap = await tx.get(reservationRef);
        if (!resSnap.exists) throw Exception('Reservation not found');

        final resData = resSnap.data()!;
        if (resData['customerId'] != uid) {
          throw Exception('You cannot cancel this reservation');
        }
        if (resData['status'] == 'cancelled') {
          throw Exception('Already cancelled');
        }

        tx.update(reservationRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        tx.update(tableRef, {
          'isAvailable': true,
          'status': 'available',
          'reservedBy': FieldValue.delete(),
          'reservedAt': FieldValue.delete(),
        });
      });

      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ══════════════════════════════════════════════════════════
  // STREAMS — userReservations (index-free)
  // ══════════════════════════════════════════════════════════
  Stream<List<TReservation>> userReservations(String uid) {
    return _db
        .collection('reservations')
        .where('customerId', isEqualTo: uid)     // ✅ Single field — index ඕන නෑ
        // ❌ .where('status', isEqualTo: 'confirmed') — Client-side filter
        // ❌ .orderBy('reservedAt') — Client-side sort
        .snapshots()
        .map((snap) {
          final all = snap.docs
              .map((d) => TReservation.fromMap(d.id, d.data()))
              .toList();

          // 👇 Client-side filter — status == 'confirmed'
          final filtered =
              all.where((r) => r.status == 'confirmed').toList();

          // 👇 Client-side sort — reservedAt descending
          filtered.sort((a, b) => b.reservedAt.compareTo(a.reservedAt));

          return filtered;
        });
  }

  // ══════════════════════════════════════════════════════════
  // STREAMS — allUserReservations (index-free)
  // ══════════════════════════════════════════════════════════
  Stream<List<TReservation>> allUserReservations(String uid) {
    return _db
        .collection('reservations')
        .where('customerId', isEqualTo: uid)     // ✅ Single field — index ඕන නෑ
        .snapshots()
        .map((snap) {
          final all = snap.docs
              .map((d) => TReservation.fromMap(d.id, d.data()))
              .toList();

          // 👇 Client-side sort — reservedAt descending
          all.sort((a, b) => b.reservedAt.compareTo(a.reservedAt));

          return all;
        });
  }

  // ══════════════════════════════════════════════════════════
  // GET SINGLE RESERVATION
  // ══════════════════════════════════════════════════════════
  Future<TReservation?> getReservation(String id) async {
    final doc = await _db.collection('reservations').doc(id).get();
    if (!doc.exists) return null;
    return TReservation.fromMap(doc.id, doc.data()!);
  }
}