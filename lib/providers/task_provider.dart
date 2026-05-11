import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assignments/models/task_model.dart';
import 'package:assignments/services/firestore_service.dart';
import 'package:assignments/repositories/task_repository.dart';
import 'package:assignments/providers/auth_provider.dart';
import 'dart:developer' as dev;

// ── Service / Repository providers ───────────────────────────────────────────

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return TaskRepository(service);
});

// ── Realtime stream ───────────────────────────────────────────────────────────

/// Provides a real-time stream of tasks for a given [userId].
///
/// Usage:
///   final tasksAsync = ref.watch(userTasksStreamProvider(userId));
final userTasksStreamProvider = StreamProvider.family<List<TaskModel>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasks(userId);
});

// ── Convenience provider that auto-resolves the current user ──────────────────

/// Provides a real-time stream using the currently signed-in user's UID.
/// Returns an empty list when no user is signed in (safe fallback).
final currentUserTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    dev.log(
      '[TaskProvider] No authenticated user – returning empty stream.',
      name: 'TASK_PROVIDER',
    );
    return const Stream.empty();
  }
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasks(user.uid);
});

// ── Mutation notifier ─────────────────────────────────────────────────────────

/// Handles all write operations (add / update / delete / toggle) for [userId].
///
/// State is [AsyncValue<void>]:
///   - [AsyncData(null)]  → idle / last operation succeeded
///   - [AsyncLoading()]   → operation in progress
///   - [AsyncError(...)]  → last operation failed
class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repo;
  final String _userId;

  TaskNotifier(this._repo, this._userId) : super(const AsyncValue.data(null));

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> addTask(TaskModel task) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addTask(_userId, task);
      dev.log('[TaskNotifier] addTask succeeded', name: 'TASK_PROVIDER');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      dev.log(
        '[TaskNotifier] addTask failed: $e',
        name: 'TASK_PROVIDER',
        error: e,
        stackTrace: stack,
      );
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> updateTask(TaskModel task) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateTask(_userId, task);
      dev.log(
        '[TaskNotifier] updateTask succeeded – id: ${task.id}',
        name: 'TASK_PROVIDER',
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      dev.log(
        '[TaskNotifier] updateTask failed: $e',
        name: 'TASK_PROVIDER',
        error: e,
        stackTrace: stack,
      );
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteTask(_userId, taskId);
      dev.log(
        '[TaskNotifier] deleteTask succeeded – id: $taskId',
        name: 'TASK_PROVIDER',
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      dev.log(
        '[TaskNotifier] deleteTask failed: $e',
        name: 'TASK_PROVIDER',
        error: e,
        stackTrace: stack,
      );
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // ── Toggle completion ─────────────────────────────────────────────────────

  Future<void> toggleTaskCompletion(TaskModel task) async {
    // No loading state for toggle to avoid flickering in the list.
    try {
      await _repo.toggleCompletion(_userId, task);
      dev.log(
        '[TaskNotifier] toggleCompletion succeeded – id: ${task.id}, '
        'newValue: ${!task.isCompleted}',
        name: 'TASK_PROVIDER',
      );
    } catch (e, stack) {
      dev.log(
        '[TaskNotifier] toggleCompletion failed: $e',
        name: 'TASK_PROVIDER',
        error: e,
        stackTrace: stack,
      );
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final taskNotifierProvider =
    StateNotifierProvider.family<TaskNotifier, AsyncValue<void>, String>((
      ref,
      userId,
    ) {
      final repo = ref.watch(taskRepositoryProvider);
      return TaskNotifier(repo, userId);
    });
