import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String balance = "Loading...";
  String currency = "USD"; // Placeholder, will fetch from DB
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
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          name = userData['name'] ?? "User"; // ✅ Fix Name Display
          balance = userData['funds']?.toString() ?? "0"; // ✅ Fix Balance Display
          currency = userData.containsKey('currency') ? userData['currency'] : "USD"; // ✅ Use Default Currency
          profilePicture = userData['profilePictureUrl'] ?? "";
        });
      }
    }
  }

  void _fetchTransactions() {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('transactions')
          .where('senderId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        if (snapshot.docs.isNotEmpty) {
          print("📌 Transactions found: ${snapshot.docs.length}");
          setState(() {
            transactions = snapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              return {
                'senderName': data['senderName'] ?? "Unknown Sender",
                'senderSurname': data['senderSurname'] ?? "",
                'receiverName': data['receiverName'] ?? "Unknown Receiver",
                'receiverSurname': data['receiverSurname'] ?? "",
                'senderIban': data['senderIban'] ?? "No IBAN",
                'receiverIban': data['receiverIban'] ?? "No IBAN",
                'amount': data['amount'] ?? 0.0,
                'date': data['date'] ?? Timestamp.now(), // Default to now if missing
              };
            }).toList();
          });
        } else {
          print("⚠️ No transactions found for user ${user.uid}");
          setState(() {
            transactions = [];
          });
        }
      }, onError: (error) {
        print("❌ Error fetching transactions: $error");
      });
    }
  }

  Widget _buildTransactionList() {
    if (transactions.isEmpty) {
      return Column(
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          SizedBox(height: 10),
          Text(
            "No transactions yet.",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      );
    }

    return Column(
      children: transactions.map((tx) {
        bool isIncome = (tx['amount'] ?? 0) > 0;
        String senderName = tx['senderName'] ?? "Unknown Sender";
        String senderSurname = tx['senderSurname'] ?? "";
        String receiverName = tx['receiverName'] ?? "Unknown Receiver";
        String receiverSurname = tx['receiverSurname'] ?? "";
        String displayName = isIncome ? "$senderName $senderSurname" : "$receiverName $receiverSurname";
        String displayIban = isIncome ? tx['senderIban'] : tx['receiverIban'];

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome ? Colors.green : Colors.red,
            child: Text(
              displayName[0], // First letter of name
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
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hello, $name!",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile'); // Navigate to profile
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    profilePicture.isNotEmpty
                        ? NetworkImage(profilePicture)
                        : null,
                child:
                    profilePicture.isEmpty
                        ? Icon(Icons.person, color: Colors.grey)
                        : null,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Balance Section
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
                Text(
                  "Your Balance",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction("Send Money", Icons.send, Colors.blue, () {
                  Navigator.pushNamed(context, '/sendMoney');
                }),
                _buildQuickAction(
                  "Request Money",
                  Icons.request_page,
                  Colors.blueAccent,
                  () {
                    Navigator.pushNamed(context, '/requestMoney');
                  },
                ),
                _buildQuickAction("More", Icons.more_horiz, Colors.grey, () {
                  // Future feature
                }),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Activity Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Activity",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/transactions',
                    ); // Full transaction list
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

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        // Home selected
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "People"),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: "Cards",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/people');
          if (index == 2) Navigator.pushNamed(context, '/cards');
          if (index == 3) Navigator.pushNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
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
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
