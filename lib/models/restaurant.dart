class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String imageUrl;
  final double rating;
  final String address;
  final String openHours;
  final int availableTables;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.imageUrl,
    required this.rating,
    required this.address,
    required this.openHours,
    required this.availableTables,
  });

  factory Restaurant.fromMap(String id, Map<String, dynamic> data) {
    return Restaurant(
      id: id,
      name: data['name'] ?? '',
      cuisine: data['cuisine'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      openHours: data['openHours'] ?? '',
      availableTables: data['availableTables'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'cuisine': cuisine,
        'imageUrl': imageUrl,
        'rating': rating,
        'address': address,
        'openHours': openHours,
        'availableTables': availableTables,
      };
}