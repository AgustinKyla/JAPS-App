import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart'; // Ensure this points to your file

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password, {
    required String username,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _fetchUserDetailsByUsername(username);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign-in error: ${e.code}");
      rethrow;
    }
  }

  Future<void> _fetchUserDetailsByUsername(String username) async {
    try {
      // employee_details documents are keyed by employeeId, not the
      // Firebase Auth UID, so we can't look the doc up by uid. A Firestore
      // equality query is also case-sensitive, so instead of `where`, pull
      // the collection and match the username ourselves - this way small
      // casing differences between what's stored and what's typed don't
      // cause the lookup to silently miss.
      final normalized = username.trim().toLowerCase();
      final snapshot = await _db.collection('employee_details').get();

      final matches = snapshot.docs.where((doc) {
        final storedUsername = (doc.data()['username'] as String? ?? '').trim().toLowerCase();
        return storedUsername == normalized;
      });

      if (matches.isNotEmpty) {
        final doc = matches.first;
        _currentUser = AppUser.fromFirestore(doc.data(), doc.id);
        notifyListeners();
      } else {
        debugPrint("No employee_details doc found for username: $username");
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}