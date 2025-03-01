import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user details from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }

  // Fetch user transactions
  Future<List<Map<String, dynamic>>> getUserTransactions(String uid) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('transactions')
          .where('senderUid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching transactions: $e");
    }
    return [];
  }
}
