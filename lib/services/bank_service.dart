import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';

class BankService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> transferMoney(String senderId, String receiverIban, double amount) async {
    try {
      final senderRef = _firestore.collection('users').doc(senderId);

      final receiverQuery = await _firestore
          .collection('users')
          .where('iban', isEqualTo: receiverIban)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) return "❌ Receiver not found!";

      final receiverRef = receiverQuery.docs.first.reference;
      final receiverId = receiverQuery.docs.first.id;

      final transactionId = _firestore.collection('transactions').doc().id;

      await _firestore.runTransaction((transaction) async {
        final senderSnapshot = await transaction.get(senderRef);
        final receiverSnapshot = await transaction.get(receiverRef);

        final senderBalance = (senderSnapshot['funds'] as num).toDouble();
        final receiverBalance = (receiverSnapshot['funds'] as num).toDouble();

        if (senderBalance < amount) throw Exception("❌ Insufficient funds.");

        transaction.update(senderRef, {'funds': senderBalance - amount});
        transaction.update(receiverRef, {'funds': receiverBalance + amount});

        final txModel = TransactionModel(
          senderUid: senderId,
          receiverUid: receiverId,
          senderIban: senderSnapshot['iban'],
          receiverIban: receiverSnapshot['iban'],
          amount: amount,
          timestamp: Timestamp.now(),
        );

        final baseTxData = txModel.toFirestore()
          ..addAll({
            'txNumber': transactionId,
            'senderName': senderSnapshot['name'],
            'receiverName': receiverSnapshot['name'],
            'status': 'completed',
          });

        // Sender view (negative amount)
        transaction.set(
          senderRef.collection('transactions').doc(transactionId),
          {
            ...baseTxData,
            'amount': -amount,
            'ownerUid': senderId,
          },
        );

        // Receiver view (positive amount)
        if (receiverId != senderId) {
          transaction.set(
            receiverRef.collection('transactions').doc(transactionId),
            {
              ...baseTxData,
              'amount': amount,
              'ownerUid': receiverId,
            },
          );
        }
      });

      return "✅ Transaction Successful!";
    } catch (e) {
      return "❌ Transaction failed: $e";
    }
  }
}
