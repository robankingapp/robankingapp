import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return Scaffold(body: Center(child: Text("Not logged in.")));

    final currentUid = user.uid;

    return Scaffold(
      appBar: AppBar(title: Text("All Transactions")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collectionGroup('transactions')
            .where('ownerUid', isEqualTo: currentUid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final transactions = snapshot.data!.docs;

          if (transactions.isEmpty) {
            return Center(child: Text("No transactions available."));
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index].data() as Map<String, dynamic>;
              final amount = (tx['amount'] ?? 0.0).toDouble();
              final isIncome = amount > 0;
              final displayName = isIncome
                  ? (tx['senderName'] ?? 'Unknown')
                  : (tx['receiverName'] ?? 'Unknown');
              final displayIban = isIncome
                  ? (tx['senderIban'] ?? '')
                  : (tx['receiverIban'] ?? '');

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIncome ? Colors.green : Colors.red,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(displayName, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("IBAN: $displayIban"),
                  trailing: Text(
                    "${isIncome ? '+' : '-'}${amount.abs().toStringAsFixed(2)} RON",
                    style: TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
