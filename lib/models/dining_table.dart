import 'package:cloud_firestore/cloud_firestore.dart';

class DiningTable {
  final String id;           // Firestore doc ID, e.g. "T01"
  final String tableNumber;  // e.g. "T01"
  final int seats;
  final String area;         // "indoor" | "patio" | "rooftop"
  final String status;       // "available" | "reserved" | "occupied"
  final String? reservedBy;
  final DateTime? reservedAt;

  DiningTable({
    required this.id,
    required this.tableNumber,
    required this.seats,
    required this.area,
    required this.status,
    this.reservedBy,
    this.reservedAt,
  });

  bool get isAvailable => status == 'available';
  bool get isReserved => status == 'reserved';
  bool get isOccupied => status == 'occupied';

  factory DiningTable.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiningTable(
      id: doc.id,
      tableNumber: data['tableNumber'] ?? doc.id,
      seats: (data['seats'] ?? 0) as int,
      area: data['area'] ?? 'indoor',
      status: data['status'] ?? 'available',
      reservedBy: data['reservedBy'] as String?,
      reservedAt: (data['reservedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableNumber': tableNumber,
      'seats': seats,
      'area': area,
      'status': status,
      'reservedBy': reservedBy,
      'reservedAt': reservedAt == null ? null : Timestamp.fromDate(reservedAt!),
    };
  }
}