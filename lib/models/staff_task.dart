import 'package:cloud_firestore/cloud_firestore.dart';

class StaffTask {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String priority; // low, medium, high
  final bool completed;
  final DateTime createdAt;

  StaffTask({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.priority,
    required this.completed,
    required this.createdAt,
  });

  factory StaffTask.fromMap(String id, Map<String, dynamic> data) {
    return StaffTask(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      priority: data['priority'] ?? 'medium',
      completed: data['completed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'priority': priority,
        'completed': completed,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}