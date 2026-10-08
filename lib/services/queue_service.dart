import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_entry.dart';

class QueueService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _queueRef(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('queue');
  }

  // ─── Join the queue ─────────────────────────────────
  Future<String?> joinQueue({
    required String restaurantId,
    required String customerId,
    required String customerName,
    required int guests,
  }) async {
    try {
      final existing = await _queueRef(restaurantId)
          .where('customerId', isEqualTo: customerId)
          .where('status',
              whereIn: ['waiting', 'preparing', 'ready', 'seated'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) return null;

      final waiting = await _queueRef(restaurantId)
          .where('status', whereIn: ['waiting', 'preparing', 'ready'])
          .get();

      final position = waiting.docs.length + 1;
      final waitMinutes = position == 1 ? 3 : 3 + (position - 1) * 3;
      final promoteAt = DateTime.now().add(Duration(minutes: waitMinutes));

      await _queueRef(restaurantId).add({
        'customerId': customerId,
        'customerName': customerName,
        'guests': guests,
        'status': 'waiting',
        'joinedAt': FieldValue.serverTimestamp(),
        'promoteAt': Timestamp.fromDate(promoteAt),
        'readyAt': null,
        'seatedAt': null,
        'tableId': null,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Leave the queue ────────────────────────────────
  Future<String?> leaveQueue({
    required String restaurantId,
    required String queueId,
  }) async {
    try {
      await _queueRef(restaurantId).doc(queueId).update({
        'status': 'left',
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Customer arrives + checks in ───────────────────
  Future<String?> checkIn({
    required String restaurantId,
    required String queueId,
    required String tableId,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final queueRef = _queueRef(restaurantId).doc(queueId);
        final tableRef = _db
            .collection('restaurants')
            .doc(restaurantId)
            .collection('dining_tables')
            .doc(tableId);

        tx.update(queueRef, {
          'status': 'seated',
          'seatedAt': FieldValue.serverTimestamp(),
        });

        tx.update(tableRef, {
          'status': 'occupied',
        });
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Customer is done ───────────────────────────────
  Future<String?> finishMeal({
    required String restaurantId,
    required String queueId,
    required String tableId,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final queueRef = _queueRef(restaurantId).doc(queueId);
        final tableRef = _db
            .collection('restaurants')
            .doc(restaurantId)
            .collection('dining_tables')
            .doc(tableId);

        tx.update(queueRef, {
          'status': 'left',
        });

        tx.update(tableRef, {
          'status': 'available',
          'reservedBy': null,
          'reservedAt': null,
        });
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Live queue list ────────────────────────────────
  Stream<List<QueueEntry>> activeQueueStream(String restaurantId) {
    return _queueRef(restaurantId)
        .where('status', whereIn: ['waiting', 'preparing', 'ready'])
        .orderBy('joinedAt')
        .snapshots()
        .map((snap) {
      final entries = <QueueEntry>[];
      int position = 1;
      for (final doc in snap.docs) {
        final entry = QueueEntry.fromDoc(doc).copyWith(position: position);
        entries.add(entry);
        position++;
      }
      return entries;
    });
  }

  // ─── Watch my own entry WITH live position ─────────
  Stream<QueueEntry?> myQueueStream({
    required String restaurantId,
    required String customerId,
  }) {
    return _queueRef(restaurantId)
        .where('status', whereIn: ['waiting', 'preparing', 'ready'])
        .orderBy('joinedAt')
        .snapshots()
        .map((snap) {
      int position = 1;
      for (final doc in snap.docs) {
        final entry = QueueEntry.fromDoc(doc).copyWith(position: position);
        if (entry.customerId == customerId) {
          return entry;
        }
        position++;
      }
      return null;
    });
  }

  // ─── My active entry (any status) ───────────────────
  Stream<QueueEntry?> myAnyStatusStream({
    required String restaurantId,
    required String customerId,
  }) {
    return _queueRef(restaurantId)
        .where('customerId', isEqualTo: customerId)
        .where('status',
            whereIn: ['waiting', 'preparing', 'ready', 'seated'])
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return QueueEntry.fromDoc(snap.docs.first);
    });
  }

  // ─── One-off position lookup ────────────────────────
  Future<int> myPosition({
    required String restaurantId,
    required String customerId,
  }) async {
    try {
      final waiting = await _queueRef(restaurantId)
          .where('status', whereIn: ['waiting', 'preparing', 'ready'])
          .orderBy('joinedAt')
          .get();

      for (int i = 0; i < waiting.docs.length; i++) {
        final data = waiting.docs[i].data();
        if (data['customerId'] == customerId) return i + 1;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Auto-promote when a table is available ────────
  Future<void> tryAutoPromote(String restaurantId) async {
    try {
      final availableTables = await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dining_tables')
          .where('status', isEqualTo: 'available')
          .limit(1)
          .get();

      if (availableTables.docs.isEmpty) return;

      final tableDoc = availableTables.docs.first;
      final tableId = tableDoc.id;

      final waiting = await _queueRef(restaurantId)
          .where('status', isEqualTo: 'waiting')
          .orderBy('joinedAt')
          .limit(1)
          .get();

      if (waiting.docs.isEmpty) return;

      final queueDoc = waiting.docs.first;

      await _db.runTransaction((tx) async {
        final tableRef = _db
            .collection('restaurants')
            .doc(restaurantId)
            .collection('dining_tables')
            .doc(tableId);
        final queueRef = _queueRef(restaurantId).doc(queueDoc.id);

        final tableSnap = await tx.get(tableRef);
        final queueSnap = await tx.get(queueRef);

        if (!tableSnap.exists || !queueSnap.exists) return;

        final tableData = tableSnap.data() as Map<String, dynamic>;
        final qData = queueSnap.data() as Map<String, dynamic>;

        if (tableData['status'] != 'available') return;
        if (qData['status'] != 'waiting') return;

        tx.update(queueRef, {
          'status': 'ready',
          'readyAt': FieldValue.serverTimestamp(),
          'tableId': tableId,
        });

        tx.update(tableRef, {
          'status': 'reserved',
          'reservedBy': qData['customerId'],
          'reservedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {}
  }

  // ─── Time-based promotion ──────────────────────────
  Future<void> tryTimeBasedPromote(String restaurantId) async {
    try {
      final now = DateTime.now();
      print('>>> tryTimeBasedPromote at $now');

      final due = await _queueRef(restaurantId)
          .where('status', isEqualTo: 'waiting')
          .where('promoteAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('promoteAt')
          .limit(1)
          .get();

      print('>>> due waiting: ${due.docs.length}');
      if (due.docs.isEmpty) return;

      final availableTables = await _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dining_tables')
          .where('status', isEqualTo: 'available')
          .limit(1)
          .get();

      print('>>> available tables: ${availableTables.docs.length}');
      if (availableTables.docs.isEmpty) return;

      final tableDoc = availableTables.docs.first;
      final tableId = tableDoc.id;
      final queueDoc = due.docs.first;

      await _db.runTransaction((tx) async {
        final tableRef = _db
            .collection('restaurants')
            .doc(restaurantId)
            .collection('dining_tables')
            .doc(tableId);
        final queueRef = _queueRef(restaurantId).doc(queueDoc.id);

        final tableSnap = await tx.get(tableRef);
        final queueSnap = await tx.get(queueRef);

        if (!tableSnap.exists || !queueSnap.exists) return;

        final tableData = tableSnap.data() as Map<String, dynamic>;
        final qData = queueSnap.data() as Map<String, dynamic>;

        if (tableData['status'] != 'available') return;
        if (qData['status'] != 'waiting') return;

        tx.update(queueRef, {
          'status': 'ready',
          'readyAt': FieldValue.serverTimestamp(),
          'tableId': tableId,
        });

        tx.update(tableRef, {
          'status': 'reserved',
          'reservedBy': qData['customerId'],
          'reservedAt': FieldValue.serverTimestamp(),
        });

        print('>>> PROMOTED to ready at table $tableId');
      });
    } catch (e) {
      print('>>> tryTimeBasedPromote ERROR: $e');
    }
  }
}