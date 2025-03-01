import 'package:flutter/material.dart';

class TransferScreen extends StatefulWidget {
  @override
  TransferScreenState createState() => TransferScreenState();
}

class TransferScreenState extends State<TransferScreen> {
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Transfer Money")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Receiver IBAN:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _receiverController, decoration: InputDecoration(hintText: "Enter IBAN")),
            SizedBox(height: 20),
            Text("Amount:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _amountController, decoration: InputDecoration(hintText: "Enter Amount"), keyboardType: TextInputType.number),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle transfer logic
                  print("Transfer Initiated: ${_receiverController.text} - ${_amountController.text}");
                },
                child: Text("Send Money"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
