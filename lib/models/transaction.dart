import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String senderUid;
  final String receiverUid;
  final String senderIban;
  final String receiverIban;
  final double amount;
  final Timestamp timestamp;

  TransactionModel({
    required this.senderUid,
    required this.receiverUid,
    required this.senderIban,
    required this.receiverIban,
    required this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'senderIban': senderIban,
      'receiverIban': receiverIban,
      'amount': amount,
      'timestamp': timestamp,
    };
  }
}
