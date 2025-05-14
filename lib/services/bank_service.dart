import 'package:cloud_firestore/cloud_firestore.dart';

class BankService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Transfer money from sender to receiver
  Future<String> transferMoney(String senderId, String receiverIban, double amount) async {
    try {
      // Get sender document
      DocumentReference senderDoc = _firestore.collection('users').doc(senderId);

      // Find receiver by IBAN
      QuerySnapshot receiverQuery = await _firestore
          .collection('users')
          .where('iban', isEqualTo: receiverIban)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) return "❌ Receiver not found!";

      DocumentReference receiverDoc = receiverQuery.docs.first.reference;
      String receiverId = receiverQuery.docs.first.id;

      // Generate a unique transaction ID
      String transactionId = _firestore.collection('transactions').doc().id;

      // Run Firestore transaction
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot senderSnapshot = await transaction.get(senderDoc);
        double senderBalance = (senderSnapshot['funds'] as num).toDouble();
        if (senderBalance < amount) throw Exception("❌ Insufficient funds.");

        DocumentSnapshot receiverSnapshot = await transaction.get(receiverDoc);
        double receiverBalance = (receiverSnapshot['funds'] as num).toDouble();

        // Update balances
        transaction.update(senderDoc, {'funds': senderBalance - amount});
        transaction.update(receiverDoc, {'funds': receiverBalance + amount});

        // Add transaction record in common "transactions" collection
        DocumentReference txnRef = _firestore.collection('transactions').doc(transactionId);
        transaction.set(txnRef, {
          'txNumber': transactionId,
          'senderId': senderId,
          'receiverId': receiverId,
          'senderIban': senderSnapshot['iban'],
          'receiverIban': receiverIban,
          'amount': amount,
          'date': FieldValue.serverTimestamp(),
          'status': "completed",
          'senderName': senderSnapshot['name'],
          'receiverName': receiverSnapshot['name'],
        });
      });

      return "✅ Transaction Successful!";
    } catch (e) {
      return "❌ Transaction failed: $e";
    }
  }
}
