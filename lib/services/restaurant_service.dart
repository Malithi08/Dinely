import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/restaurant.dart';

class RestaurantService {
  final CollectionReference _restaurantsRef =
      FirebaseFirestore.instance.collection('restaurants');

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Real-time stream
  Stream<List<Restaurant>> getRestaurants() {
    return _restaurantsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .toList();
    });
  }

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName =
          'restaurant_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  // Add restaurant
  Future<void> addRestaurant({
    required String name,
    required String address,
    required String phone,
    File? imageFile,
    double rating = 0.0,  // 🟡 NEW — Default 0.0
  }) async {
    try {
      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
      }

      final newRestaurant = Restaurant(
        id: '',
        name: name,
        address: address,
        phone: phone,
        imageUrl: imageUrl,
        rating: rating,  // 🟡 NEW — Pass rating
      );

      await _restaurantsRef.add(newRestaurant.toFirestore());
    } catch (e) {
      throw Exception('Failed to add restaurant: $e');
    }
  }

  // Delete restaurant
  Future<void> deleteRestaurant(String id) async {
    await _restaurantsRef.doc(id).delete();
  }
}