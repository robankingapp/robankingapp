import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData(
    String uid,
    String name,
    String surname,
    String email,
    String phone,
    String iban,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'surname': surname,
        'email': email,
        'phone': phone,
        'role': 'user', // Default role is "user"
        'iban': iban,
        'funds': 0.0, // Initial funds start at 0
        'createdAt': FieldValue.serverTimestamp(), // Firestore Timestamp
        'transactions': [],
        'profilePictureUrl': '', // Placeholder for profile picture
      });
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  // Fetch user data by UID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }
}
