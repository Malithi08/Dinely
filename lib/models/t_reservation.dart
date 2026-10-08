import 'package:cloud_firestore/cloud_firestore.dart';

class TReservation {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String tableId;
  final String tableNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final int seats;
  final String area;
  final DateTime? reservedDate;
  final String reservedTime;
  final DateTime reservedAt;
  final String status;

  TReservation({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.tableId,
    required this.tableNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.seats,
    required this.area,
    this.reservedDate,
    required this.reservedTime,
    required this.reservedAt,
    required this.status,
  });

  factory TReservation.fromMap(String id, Map<String, dynamic> map) {
    return TReservation(
      id: id,
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      tableId: map['tableId'] ?? '',
      tableNumber: map['tableNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      seats: map['seats'] ?? 0,
      area: map['area'] ?? '',
      reservedDate: (map['reservedDate'] as Timestamp?)?.toDate(),
      reservedTime: map['reservedTime'] ?? '',
      reservedAt: (map['reservedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'confirmed',
    );
  }

  Map<String, dynamic> toMap() => {
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'tableId': tableId,
        'tableNumber': tableNumber,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'seats': seats,
        'area': area,
        'reservedDate': reservedDate != null
            ? Timestamp.fromDate(reservedDate!)
            : null,
        'reservedTime': reservedTime,
        'reservedAt': Timestamp.fromDate(reservedAt),
        'status': status,
      };
}