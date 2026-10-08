import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_entry.dart';

class QueueService {
  final _db = FirebaseFirestore.instance;

  Stream<List<QueueEntry>> streamQueue() {
    return _db
        .collection('queue')
        .orderBy('position')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => QueueEntry.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> removeFromQueue(String id) async {
    await _db.collection('queue').doc(id).delete();
  }

  Future<void> addToQueue(QueueEntry entry) async {
    await _db.collection('queue').add(entry.toMap());
  }
}