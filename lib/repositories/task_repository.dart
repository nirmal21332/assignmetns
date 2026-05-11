import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignments/models/task_model.dart';
import 'package:assignments/services/firestore_service.dart';

/// Repository layer that sits between providers/UI and [FirestoreService].
///
/// Responsibilities:
///  - Ensure the caller always passes a valid, non-empty [userId].
///  - Translate low-level service errors into domain-level errors when needed.
///  - Provide a single, consistent API surface for all task operations.
class TaskRepository {
  final FirestoreService _service;

  TaskRepository(this._service);

  // ── Realtime data ─────────────────────────────────────────────────────────

  /// Real-time stream of the authenticated user's tasks.
  Stream<List<TaskModel>> watchTasks(String userId) {
    _assertUserId(userId);
    return _service.getUserTasksStream(userId);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Adds a new task.  [createdAt] is set to [FieldValue.serverTimestamp()]
  /// inside [FirestoreService.addTask].
  Future<DocumentReference> addTask(String userId, TaskModel task) {
    _assertUserId(userId);
    return _service.addTask(userId, task);
  }

  /// Updates all mutable fields on an existing task.
  Future<void> updateTask(String userId, TaskModel task) {
    _assertUserId(userId);
    return _service.updateTask(userId, task);
  }

  /// Permanently deletes a task document.
  Future<void> deleteTask(String userId, String taskId) {
    _assertUserId(userId);
    return _service.deleteTask(userId, taskId);
  }

  /// Toggles the [isCompleted] flag without touching other fields.
  Future<void> toggleCompletion(String userId, TaskModel task) {
    _assertUserId(userId);
    return _service.toggleTaskCompletion(userId, task);
  }

  // ── Guards ────────────────────────────────────────────────────────────────

  void _assertUserId(String userId) {
    if (userId.isEmpty) {
      throw StateError(
        'TaskRepository: userId must not be empty. '
        'Ensure the user is authenticated before calling Firestore.',
      );
    }
  }
}
