import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String userId;
  final String userName;
  final String restaurantId;
  final String restaurantName;
  final DateTime dateTime;
  final int guests;
  final String status; // pending, confirmed, cancelled, completed
  final String? specialRequest;
  final String? tableNumber;

  Reservation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.restaurantId,
    required this.restaurantName,
    required this.dateTime,
    required this.guests,
    required this.status,
    this.specialRequest,
    this.tableNumber,
  });

  factory Reservation.fromMap(String id, Map<String, dynamic> data) {
    return Reservation(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      guests: data['guests'] ?? 2,
      status: data['status'] ?? 'pending',
      specialRequest: data['specialRequest'],
      tableNumber: data['tableNumber'],
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'dateTime': Timestamp.fromDate(dateTime),
        'guests': guests,
        'status': status,
        'specialRequest': specialRequest,
        'tableNumber': tableNumber,
      };
}