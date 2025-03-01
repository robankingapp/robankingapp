import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/dashboard_controller.dart';
import '../screens/home_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String uid;
  DashboardScreen({required this.uid});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DashboardController _dashboardController = DashboardController();

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    var userDetails = await _dashboardController.getUserData(widget.uid);
    var userTransactions = await _dashboardController.getUserTransactions(widget.uid);

    setState(() {
      userData = userDetails;
      transactions = userTransactions;
      isLoading = false;
    });
  }

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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userData == null
          ? Center(child: Text("Error loading data"))
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, ${userData!['name']}!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("IBAN: ${userData!['iban']}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Balance: \$${userData!['funds'].toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text("Recent Transactions:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: transactions.isEmpty
                  ? Center(child: Text("No transactions available"))
                  : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  var txn = transactions[index];
                  return Card(
                    child: ListTile(
                      title: Text("To: ${txn['receiverIban']}"),
                      subtitle: Text("\$${txn['amount']}"),
                      trailing: Text("${txn['timestamp'].toDate()}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
