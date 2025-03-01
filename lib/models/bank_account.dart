import 'package:cloud_firestore/cloud_firestore.dart';

class BankAccount {
  final String uid; // User ID
  final String iban; // Unique IBAN number
  final double balance; // Account balance
  final Timestamp createdAt;

  BankAccount({
    required this.uid,
    required this.iban,
    required this.balance,
    required this.createdAt,
  });

  // Convert Firestore document to BankAccount object
  factory BankAccount.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BankAccount(
      uid: data['uid'],
      iban: data['iban'],
      balance: (data['balance'] as num).toDouble(),
      createdAt: data['createdAt'],
    );
  }

  // Convert BankAccount object to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'iban': iban,
      'balance': balance,
      'createdAt': createdAt,
    };
  }
}
