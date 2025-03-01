import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/bank_service.dart';

class SendMoneyScreen extends StatefulWidget {
  @override
  _SendMoneyScreenState createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final BankService _bankService = BankService();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String _message = "";

  /// ✅ Function to send money
  Future<void> _sendMoney() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ Error: No user logged in.");
      return;
    }

    String senderId = user.uid;
    String receiverIban = _ibanController.text.trim();
    double amount = double.parse(_amountController.text.trim());

    if (amount <= 0) {
      print("❌ Error: Invalid amount.");
      return;
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference senderDoc = firestore.collection('users').doc(senderId);

      // ✅ Find receiver by IBAN
      QuerySnapshot receiverQuery = await firestore
          .collection('users')
          .where('iban', isEqualTo: receiverIban)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) {
        print("❌ Error: Receiver IBAN not found.");
        return;
      }

      DocumentReference receiverDoc = receiverQuery.docs.first.reference;
      String receiverId = receiverQuery.docs.first.id;

      await firestore.runTransaction((transaction) async {
        // ✅ Fetch sender account
        DocumentSnapshot senderSnapshot = await transaction.get(senderDoc);
        double senderBalance = (senderSnapshot['funds'] as num).toDouble();

        if (senderBalance < amount) {
          print("❌ Error: Insufficient funds.");
          return;
        }

        // ✅ Fetch receiver account
        DocumentSnapshot receiverSnapshot = await transaction.get(receiverDoc);
        double receiverBalance = (receiverSnapshot['funds'] as num).toDouble();

        // ✅ Update balances
        transaction.update(senderDoc, {'funds': senderBalance - amount});
        transaction.update(receiverDoc, {'funds': receiverBalance + amount});

        // ✅ Store transaction record
        DocumentReference transactionRef =
        firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'senderId': senderId,
          'receiverId': receiverId,
          'senderIban': senderSnapshot['iban'],
          'receiverIban': receiverIban,
          'amount': amount,
          'date': FieldValue.serverTimestamp(),
          'validate': true,
        });
      });

      print("✅ Transaction Successful!");
    } catch (e) {
      print("❌ Transaction failed: $e");
    }
  }

  /// ✅ UI Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Send Money")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ibanController,
              decoration: InputDecoration(labelText: "Receiver IBAN"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Amount"),
            ),
            SizedBox(height: 20),

            // ✅ Send Money Button with Loading
            Center(
              child: ElevatedButton(
                onPressed: _loading ? null : _sendMoney, // ✅ Disable when loading
                child: _loading
                    ? SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text("Send Money"),
              ),
            ),

            SizedBox(height: 10),

            // ✅ Show Message (Success/Error)
            if (_message.isNotEmpty)
              Center(
                child: Text(
                  _message,
                  style: TextStyle(color: _message.contains("❌") ? Colors.red : Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
