import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  final String uid;

  DashboardScreen({required this.uid});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return Center(child: CircularProgressIndicator());
          if (!userSnapshot.data!.exists) return Center(child: Text("User data not found"));

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          var userIban = userData['iban'] ?? '';

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome, ${userData['name']}!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("IBAN: $userIban", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("Balance: \$${(userData['funds'] ?? 0).toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Text("Recent Transactions:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(widget.uid)
                        .collection('transactions')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, transactionSnapshot) {
                      if (!transactionSnapshot.hasData)
                        return Center(child: CircularProgressIndicator());

                      var transactions = transactionSnapshot.data!.docs;

                      if (transactions.isEmpty)
                        return Center(child: Text("No transactions available"));

                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          var txn = transactions[index].data() as Map<String, dynamic>;

                          bool isIncome = txn['receiverIban'] == userIban;
                          String amountText = "${isIncome ? "+" : "-"}${txn['amount']}";
                          Color amountColor = isIncome ? Colors.green : Colors.red;

                          return Card(
                            child: ListTile(
                              title: Text(
                                isIncome
                                    ? "From: ${txn['senderIban']}"
                                    : "To: ${txn['receiverIban']}",
                              ),
                              subtitle: Text(
                                "$amountText RON",
                                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
                              ),
                              trailing: Text("${txn['date'].toDate()}"),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
