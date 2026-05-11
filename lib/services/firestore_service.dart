import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:assignments/models/task_model.dart';
import 'dart:developer' as dev;

/// Low-level Firestore service.
///
/// All reads and writes are scoped to:
///   /users/{uid}/tasks/{taskId}
///
/// This matches the production Firestore security rules:
///   match /users/{userId}/tasks/{taskId} {
///     allow read, write: if request.auth != null
///                        && request.auth.uid == userId;
///   }
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Returns the typed, strictly-structured tasks collection reference for
  /// [userId].  Using the explicit nested path avoids any risk of accidentally
  /// hitting a root-level `tasks` collection.
  CollectionReference<Map<String, dynamic>> _tasksRef(String userId) {
    return _db.collection('users').doc(userId).collection('tasks');
  }

  // ── Realtime stream ───────────────────────────────────────────────────────

  /// Returns a real-time stream of all tasks for [userId], ordered newest
  /// first.  The stream automatically updates when Firestore data changes.
  Stream<List<TaskModel>> getUserTasksStream(String userId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid;

    dev.log(
      '[FirestoreService] Stream Request - Requested: $userId, AuthUID: $currentUid',
      name: 'FIRESTORE',
    );

    if (currentUid == null) {
      dev.log(
        '[FirestoreService] WARNING: Attempting to stream tasks without an authenticated user.',
        name: 'FIRESTORE',
      );
      // We still return the stream, as Firestore will handle the permission rejection,
      // but we log it here for debugging.
    } else if (currentUid != userId) {
      dev.log(
        '[FirestoreService] CRITICAL: UID Mismatch! AuthUID ($currentUid) != requested userId ($userId)',
        name: 'FIRESTORE',
      );
    }

    return _tasksRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          dev.log(
            '[FirestoreService] Stream snapshot received – '
            '${snapshot.docs.length} task(s)',
            name: 'FIRESTORE',
          );
          return snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
        })
        .handleError((Object error, StackTrace stack) {
          _logFirestoreError('getUserTasksStream', error, stack);
          // Re-throw so StreamProvider surfaces the error state to the UI.
          throw error;
        });
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Adds a new task document.  [createdAt] is always set via
  /// [FieldValue.serverTimestamp()] for consistency.
  Future<DocumentReference> addTask(String userId, TaskModel task) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    dev.log(
      '[FirestoreService] addTask - Requested: $userId, AuthUID: $currentUid',
      name: 'FIRESTORE',
    );

    try {
      final data = task.toFirestore()
        ..['createdAt'] = FieldValue.serverTimestamp();

      final ref = await _tasksRef(userId).add(data);
      dev.log(
        '[FirestoreService] Task added successfully – id: ${ref.id}',
        name: 'FIRESTORE',
      );
      return ref;
    } on FirebaseException catch (e) {
      _logFirestoreError('addTask', e, StackTrace.current);
      throw _mapFirestoreException(e);
    }
  }

  /// Replaces all writable fields on an existing task document.
  Future<void> updateTask(String userId, TaskModel task) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    dev.log(
      '[FirestoreService] updateTask - Requested: $userId, AuthUID: $currentUid',
      name: 'FIRESTORE',
    );

    try {
      await _tasksRef(userId).doc(task.id).update(task.toFirestore());
      dev.log(
        '[FirestoreService] Task updated successfully – id: ${task.id}',
        name: 'FIRESTORE',
      );
    } on FirebaseException catch (e) {
      _logFirestoreError('updateTask', e, StackTrace.current);
      throw _mapFirestoreException(e);
    }
  }

  /// Deletes a task document by [taskId].
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _tasksRef(userId).doc(taskId).delete();
      dev.log(
        '[FirestoreService] Task deleted – id: $taskId, uid: $userId',
        name: 'FIRESTORE',
      );
    } on FirebaseException catch (e) {
      _logFirestoreError('deleteTask', e, StackTrace.current);
      throw _mapFirestoreException(e);
    }
  }

  /// Flips the [isCompleted] flag using a targeted field update so other
  /// fields are not overwritten.
  Future<void> toggleTaskCompletion(String userId, TaskModel task) async {
    try {
      await _tasksRef(
        userId,
      ).doc(task.id).update({'isCompleted': !task.isCompleted});
      dev.log(
        '[FirestoreService] Task toggled – id: ${task.id}, '
        'isCompleted: ${!task.isCompleted}',
        name: 'FIRESTORE',
      );
    } on FirebaseException catch (e) {
      _logFirestoreError('toggleTaskCompletion', e, StackTrace.current);
      throw _mapFirestoreException(e);
    }
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  void _logFirestoreError(String operation, Object error, StackTrace stack) {
    debugPrint('[FirestoreService] $operation failed: $error');
    dev.log(
      '[FirestoreService] $operation failed: $error',
      name: 'FIRESTORE',
      error: error,
      stackTrace: stack,
    );
  }

  /// Converts raw [FirebaseException] codes into human-readable messages.
  Exception _mapFirestoreException(FirebaseException e) {
    debugPrint('[FirestoreService] Mapping error code: ${e.code}');
    switch (e.code) {
      case 'permission-denied':
        return Exception(
          'Access Denied: You do not have permission to perform this action. '
          'Please ensure you are authenticated correctly.',
        );
      case 'not-found':
        return Exception('The requested resource was not found.');
      case 'unavailable':
        return Exception(
          'Service Unavailable: Please check your internet connection and try again.',
        );
      case 'resource-exhausted':
        return Exception('Quota exceeded. Please try again later.');
      case 'cancelled':
        return Exception('Operation was cancelled.');
      default:
        return Exception(e.message ?? 'An unexpected database error occurred.');
    }
  }
}
