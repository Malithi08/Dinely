import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_status.dart';

class TableService {
  final _db = FirebaseFirestore.instance;

  Stream<List<TableStatus>> streamTables() {
    return _db
        .collection('tables')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TableStatus.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id)));
  }

  Future<void> updateStatus(String id, String status) async {
    final normalizedStatus = status.trim().toLowerCase();
    if (!['available', 'occupied', 'reserved'].contains(normalizedStatus)) {
      return;
    }

    await _db.collection('tables').doc(id).update({'status': normalizedStatus});
  }
}