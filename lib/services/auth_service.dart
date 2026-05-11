import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

/// Handles all Firebase Authentication operations.
/// On successful sign-up it also bootstraps the user's top-level
/// Firestore document so the security rules can match /users/{uid}.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Auth state ────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Sign-up ───────────────────────────────────────────────────────────────

  /// Creates a new Firebase Auth account, then writes the user profile
  /// document so that security rules on /users/{uid}/tasks/{taskId} resolve.
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Bootstrap /users/{uid} so Firestore rules work from the first request.
      await _createUserProfile(credential.user!);

      dev.log(
        '[AuthService] Sign-up successful: ${credential.user?.uid}',
        name: 'AUTH',
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      dev.log(
        '[AuthService] Sign-up failed: ${e.code} – ${e.message}',
        name: 'AUTH',
        error: e,
      );
      throw _handleAuthException(e);
    }
  }

  // ── Sign-in ───────────────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      dev.log(
        '[AuthService] Sign-in successful: ${credential.user?.uid}',
        name: 'AUTH',
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      dev.log(
        '[AuthService] Sign-in failed: ${e.code} – ${e.message}',
        name: 'AUTH',
        error: e,
      );
      throw _handleAuthException(e);
    }
  }

  // ── Sign-out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      dev.log('[AuthService] User signed out', name: 'AUTH');
    } catch (e) {
      dev.log('[AuthService] Sign-out error: $e', name: 'AUTH', error: e);
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Writes a minimal user profile document.
  /// Uses [SetOptions(merge: true)] so repeated calls are idempotent.
  Future<void> _createUserProfile(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      await docRef.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': user.uid,
      }, SetOptions(merge: true));
      dev.log(
        '[AuthService] User profile created/updated for uid: ${user.uid}',
        name: 'AUTH',
      );
    } on FirebaseException catch (e) {
      // Log but do not crash – the tasks sub-collection rules are independent.
      dev.log(
        '[AuthService] Could not write user profile: ${e.code} – ${e.message}',
        name: 'AUTH',
        error: e,
      );
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}
