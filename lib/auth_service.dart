import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn(
    scopes: <String>['email'],
  );

  // GOOGLE SIGN-IN
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Add this to avoid multi-factor issues on web
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        
        UserCredential userCredential =
            await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } else {
        final googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // EMAIL/PASSWORD REGISTRATION
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Registration Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Registration Error: $e');
      return null;
    }
  } 

  // EMAIL/PASSWORD LOGIN
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  // CHANGE PASSWORD (User must be logged in)
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Change password
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Change Password Error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Change Password Error: $e');
      return false;
    }
  }
  
  // SIGN OUT
  Future<void> signOut() async {
    try {
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn?.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }

  // FORGOT PASSWORD
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Password Reset Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Password Reset Error: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get userStream => _auth.authStateChanges();
}