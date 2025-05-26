import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'firestore_service.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> signInWithEmail(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          String role = userDoc['role'] ?? "user";

          if (role == "admin") {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      print("❌ Sign In Error: $e");
    }
  }
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Sign Out Error: $e");
    }
  }
  String generateUniqueIBAN(String userId) {
    final random = Random();

    String countryCode = "IR"; // IBAN
    String randomDigits = "${random.nextInt(90) + 10}"; // Random 2-digit number (10-99)
    String accountNumber = List.generate(8, (_) => random.nextInt(10)).join(); // Random 8-digit number

    return "RONB $countryCode$randomDigits-$accountNumber"; // IBAN format: RONB IRXX-XXXX-XXXX
  }

}
