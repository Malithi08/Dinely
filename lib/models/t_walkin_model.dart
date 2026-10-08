import 'package:cloud_firestore/cloud_firestore.dart';

class WalkinModel {
  final String id;
  final String customerName;
  final String phoneNumber;
  final String email;
  final String date;
  final String time;
  final int guests;
  final String tableId;
  final String seatingPreference;
  final String status;
  final String walkinCode;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImage;
  final DateTime createdAt;

  WalkinModel({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.email,
    required this.date,
    required this.time,
    required this.guests,
    required this.tableId,
    required this.seatingPreference,
    required this.status,
    required this.walkinCode,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImage,
    required this.createdAt,
  });

  factory WalkinModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WalkinModel(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      guests: (data['guests'] ?? 0).toInt(),
      tableId: data['tableId'] ?? '',
      seatingPreference: data['seatingPreference'] ?? '',
      status: data['status'] ?? 'confirmed',
      walkinCode: data['walkinCode'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      restaurantImage: data['restaurantImage'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'email': email,
      'date': date,
      'time': time,
      'guests': guests,
      'tableId': tableId,
      'seatingPreference': seatingPreference,
      'status': status,
      'walkinCode': walkinCode,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImage': restaurantImage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}