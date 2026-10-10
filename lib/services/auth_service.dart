import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ─── Sign Up ───
  Future<String?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? staffId,
    String? managerId,
    String? restaurantId,
  }) async {
    try {
      print('>>> signUp START: $email');
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('>>> signUp AUTH OK: uid=${cred.user?.uid}');

      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'staffId': staffId,
        'managerId': managerId,
        'restaurantId': restaurantId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('>>> signUp FIRESTORE OK');
      return null;
    } on FirebaseAuthException catch (e) {
      print('>>> signUp AUTH ERROR: ${e.code} — ${e.message}');
      return e.message ?? 'Signup failed';
    } catch (e) {
      print('>>> signUp OTHER ERROR: $e');
      return e.toString();
    }
  }

  // ─── Sign In (email/password) ───
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('>>> signIn START: $email');
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('>>> signIn OK');
      return null;
    } on FirebaseAuthException catch (e) {
      print('>>> signIn AUTH ERROR: ${e.code} — ${e.message}');
      return e.message ?? 'Login failed';
    } catch (e) {
      print('>>> signIn OTHER ERROR: $e');
      return e.toString();
    }
  }

  // ─── Sign In with Google ───
  Future<String?> signInWithGoogle() async {
    try {
      print('>>> Google signIn START');
      UserCredential userCred;

      if (kIsWeb) {
        // Web: use popup
        userCred = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        // Android / iOS: native flow
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCred = await _auth.signInWithCredential(credential);
      }

      print('>>> Google AUTH OK: uid=${userCred.user?.uid}');

      // Create Firestore user doc if this is a first-time Google user
      final uid = userCred.user!.uid;
      final docRef = _db.collection('users').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'uid': uid,
          'name': userCred.user!.displayName ?? '',
          'email': userCred.user!.email ?? '',
          'phone': userCred.user!.phoneNumber ?? '',
          'role': 'customer', // Google sign-ups are always customers
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('>>> Google FIRESTORE user doc created');
      } else {
        print('>>> Google user already exists in Firestore');
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      print('>>> Google AUTH ERROR: ${e.code} — ${e.message}');
      return e.message ?? 'Google sign-in failed';
    } catch (e) {
      print('>>> Google OTHER ERROR: $e');
      return e.toString();
    }
  }

  // ─── Sign Out ───
  Future<void> signOut() async {
    // Also sign out of Google so the account picker reappears next time
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // ignore if user wasn't signed in with Google
      }
    }
    await _auth.signOut();
  }

  // ─── Get role ───
  Future<String?> getUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── Get restaurantId ───
  Future<String?> getUserRestaurantId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['restaurantId'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── Get full profile ───
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
}