import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/t_walkin_model.dart';

class WalkinService {
  final CollectionReference _walkinsRef =
      FirebaseFirestore.instance.collection('walkins');

  // =========================================================================
  // Create a walk-in
  // =========================================================================
  Future<String> createWalkin({
    required String customerName,
    required String phoneNumber,
    required String email,
    required String date,
    required String time,
    required int guests,
    required String tableId,
    required String seatingPreference,
    required String restaurantId,
    required String restaurantName,
    required String restaurantImage,
  }) async {
    try {
      if (guests < 1 || guests > 6) {
        throw Exception('Guests must be between 1 and 6');
      }

      final code = '#WLK${DateTime.now().millisecondsSinceEpoch % 10000}';

      final docRef = await _walkinsRef.add({
        'customerName': customerName,
        'phoneNumber': phoneNumber,
        'email': email,
        'date': date,
        'time': time,
        'guests': guests,
        'tableId': tableId,
        'seatingPreference': seatingPreference,
        'status': 'confirmed',
        'walkinCode': code,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'restaurantImage': restaurantImage,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create walk-in: $e');
    }
  }

  // =========================================================================
  // Get walk-in by ID
  // =========================================================================
  Future<WalkinModel?> getWalkinById(String id) async {
    try {
      final doc = await _walkinsRef.doc(id).get();
      if (doc.exists) {
        return WalkinModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // =========================================================================
  // Stream: all walk-ins for a restaurant
  // =========================================================================
  Stream<List<WalkinModel>> getRestaurantWalkins(String restaurantId) {
    return _walkinsRef
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WalkinModel.fromFirestore(doc))
          .toList();
    });
  }
}