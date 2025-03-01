import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Ensure user is an admin before executing admin actions
  Future<bool> _isAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.exists && userDoc['role'] == "admin";
  }

  /// ✅ Print Money (Add Funds to an IBAN)
  Future<String> printMoney(String receiverIban, double amount) async {
    if (!(await _isAdmin())) return "Access Denied: Only admins can print money.";

    try {
      QuerySnapshot receiverQuery = await _firestore
          .collection('users')
          .where('iban', isEqualTo: receiverIban)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) return "Receiver IBAN not found.";
      DocumentSnapshot receiverDoc = receiverQuery.docs.first;
      String receiverUid = receiverDoc.id;
      double receiverBalance = receiverDoc['funds'] ?? 0.0;

      // ✅ Update balance
      await receiverDoc.reference.update({'funds': receiverBalance + amount});

      // ✅ Log the transaction
      String txId = _firestore.collection('transactions').doc().id;
      await _firestore.collection('transactions').doc(txId).set({
        'txNumber': txId,
        'amount': amount,
        'date': FieldValue.serverTimestamp(),
        'senderId': "ADMIN",
        'senderIban': "Central Bank",
        'receiverId': receiverUid,
        'receiverIban': receiverIban,
        'status': 'completed',
      });

      return "✅ Funds added successfully!";
    } catch (e) {
      return "❌ Error: $e";
    }
  }

  /// ✅ Promote a User to Admin
  Future<String> promoteToAdmin(String userId) async {
    if (!(await _isAdmin())) return "Access Denied: Only admins can promote users.";

    try {
      await _firestore.collection('users').doc(userId).update({'role': 'admin'});
      return "✅ User promoted to Admin!";
    } catch (e) {
      return "❌ Error promoting user: $e";
    }
  }

  /// ✅ Demote an Admin to User
  Future<String> demoteToUser(String userId) async {
    if (!(await _isAdmin())) return "Access Denied: Only admins can demote users.";

    try {
      await _firestore.collection('users').doc(userId).update({'role': 'user'});
      return "✅ Admin demoted to User!";
    } catch (e) {
      return "❌ Error demoting admin: $e";
    }
  }

  /// ✅ Fetch All Users (for Admin Management)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!(await _isAdmin())) return [];

    try {
      QuerySnapshot userDocs = await _firestore.collection('users').get();
      return userDocs.docs.map((doc) => {'uid': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      print("❌ Error fetching users: $e");
      return [];
    }
  }
}
