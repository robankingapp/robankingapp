import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/bank_service.dart';

class SendMoneyScreen extends StatefulWidget {
  final User? user; // Pass authenticated user

  SendMoneyScreen({Key? key, required this.user}) : super(key: key);

  @override
  _SendMoneyScreenState createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final BankService _bankService = BankService();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String _message = "";

  @override
  void initState() {
    super.initState();
    if (widget.user == null) {
      print("❌ Error: User is not authenticated.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context); // Redirect if not logged in
      });
    }
  }

  Future<void> _sendMoney() async {
    if (widget.user == null) {
      setState(() {
        _message = "User not authenticated.";
      });
      return;
    }
    String senderId = widget.user!.uid;
    String receiverIban = _ibanController.text.trim();
    double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _message = "Invalid amount.";
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = "";
    });
    String result = await _bankService.transferMoney(senderId, receiverIban, amount);
    setState(() {
      _message = result;
      _loading = false;
    });
  }

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
            Center(
              child: ElevatedButton(
                onPressed: _loading ? null : _sendMoney,
                child: _loading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text("Send Money"),
              ),
            ),
            SizedBox(height: 10),
            if (_message.isNotEmpty)
              Center(
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains("❌") ? Colors.red : Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
