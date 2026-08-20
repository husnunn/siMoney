import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../state/app_store.dart';

/// Firebase Authentication via Google Sign-In only.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleReady = false;

  /// Web OAuth client ID (client_type 3) — required for idToken on Android.
  static const _serverClientId =
      '937055995641-t7de4n5afqii4s2s9tlql2v10em9roni.apps.googleusercontent.com';

  /// iOS OAuth client ID from GoogleService-Info.plist.
  static const _iosClientId =
      '937055995641-dc8sq7ve00ar07rhmnvau8ov74mptah1.apps.googleusercontent.com';

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> ensureGoogleSignInInitialized() async {
    if (_googleReady || kIsWeb) return;
    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _iosClientId
          : null,
      serverClientId: _serverClientId,
    );
    _googleReady = true;
  }

  /// Upsert Firestore user profile and attach ledger session if any.
  Future<void> bootstrapSession({String? name}) async {
    final user = _auth.currentUser;
    if (user == null) {
      await appStore.clearSession();
      return;
    }
    await appStore.bootstrapSession(user, name: name);
  }

  Future<UserCredential?> signInWithGoogle() async {
    await ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google tidak mengembalikan idToken. Cek SHA-1 & OAuth client.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final cred = await _auth.signInWithCredential(credential);
    await bootstrapSession(name: googleUser.displayName);
    return cred;
  }

  Future<void> signOut() async {
    try {
      if (_googleReady) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // Ignore Google sign-out failures; still clear Firebase session.
    }
    await _auth.signOut();
    await appStore.clearSession();
  }

  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-disabled':
          return 'Akun ini dinonaktifkan.';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet.';
        case 'missing-id-token':
          return error.message ?? 'Gagal login Google.';
        default:
          return error.message ?? 'Autentikasi gagal (${error.code}).';
      }
    }
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'Login Google dibatalkan.';
      }
      return 'Login Google gagal. Coba lagi.';
    }
    if (error is StateError) {
      return error.message;
    }
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'Akses ditolak. Cek koneksi atau aturan Firestore.';
    }
    if (text.contains('unavailable') || text.contains('network')) {
      return 'Tidak ada koneksi internet.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
