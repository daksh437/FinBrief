import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/google_config.dart';
import 'api_service.dart';

class GoogleSignInCancelled implements Exception {}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(serverClientId: GoogleConfig.webClientId);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> get idToken async => currentUser?.getIdToken();

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw GoogleSignInCancelled();

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // best-effort — proceed to Firebase sign-out regardless
    }
    await _auth.signOut();
  }

  /// Permanently deletes the account and all its data.
  ///
  /// The backend does the work: it needs the Admin SDK to purge Firestore
  /// documents the client can't touch, and to remove the Auth user itself.
  /// Once that succeeds the local session is cleared, which drops the app back
  /// to the login screen through the usual auth stream.
  ///
  /// Throws [AccountDeletionFailed] with a readable message on failure — the
  /// caller is a destructive confirmation dialog and must not fail silently.
  Future<void> deleteAccount() async {
    final res = await ApiService.instance.delete('/auth/account');
    if (res['success'] != true) {
      throw AccountDeletionFailed(
        res['message'] as String? ?? 'Could not delete your account. Please try again.',
      );
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // The account is already gone server-side; a failed Google sign-out
      // shouldn't surface as a deletion error.
    }
    await _auth.signOut();
  }
}

class AccountDeletionFailed implements Exception {
  AccountDeletionFailed(this.message);
  final String message;

  @override
  String toString() => message;
}
