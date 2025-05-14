import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final User? user; // Now we accept a 'user' parameter

  HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String balance = "Loading...";
  String currency = "RON"; // Default currency
  String name = "User";
  String profilePicture = "";
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchTransactions();
  }

  Future<void> _fetchUserData() async {
    var user = widget.user ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ Error: User is not authenticated.");
      return;
    }

    DocumentSnapshot userDoc =
    await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        name = userData['name'] ?? "User";
        balance = userData['funds']?.toString() ?? "0";
        currency = userData.containsKey('currency') ? userData['currency'] : "RON";
        profilePicture = userData['profilePictureUrl'] ?? "";
      });
    } else {
      print("❌ Error: User document not found in Firestore.");
    }
  }

  void _fetchTransactions() {
    var user = widget.user ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ No user is logged in. Cannot fetch transactions.");
      return;
    }

    _firestore
        .collection('transactions')
        .where('senderId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          transactions = snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'senderName': data['senderName'] ?? "Unknown Sender",
              'receiverName': data['receiverName'] ?? "Unknown Receiver",
              'senderIban': data['senderIban'] ?? "No IBAN",
              'receiverIban': data['receiverIban'] ?? "No IBAN",
              'amount': data['amount'] ?? 0.0,
              'date': data['date'] ?? Timestamp.now(),
            };
          }).toList();
        });
      } else {
        setState(() {
          transactions = [];
        });
      }
    }, onError: (error) {
      print("❌ Error fetching transactions: $error");
    });
  }

  Widget _buildTransactionList() {
    if (transactions.isEmpty) {
      return Column(
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          SizedBox(height: 10),
          Text("No transactions yet.",
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        var tx = transactions[index];
        bool isIncome = (tx['amount'] ?? 0) > 0;
        String displayName = isIncome ? tx['senderName'] : tx['receiverName'];
        String displayIban = isIncome ? tx['senderIban'] : tx['receiverIban'];

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIncome ? Colors.green : Colors.red,
              child: Text(
                displayName.isNotEmpty ? displayName[0] : "?",
                style: TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              displayName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("IBAN: $displayIban"),
            trailing: Text(
              "${isIncome ? "+" : "-"}${tx['amount']} RON",
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Hello, $name!",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: profilePicture.isNotEmpty
                    ? NetworkImage(profilePicture)
                    : null,
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
          Container(
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
                  "$currency $balance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text("Your Balance",
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction("Send Money", Icons.send, Colors.blue, () {
                  Navigator.pushNamed(context, '/sendMoney');
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
                Text("Activity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              child: _buildTransactionList(),
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
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
