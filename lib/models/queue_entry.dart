import 'package:cloud_firestore/cloud_firestore.dart';

class QueueEntry {
  final String id;
  final String customerId;
  final String customerName;
  final int guests;
  final String status; // 'waiting' | 'preparing' | 'ready' | 'seated' | 'left'
  final DateTime joinedAt;
  final DateTime? readyAt;
  final DateTime? seatedAt;
  final String? tableId;
  final int position;

  QueueEntry({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.guests,
    required this.status,
    required this.joinedAt,
    this.readyAt,
    this.seatedAt,
    this.tableId,
    this.position = 0,
  });

  bool get isWaiting => status == 'waiting';
  bool get isReady => status == 'ready';
  bool get isSeated => status == 'seated';
  bool get isLeft => status == 'left';

  int get estimatedWaitMinutes {
    if (isSeated || isLeft) return 0;
    final groupsAhead = position > 1 ? position - 1 : 0;
    if (position == 1) return 3;
    return 3 + groupsAhead * 3;
  }

  QueueEntry copyWith({int? position}) {
    return QueueEntry(
      id: id,
      customerId: customerId,
      customerName: customerName,
      guests: guests,
      status: status,
      joinedAt: joinedAt,
      readyAt: readyAt,
      seatedAt: seatedAt,
      tableId: tableId,
      position: position ?? this.position,
    );
  }

  factory QueueEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueEntry(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Guest',
      guests: (data['guests'] ?? 1) as int,
      status: data['status'] ?? 'waiting',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readyAt: (data['readyAt'] as Timestamp?)?.toDate(),
      seatedAt: (data['seatedAt'] as Timestamp?)?.toDate(),
      tableId: data['tableId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'guests': guests,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'readyAt': readyAt == null ? null : Timestamp.fromDate(readyAt!),
      'seatedAt': seatedAt == null ? null : Timestamp.fromDate(seatedAt!),
      'tableId': tableId,
    };
  }
}