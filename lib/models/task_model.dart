import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable data model for a task document stored at:
///   /users/{uid}/tasks/{taskId}
class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final bool isCompleted;
  final Timestamp createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.isCompleted,
    required this.createdAt,
  });

  // ── Firestore deserialization ─────────────────────────────────────────────

  /// Creates a [TaskModel] from a Firestore [DocumentSnapshot].
  ///
  /// All fields are handled defensively so a missing or malformed field
  /// never causes an unhandled exception in production.
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    // Guard against a document that has been deleted or has no data.
    final raw = doc.data();
    final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

    return TaskModel(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      isCompleted: (data['isCompleted'] as bool?) ?? false,
      // createdAt may be null on the first read while server timestamp
      // is still resolving (pending write); fall back to now().
      createdAt: (data['createdAt'] is Timestamp)
          ? data['createdAt'] as Timestamp
          : Timestamp.now(),
    );
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  /// Converts this model to a map for Firestore writes.
  ///
  /// NOTE: [createdAt] is intentionally omitted here so callers can inject
  /// [FieldValue.serverTimestamp()] for new documents while keeping the
  /// original value for updates.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'isCompleted': isCompleted,
      'createdAt': createdAt,
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    bool? isCompleted,
    Timestamp? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'TaskModel(id: $id, title: $title, isCompleted: $isCompleted)';
}
