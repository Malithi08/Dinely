import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

class ReservationService {
  final _db = FirebaseFirestore.instance;

  // CREATE
  Future<String> createReservation(Reservation r) async {
    final ref = await _db.collection('reservations').add(r.toMap());
    return ref.id;
  }

  // READ - customer's own reservations
  Stream<List<Reservation>> streamUserReservations(String userId) {
    return _db
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Reservation.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    });
  }

  // READ - all reservations (staff)
  Stream<List<Reservation>> streamAllReservations() {
    return _db
        .collection('reservations')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Reservation.fromMap(d.id, d.data()))
            .toList());
  }

  // UPDATE - status
  Future<void> updateStatus(String id, String status) async {
    await _db.collection('reservations').doc(id).update({'status': status});
  }

  // UPDATE - table number
  Future<void> assignTable(String id, String tableNumber) async {
    await _db
        .collection('reservations')
        .doc(id)
        .update({'tableNumber': tableNumber});
  }

  // DELETE
  Future<void> deleteReservation(String id) async {
    await _db.collection('reservations').doc(id).delete();
  }
}