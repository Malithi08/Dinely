class TableStatus {
  final String id;        // T1, T2, ...
  final int seats;
  final String status;    // available, occupied, reserved

  TableStatus({
    required this.id,
    required this.seats,
    required this.status,
  });

  factory TableStatus.fromMap(String id, Map<String, dynamic> data) {
    final normalizedStatus = ((data['status'] ?? 'available') as String)
        .trim()
        .toLowerCase();

    final normalizedSeats = data['seats'] is int
        ? data['seats'] as int
        : int.tryParse(data['seats']?.toString() ?? '') ?? 2;

    return TableStatus(
      id: id,
      seats: normalizedSeats,
      status: ['available', 'occupied', 'reserved'].contains(normalizedStatus)
          ? normalizedStatus
          : 'available',
    );
  }

  Map<String, dynamic> toMap() => {
        'seats': seats,
        'status': status,
      };
}