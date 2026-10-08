import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staff_task.dart';

class StaffService {
  final _db = FirebaseFirestore.instance;

  // CREATE
  Future<String> createTask(StaffTask t) async {
    final ref = await _db.collection('tasks').add(t.toMap());
    return ref.id;
  }

  // READ
  Stream<List<StaffTask>> streamTasks() {
    return _db
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StaffTask.fromMap(d.id, d.data()))
            .toList());
  }

  // UPDATE - toggle completed
  Future<void> toggleComplete(String id, bool completed) async {
    await _db.collection('tasks').doc(id).update({'completed': completed});
  }

  // UPDATE
  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _db.collection('tasks').doc(id).update(data);
  }

  // DELETE
  Future<void> deleteTask(String id) async {
    await _db.collection('tasks').doc(id).delete();
  }
}