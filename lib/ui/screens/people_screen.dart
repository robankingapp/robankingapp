import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PeopleScreen extends StatefulWidget {
  @override
  _PeopleScreenState createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();

  List<Map<String, dynamic>> contacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    var user = _auth.currentUser;
    if (user == null) return;

    var contactsSnapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('contacts')
            .get();

    setState(() {
      contacts = contactsSnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _addContact() async {
    var user = _auth.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _ibanController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    Map<String, dynamic> newContact = {
      'name': _nameController.text.trim(),
      'surname': _surnameController.text.trim(),
      'iban': _ibanController.text.trim(),
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .add(newContact);

    _nameController.clear();
    _surnameController.clear();
    _ibanController.clear();
    _fetchContacts();
  }

  void _sendMoney(String iban) {
    Navigator.pushNamed(context, '/sendMoney', arguments: {'iban': iban});
  }

  void _requestMoney(String iban) async {
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Request Money"),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: "Amount"),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Request"),
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Enter a valid amount")),
                  );
                  return;
                }
                Navigator.of(context).pop(); // close dialog
                await _sendRequest(iban, amount);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendRequest(String recipientIban, double amount) async {
    final sender = FirebaseAuth.instance.currentUser;
    if (sender == null) return;

    // Find recipient UID by IBAN
    final query =
        await FirebaseFirestore.instance
            .collection('users')
            .where('iban', isEqualTo: recipientIban)
            .limit(1)
            .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Recipient not found")));
      return;
    }

    final recipientUid = query.docs.first.id;

    // Write request to recipient's "requests" subcollection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(recipientUid)
        .collection('requests')
        .add({
          'fromUid': sender.uid,
          'fromEmail': sender.email,
          'amount': amount,
          'iban': recipientIban,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Request sent successfully")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("People")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: _surnameController,
                  decoration: InputDecoration(labelText: "Surname"),
                ),
                TextField(
                  controller: _ibanController,
                  decoration: InputDecoration(labelText: "IBAN"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addContact,
                  child: Text("Add Contact"),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                var contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(contact['name'][0])),
                  title: Text("${contact['name']} ${contact['surname']}"),
                  subtitle: Text("IBAN: ${contact['iban']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.green),
                        onPressed: () => _sendMoney(contact['iban']),
                      ),
                      IconButton(
                        icon: Icon(Icons.request_page, color: Colors.blue),
                        onPressed: () => _requestMoney(contact['iban']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
