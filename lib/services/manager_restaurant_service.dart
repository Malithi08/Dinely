import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerRestaurantService {
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

  /// Update table properties
  Future<void> updateTable({
    required String restaurantId,
    required String tableDocId,
    String? tableNumber,
    int? seats,
    String? area,
    String? status,
  }) async {
    final Map<String, dynamic> updates = {};
    if (tableNumber != null) updates['tableNumber'] = tableNumber;
    if (seats != null) updates['seats'] = seats;
    if (area != null) updates['area'] = area.toLowerCase();
    if (status != null) updates['status'] = status;
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('dining_tables')
        .doc(tableDocId)
        .update(updates);
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

  // ─── WALK-INS ─────────────────────────────────────────────────────────────

  Future<void> addWalkin(Map<String, dynamic> walkinData) async {
    String restName = walkinData['restaurantName'] ?? 'Dinely Restaurant';
    String restImage = walkinData['restaurantImage'] ?? '';
    
    try {
      final String? rId = walkinData['restaurantId'];
      if (rId != null && rId.isNotEmpty) {
        final rDoc = await _db.collection('restaurants').doc(rId).get();
        if (rDoc.exists && rDoc.data() != null) {
          final rData = rDoc.data()!;
          if (rData['name'] != null && rData['name'].toString().isNotEmpty) restName = rData['name'].toString();
          else if (rData['restaurantName'] != null && rData['restaurantName'].toString().isNotEmpty) restName = rData['restaurantName'].toString();
          else if (rData['restaurant_name'] != null && rData['restaurant_name'].toString().isNotEmpty) restName = rData['restaurant_name'].toString();
          else if (rData['title'] != null && rData['title'].toString().isNotEmpty) restName = rData['title'].toString();
          
          if (rData['image'] != null && rData['image'].toString().isNotEmpty) restImage = rData['image'].toString();
          else if (rData['imageUrl'] != null && rData['imageUrl'].toString().isNotEmpty) restImage = rData['imageUrl'].toString();
          else if (rData['restaurantImage'] != null && rData['restaurantImage'].toString().isNotEmpty) restImage = rData['restaurantImage'].toString();
        }
      }
    } catch (_) {}

    final finalData = {
      ...walkinData,
      'restaurantName': restName,
      'restaurantImage': restImage,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('walkins').add(finalData);
  }

  /// Stream walk-ins
  Stream<List<Map<String, dynamic>>> streamWalkins(String restaurantId) {
    return _db
        .collection('walkins')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
          var walkinsList = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'docId': doc.id,
              'name': data['customerName'] ?? data['email'] ?? 'Unknown Guest',
              'phone': data['phoneNumber'] ?? 'N/A',
              'email': data['email'] ?? 'N/A',
              'party': data['guests'] ?? 2,
              'time': data['time'] ?? 'N/A',
              'date': data['date'] ?? 'N/A',
              'table': data['tableId'] ?? 'Unassigned',
              'status': data['status'] ?? 'confirmed',
              'walkinCode': data['walkinCode'] ?? 'N/A',
              'seatingPreference': data['seatingPreference'] ?? 'None',
              ...data,
            };
          }).toList();

          walkinsList.sort((a, b) {
            final timeA = a['updatedAt'];
            final timeB = b['updatedAt'];
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1; // Put nulls at bottom
            if (timeB == null) return -1;
            // Sort ascending: oldest first, newest at bottom (just like they are added)
            // If you prefer newest at top, swap b and a below.
            return timeA.compareTo(timeB);
          });
          
          return walkinsList;
        });
  }

  /// Update walk-in status
  Future<void> updateWalkinStatus(
    String docId, 
    String status, {
    String? tableId,
    Map<String, dynamic>? walkinData,
    String? managerId,
  }) async {
    final Map<String, dynamic> data = {
      'status': status.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (tableId != null) {
      data['tableId'] = tableId;
    }
    await _db.collection('walkins').doc(docId).set(data, SetOptions(merge: true));

    if (tableId != null && walkinData != null) {
      await _db.collection('allocated_tables').add({
        'tableId': tableId,
        'restaurantId': walkinData['restaurantId'] ?? 'Unknown',
        'customerName': walkinData['name'] ?? walkinData['customerName'] ?? 'Unknown',
        'phoneNumber': walkinData['phone'] ?? walkinData['phoneNumber'] ?? 'N/A',
        'assignedBy': managerId ?? 'Manager',
        'allocatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Delete a walkin
  Future<void> deleteWalkin(String docId, {String? restaurantId, String? tableId}) async {
    if (restaurantId != null && tableId != null && tableId.isNotEmpty) {
      if (tableId.toLowerCase() != 'unassigned' && tableId.toLowerCase() != 'auto') {
         await updateTableStatus(restaurantId, tableId, 'Available');
      }
    }
    await _db.collection('walkins').doc(docId).delete();
  }
}
