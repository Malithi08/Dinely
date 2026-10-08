import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String imageUrl;
  final double rating;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.imageUrl,
    required this.rating,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Helper: handles field names with extra spaces
    String? getField(String baseName) {
      if (data.containsKey(baseName)) {
        return data[baseName]?.toString();
      }
      if (data.containsKey('$baseName ')) {
        return data['$baseName ']?.toString();
      }
      if (data.containsKey(' $baseName')) {
        return data[' $baseName']?.toString();
      }
      for (final key in data.keys) {
        if (key.trim() == baseName) {
          return data[key]?.toString();
        }
      }
      return null;
    }

    final name = getField('name') ?? 'No name';

    // 🟡 Rating — Firestore එකේ නැත්නම්, name එකේ hash එකෙන් හදනවා
    // එකම name එකට හැම වෙලාවෙම එකම rating එක එනවා
    double rating = 0.0;
    final ratingValue = getField('rating');
    if (ratingValue != null) {
      rating = double.tryParse(ratingValue) ?? 0.0;
    }
    // 🟡 Fallback: rating නැත්නම්, name එකේ hash එකෙන් එකක් හදනවා
    if (rating == 0.0) {
      final hash = name.codeUnits.fold<int>(0, (prev, c) => prev + c);
      // 4.0 සිට 4.9 දක්වා ratings
      rating = 4.0 + (hash % 10) / 10.0;
    }

    return Restaurant(
      id: doc.id,
      name: name,
      address: getField('address') ?? 'No address',
      phone: getField('phone') ?? 'No phone',
      imageUrl: getField('imageUrl') ?? '',
      rating: rating,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'imageUrl': imageUrl,
      'rating': rating,
    };
  }
}