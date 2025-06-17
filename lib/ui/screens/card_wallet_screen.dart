import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CardWalletScreen extends StatefulWidget {
  const CardWalletScreen({Key? key}) : super(key: key);

  @override
  State<CardWalletScreen> createState() => _CardWalletScreenState();
}

class _CardWalletScreenState extends State<CardWalletScreen> {
  final List<_VirtualCard> _cards = [];
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['name'] != null) {
      setState(() {
        userName = data['name'];
      });
    }
  }

  void _addNewCard() {
    if (_cards.length >= 3) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Limit Reached"),
          content: const Text("You can only have a maximum of 3 cards."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    final random = Random();
    final cardNumber = List.generate(4, (_) => (1000 + random.nextInt(8999)).toString()).join(" ");
    final expiryMonth = (random.nextInt(12) + 1).toString().padLeft(2, '0');
    final expiryYear = (DateTime.now().year + random.nextInt(5)).toString().substring(2);

    setState(() {
      _cards.add(_VirtualCard(
        number: cardNumber,
        expiry: "$expiryMonth/$expiryYear",
        name: userName,
        color: _randomGradient(),
      ));
    });
  }

  Gradient _randomGradient() {
    final gradients = [
      LinearGradient(colors: [Colors.indigo, Colors.purple]),
      LinearGradient(colors: [Colors.teal, Colors.green]),
      LinearGradient(colors: [Colors.deepOrange, Colors.red]),
      LinearGradient(colors: [Colors.blueGrey, Colors.black]),
    ];
    return gradients[Random().nextInt(gradients.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Cards")),
      body: _cards.isEmpty
          ? Center(child: Text("No cards added yet", style: Theme.of(context).textTheme.titleMedium))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cards.length,
        itemBuilder: (context, index) => _CardView(card: _cards[index]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCard,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VirtualCard {
  final String number;
  final String expiry;
  final String name;
  final Gradient color;

  _VirtualCard({
    required this.number,
    required this.expiry,
    required this.name,
    required this.color,
  });
}

class _CardView extends StatelessWidget {
  final _VirtualCard card;

  const _CardView({Key? key, required this.card}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 200,
      decoration: BoxDecoration(
        gradient: card.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.credit_card, color: Colors.white, size: 30),
          const Spacer(),
          Text(card.number, style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(card.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text("Exp: ${card.expiry}", style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
