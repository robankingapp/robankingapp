import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String _message = "";
  double _currentFunds = 0.0;
  String _iban = "";

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  /// ✅ Fetch Admin's Current Funds
  Future<void> _fetchAdminData() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        _currentFunds = (userDoc['funds'] as num).toDouble();
        _iban = userDoc['iban'] ?? "";
      });
    }
  }

  /// ✅ Add Money to Admin's Account
  Future<void> _addMoney() async {
    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || amount > 100000) {
      setState(() => _message = "❌ Enter a valid amount (1 - 100,000)");
      return;
    }

    setState(() => _loading = true);
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentReference userRef = _firestore.collection('users').doc(user.uid);
      await userRef.update({'funds': _currentFunds + amount});

      // ✅ Log Transaction
      String txId = _firestore.collection('transactions').doc().id;
      await _firestore.collection('transactions').doc(txId).set({
        'txNumber': txId,
        'amount': amount,
        'date': FieldValue.serverTimestamp(),
        'senderId': "ADMIN",
        'senderIban': "Central Bank",
        'receiverId': user.uid,
        'receiverIban': _iban,
        'status': 'completed',
      });

      setState(() {
        _currentFunds += amount;
        _message = "✅ Successfully added \$${amount.toStringAsFixed(2)}";
      });

      _amountController.clear();
    } catch (e) {
      setState(() => _message = "❌ Error: $e");
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Panel")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Current Balance: \$${_currentFunds.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Amount to Add"),
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _addMoney,
              icon: Icon(Icons.add),
              label: Text("Add Money"),
            ),
            SizedBox(height: 20),
            Text(_message, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
