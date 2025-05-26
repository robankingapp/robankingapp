import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final User? user;

  HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = "User";
  String userIban = "";
  String currency = "RON";
  String profilePicture = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    var user = widget.user ?? FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        name = userData['name'] ?? "User";
        userIban = userData['iban'] ?? "";
        currency = userData['currency'] ?? "RON";
        profilePicture = userData['profilePictureUrl'] ?? "";
      });
    }
  }

  Widget _buildTransactionList(String userId, String userIban, String currency) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('transactions')
          .where('ownerUid', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final transactions = snapshot.data!.docs;

        if (transactions.isEmpty) return Center(child: Text("No transactions found."));

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index].data() as Map<String, dynamic>;

            final amount = (tx['amount'] ?? 0.0).toDouble();
            final isIncome = amount > 0;
            final displayName = isIncome
                ? tx['senderName'] ?? 'Unknown'
                : tx['receiverName'] ?? 'Unknown';
            final displayIban = isIncome
                ? tx['senderIban'] ?? ''
                : tx['receiverIban'] ?? '';

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
                  "${isIncome ? '+' : '-'}${amount.abs().toStringAsFixed(2)} $currency",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.user ?? FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Hello, $name!", style: TextStyle(color: Colors.white, fontSize: 18)),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                profilePicture.isNotEmpty ? NetworkImage(profilePicture) : null,
                child: profilePicture.isEmpty
                    ? Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  color: Colors.blue,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final funds = (userData['funds'] as num?)?.toDouble() ?? 0.0;

              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$currency ${funds.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text("Your Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction("Send Money", Icons.send, Colors.blue, () {
                  Navigator.pushNamed(context, '/sendMoney').then((_) => _fetchUserData());
                }),
                _buildQuickAction("Request Money", Icons.request_page, Colors.blueAccent, () {
                  Navigator.pushNamed(context, '/requestMoney');
                }),
                _buildQuickAction("More", Icons.more_horiz, Colors.grey, () {
                  // Future feature
                }),
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/transactions');
                  },
                  child: Text("View all"),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildTransactionList(currentUser!.uid, userIban, currency),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "People"),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: "Cards"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/people');
          if (index == 2) Navigator.pushNamed(context, '/cards');
          if (index == 3) Navigator.pushNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
