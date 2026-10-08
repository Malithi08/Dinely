class QueueEntry {
  final String id;
  final String name;
  final String phone;
  final int partySize;
  final DateTime joinedAt;
  final int position; // #1, #2, #3

  QueueEntry({
    required this.id,
    required this.name,
    required this.phone,
    required this.partySize,
    required this.joinedAt,
    required this.position,
  });

  int get waitingMinutes =>
      DateTime.now().difference(joinedAt).inMinutes;

  factory QueueEntry.fromMap(String id, Map<String, dynamic> data) {
    return QueueEntry(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      partySize: data['partySize'] ?? 2,
      joinedAt: (data['joinedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      position: data['position'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'partySize': partySize,
        'joinedAt': joinedAt,
        'position': position,
      };
}