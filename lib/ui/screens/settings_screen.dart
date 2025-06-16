import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  final User? user;

  const SettingsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = "User";
  String email = "";
  String profilePicture = "";
  String iban = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = widget.user ?? FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        name = data['name'] ?? 'User';
        email = user.email ?? '';
        iban = data['iban'] ?? '';
        profilePicture = data['profilePictureUrl'] ?? '';
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Summary
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                    profilePicture.isNotEmpty ? NetworkImage(profilePicture) : null,
                    child: profilePicture.isEmpty
                        ? const Icon(Icons.person, size: 32, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: Colors.grey)),
                        if (iban.isNotEmpty) Text("IBAN: $iban", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Account Management
          Text("Account", style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildTile(Icons.person, "Personal Details", () {
            Navigator.pushNamed(context, '/profile');
          }),
          _buildTile(Icons.info, "Account Details", () {
            Navigator.pushNamed(context, '/accountDetails');
          }),
          _buildTile(Icons.lock, "Change Password", () {
            Navigator.pushNamed(context, '/changePassword');
          }),

          const SizedBox(height: 24),

          // Legal
          Text("Legal", style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildTile(Icons.policy, "Privacy Policy", () {
            _showLegalDialog("Privacy Policy", "This is a sample privacy policy for demo purposes.");
          }),
          _buildTile(Icons.description, "Terms & Conditions", () {
            _showLegalDialog("Terms & Conditions", "These are some sample terms & conditions.");
          }),

          const SizedBox(height: 24),

          // App info & logout
          Text("App", style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildTile(Icons.info_outline, "App Version", () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Version 1.0.0+1")),
            );
          }),
          _buildTile(Icons.logout, "Logout", _logout, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
