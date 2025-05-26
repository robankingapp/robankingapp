import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String fromIban;
  final String toIban;
  final double amount;
  final DateTime timestamp;

  RequestModel({
    required this.id,
    required this.fromIban,
    required this.toIban,
    required this.amount,
    required this.timestamp,
  });

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      fromIban: data['fromIban'] ?? '',
      toIban: data['toIban'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
