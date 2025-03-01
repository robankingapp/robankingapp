import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> sendMoney(String receiverIban, double amount) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return "User not logged in.";

      DocumentSnapshot senderDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!senderDoc.exists) return "Sender account not found.";

      var senderData = senderDoc.data() as Map<String, dynamic>;
      double senderBalance = senderData['funds'];
      String senderIban = senderData['iban'];

      if (senderBalance < amount) return "Insufficient funds.";

      QuerySnapshot receiverQuery = await _firestore
          .collection('users')
          .where('iban', isEqualTo: receiverIban)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) return "Receiver IBAN not found.";
      DocumentSnapshot receiverDoc = receiverQuery.docs.first;
      String receiverUid = receiverDoc.id;
      double receiverBalance = receiverDoc['funds'];

      // Perform the transaction
      await _firestore.runTransaction((transaction) async {
        transaction.update(senderDoc.reference, {'funds': senderBalance - amount});
        transaction.update(receiverDoc.reference, {'funds': receiverBalance + amount});

        String txId = _firestore.collection('transactions').doc().id;

        transaction.set(_firestore.collection('transactions').doc(txId), {
          'txNumber': txId,
          'amount': amount,
          'date': FieldValue.serverTimestamp(),
          'senderId': user.uid,
          'senderIban': senderIban,
          'receiverId': receiverUid,
          'receiverIban': receiverIban,
          'status': 'completed',
        });
      });

      return "Transaction successful!";
    } catch (e) {
      return "Transaction failed: $e";
    }
  }
}
