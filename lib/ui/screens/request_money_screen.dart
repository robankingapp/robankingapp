import 'package:flutter/material.dart';
import '../../services/request_service.dart';

class RequestMoneyScreen extends StatefulWidget {
  @override
  _RequestMoneyScreenState createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> {
  final RequestService _requestService = RequestService();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String _message = "";

  Future<void> _requestMoney() async {
    setState(() => _loading = true);
    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _message = "Invalid amount.";
        _loading = false;
      });
      return;
    }

    String response = await _requestService.requestMoney(_ibanController.text, amount);

    setState(() {
      _message = response;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request Money")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _ibanController, decoration: InputDecoration(labelText: "Requester IBAN")),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Amount")),
            SizedBox(height: 20),
            _loading ? CircularProgressIndicator() : ElevatedButton(onPressed: _requestMoney, child: Text("Request Money")),
            if (_message.isNotEmpty) Text(_message, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
