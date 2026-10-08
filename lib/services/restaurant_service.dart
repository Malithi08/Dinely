import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';

class RestaurantService {
  final _db = FirebaseFirestore.instance;

  // CREATE
  Future<String> addRestaurant(Restaurant r) async {
    final ref = await _db.collection('restaurants').add(r.toMap());
    return ref.id;
  }

  // READ (all)
  Stream<List<Restaurant>> streamRestaurants() {
    return _db
        .collection('restaurants')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Restaurant.fromMap(d.id, d.data()))
            .toList());
  }

  // READ (search)
  Future<List<Restaurant>> searchRestaurants(String query) async {
    final snap = await _db.collection('restaurants').get();
    final all = snap.docs
        .map((d) => Restaurant.fromMap(d.id, d.data()))
        .toList();
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.cuisine.toLowerCase().contains(q))
        .toList();
  }

  // UPDATE
  Future<void> updateRestaurant(String id, Map<String, dynamic> data) async {
    await _db.collection('restaurants').doc(id).update(data);
  }

  // DELETE
  Future<void> deleteRestaurant(String id) async {
    await _db.collection('restaurants').doc(id).delete();
  }
}