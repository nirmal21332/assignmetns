import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assignments/services/auth_service.dart';
import 'dart:developer' as dev;

// ── Service provider ──────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Auth state stream ─────────────────────────────────────────────────────────

/// Real-time stream of [User?] that drives all auth-aware UI.
/// Emits `null` when signed out and a [User] when signed in.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Synchronous snapshot of the currently signed-in user.
/// Returns `null` when no user is authenticated.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Handles sign-up, sign-in, and sign-out mutations.
///
/// State is [AsyncValue<User?>]:
///   - [AsyncLoading()]     → auth state not yet resolved / operation in flight
///   - [AsyncData(user)]    → resolved; user is non-null when signed in
///   - [AsyncError(e, st)]  → last operation failed
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen(
      (user) {
        dev.log(
          '[AuthNotifier] authState changed – uid: ${user?.uid ?? 'null'}',
          name: 'AUTH',
        );
        state = AsyncValue.data(user);
      },
      onError: (Object error, StackTrace stack) {
        dev.log(
          '[AuthNotifier] authState error: $error',
          name: 'AUTH',
          error: error,
          stackTrace: stack,
        );
        state = AsyncValue.error(error, stack);
      },
    );
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signUpWithEmail(email, password);
      // State will be updated by the _init() listener automatically.
    } catch (e, stack) {
      dev.log('[AuthNotifier] signUp failed: $e', name: 'AUTH', error: e);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmail(email, password);
      // State will be updated by the _init() listener automatically.
    } catch (e, stack) {
      dev.log('[AuthNotifier] signIn failed: $e', name: 'AUTH', error: e);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e, stack) {
      dev.log('[AuthNotifier] signOut failed: $e', name: 'AUTH', error: e);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthNotifier(authService);
    });
