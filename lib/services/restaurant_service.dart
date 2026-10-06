import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── TABLES ────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamTables(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('dining_tables')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            
            // Handle tableNumber stored as String
            String parsedTableNum = doc.id;
            if (data['tableNumber'] != null) {
              parsedTableNum = data['tableNumber'].toString();
            }

            // Handle seats stored as String or num
            int parsedSeats = 4;
            if (data['seats'] is num) {
              parsedSeats = (data['seats'] as num).toInt();
            } else if (data['seats'] is String) {
              parsedSeats = int.tryParse(data['seats']) ?? 4;
            }

            String areaVal = data['area'] ?? data['zone'] ?? '';
            if (areaVal.toLowerCase() == 'main hall') areaVal = 'Indoor';

            // Auto-correct missing or generic area based on tableNumber prefix
            if (areaVal.isEmpty || areaVal == 'Indoor') {
              if (parsedTableNum.startsWith('P') || parsedTableNum.toUpperCase().startsWith('P-')) {
                areaVal = 'Patio';
              } else if (parsedTableNum.startsWith('R') || parsedTableNum.toUpperCase().startsWith('R-')) {
                areaVal = 'Rooftop';
              } else {
                areaVal = 'Indoor';
              }
            }

            String rawStatus = data['status']?.toString() ?? 'available';
            String formattedStatus = rawStatus.isEmpty ? 'Available' : '${rawStatus[0].toUpperCase()}${rawStatus.substring(1).toLowerCase()}';

            return {
              'id': doc.id,
              ...data,
              'tableNumber': parsedTableNum,
              'seats': parsedSeats,
              'area': areaVal,
              'status': formattedStatus,
            };
          }).toList();

          docs.sort((a, b) {
            final numA = a['tableNumber'].toString();
            final numB = b['tableNumber'].toString();
            return numA.compareTo(numB);
          });
          return docs;
        });
  }

  /// Update table status (Available, Occupied, Reserved, Cleaning)
  Future<void> updateTableStatus(String restaurantId, String tableDocId, String newStatus) async {
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('dining_tables')
        .doc(tableDocId)
        .set({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  /// Delete table from Firestore
  Future<void> deleteTable(String restaurantId, String tableDocId) async {
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('dining_tables')
        .doc(tableDocId)
        .delete();
  }

  /// Add a new table to Firestore
  Future<void> addTable({
    required String restaurantId,
    required String tableNumber,
    required int seats,
    required String area,
    String? assignedServer,
  }) async {
    final tableId = tableNumber;
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('dining_tables')
        .doc(tableId)
        .set({
      'tableNumber': tableNumber,
      'seats': seats,
      'status': 'available',
      'area': area.toLowerCase(),
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

  /// Stream reservations (checks root 'reservations' collection and fetches customer details)
  Stream<List<Map<String, dynamic>>> streamReservations(String restaurantId) {
    return _db
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> results = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data();
            String name = data['name'] ?? 'Unknown Guest';
            String phone = data['phone'] ?? 'N/A';
            
            if (data['customerId'] != null) {
              final userDoc = await _db.collection('users').doc(data['customerId']).get();
              if (userDoc.exists && userDoc.data() != null) {
                final userData = userDoc.data()!;
                name = userData['name'] ?? userData['fullName'] ?? name;
                phone = userData['phone'] ?? userData['phoneNumber'] ?? phone;
              }
            }

            String timeStr = data['time'] ?? 'N/A';
            if (data['time'] == null && data['createdAt'] != null && data['createdAt'] is Timestamp) {
              final dt = (data['createdAt'] as Timestamp).toDate();
              final hr = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
              final ampm = dt.hour >= 12 ? 'PM' : 'AM';
              timeStr = '$hr:${dt.minute.toString().padLeft(2, '0')} $ampm';
            }

            results.add({
              'docId': doc.id,
              'name': name,
              'phone': phone,
              'table': data['tableId'] ?? 'Unassigned',
              'party': data['partySize'] ?? 2,
              'time': timeStr,
              'status': data['status'] ?? 'confirmed',
              ...data,
            });
          }
          return results;
        });
  }

  /// Update reservation status (Confirmed, Seated, No Show, Cancelled)
  Future<void> updateReservationStatus(String restaurantId, String docId, String status) async {
    await _db.collection('reservations').doc(docId).set({
      'status': status.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Add new reservation
  Future<void> addReservation({
    required String restaurantId,
    required String name,
    required int partySize,
    required String phone,
    String? time,
    String? date,
  }) async {
    await _db.collection('reservations').add({
      'restaurantId': restaurantId,
      'name': name,
      'partySize': partySize,
      'phone': phone,
      'time': time ?? '7:00 PM',
      'date': date ?? 'Today',
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── MANAGER PROFILE ───────────────────────────────────────────────────────

  /// Get manager user profile details from Firestore
  Future<Map<String, dynamic>?> getManagerProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return doc.data();
    }
    return null;
  }
}
