import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String userId;
  final String title;
  final String subject;
  final DateTime? deadline;
  final String priority;
  final String notes;
  final bool reminderEnabled;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    this.subject = 'General',
    this.deadline,
    this.priority = 'medium',
    String? notes,
    String? description,
    this.reminderEnabled = false,
    this.isDone = false,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  }) : notes = notes ?? description ?? '';

  // This keeps your old code working if some widgets still use todo.description.
  String get description => notes;

  factory Todo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final priorityValue =
        (data['priority'] ?? 'medium').toString().toLowerCase().trim();

    final safePriority = ['high', 'medium', 'low'].contains(priorityValue)
        ? priorityValue
        : 'medium';

    return Todo(
      id: doc.id,
      userId: (data['user_id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      subject: (data['subject'] ?? 'General').toString(),
      deadline: _nullableDateFrom(data['deadline']),
      priority: safePriority,
      notes: (data['notes'] ?? data['description'] ?? '').toString(),
      reminderEnabled: data['reminder_enabled'] == true,
      isDone: data['is_done'] == true,
      createdAt: _nullableDateFrom(data['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _nullableDateFrom(data['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: _nullableDateFrom(data['completed_at']),
    );
  }

  static DateTime? _nullableDateFrom(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}