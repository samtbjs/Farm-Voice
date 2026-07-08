import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Single place that talks to Firebase Auth + Google Sign-In.
///
/// Every sign-in method returns a [UserCredential] (not just a [User])
/// so screens can check `additionalUserInfo?.isNewUser` and decide
/// whether this is someone's very first time signing in.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleSignInInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize(
      clientId: kIsWeb
        ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
        : null,
);
    _googleSignInInitialized = true;
  }

  /// Opens the Google account picker. Returns null if the farmer
  /// backs out of the picker instead of throwing — everything else
  /// (misconfiguration, network errors) is rethrown so the caller can
  /// show a real error message.
  Future<UserCredential?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final String? idToken = googleUser.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  /// Step 1 of phone sign-in: sends an OTP SMS to [phoneNumber], which
  /// must be in E.164 format (e.g. `+919876543210`).
  ///
  /// Deliberately does NOT use Firebase's "auto-verification" callback
  /// (which can skip the OTP screen entirely on some Android devices) —
  /// the farmer always confirms the code on [OtpVerificationScreen].
  /// That keeps this one predictable path instead of two.
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: onFailed,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Step 2 of phone sign-in: confirms the OTP the farmer typed in.
  Future<UserCredential> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Email sign-in that also silently handles first-time sign-up.
  ///
  /// Tries to sign in first. If Firebase says there's no such account
  /// (or, on newer Firebase versions, the generic "invalid-credential"
  /// used to prevent attackers from telling which emails are
  /// registered), a fresh account is created with the same
  /// email+password instead of showing an error. If that *create* call
  /// then fails with "email-already-in-use", the account did exist all
  /// along and the farmer's password was simply wrong.
  Future<UserCredential> signInOrRegisterWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      final bool looksLikeNoAccount =
          e.code == 'user-not-found' || e.code == 'invalid-credential';
      if (!looksLikeNoAccount) rethrow;

      try {
        return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (createError) {
        if (createError.code == 'email-already-in-use') {
          throw FirebaseAuthException(
            code: 'wrong-password',
            message: 'Incorrect password for this email address.',
          );
        }
        rethrow;
      }
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await user.reload();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignInInitialized) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Not critical — Firebase sign-out above already ended the session.
      }
    }
  }
}