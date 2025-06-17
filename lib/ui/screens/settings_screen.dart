import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), backgroundColor: primary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Summary
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        profilePicture.isNotEmpty
                            ? NetworkImage(profilePicture)
                            : null,
                    child:
                        profilePicture.isEmpty
                            ? const Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: Colors.grey)),
                        if (iban.isNotEmpty)
                          Text(
                            "IBAN: $iban",
                            style: const TextStyle(fontSize: 12),
                          ),
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
            Navigator.pushNamed(context, '/profile');
          }),
          _buildTile(Icons.lock, "Change Password", () {
            Navigator.pushNamed(context, '/changePassword');
          }),

          const SizedBox(height: 24),

          // Legal
          Text("Legal", style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildTile(Icons.policy, "Privacy Policy", () {
            _showLegalDialog("Privacy Policy", """Last updated: June 16, 2025

1. Introduction
We value your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile banking application.

By using our app, you agree to the collection and use of information in accordance with this policy.

2. Information We Collect
We may collect the following information:
• Personal identification data (e.g., name, email, IBAN)
• Profile picture and contact details
• Transaction history and activity logs
• Technical data such as device type, OS version, and app usage

This data is used to provide you with secure and personalized banking features.

3. Use of Your Information
We use your information to:
• Authenticate users and prevent fraud
• Facilitate transactions between users
• Display account details and balances
• Improve app performance and user experience
• Comply with legal obligations

We do not sell or share your personal data for marketing purposes.

4. Data Storage and Security
All user data is stored securely in Firebase services, protected with encryption and access controls. Only authorized systems and personnel can access sensitive information.

While we implement reasonable safeguards, no method of transmission over the Internet or method of electronic storage is 100% secure.

5. Third-Party Services
Our app may integrate third-party services such as Firebase Authentication, Firestore Database, and Stripe Payments. These services have their own privacy policies which we encourage you to review.

6. Your Rights
You have the right to:
• Access or update your personal data
• Request deletion of your account
• Withdraw consent at any time

To exercise these rights, contact our support team at support@yourappdomain.com.

7. Changes to This Policy
We may update our Privacy Policy from time to time. You will be notified of any significant changes within the app or via email.

8. Contact Us
If you have any questions about this policy, please contact us at:
privacy@yourappdomain.com

This Privacy Policy is effective as of the date shown above.""");
          }),
          _buildTile(Icons.description, "Terms & Conditions", () {
            _showLegalDialog(
              "Terms & Conditions",
              """Last updated: June 16, 2025

1. Acceptance of Terms
By using this mobile banking application, you agree to be bound by these Terms and Conditions. If you do not agree, you must not access or use the app.

2. Eligibility
You must be at least 18 years old and legally capable of entering into binding agreements to use this app.

3. Use of the App
You agree to use the app only for lawful purposes. You may not use the app:
• To engage in fraudulent or illegal activities
• To impersonate another person or entity
• To interfere with the operation of the app or its security features

4. User Accounts
You are responsible for maintaining the confidentiality of your login credentials. You agree to notify us immediately of any unauthorized use of your account.

We reserve the right to suspend or terminate accounts found to be in violation of these terms.

5. Transactions
The app enables peer-to-peer transactions, balance tracking, and request features. By initiating a transaction, you authorize us to process and record it.

We are not responsible for the content or accuracy of user-submitted transaction data.

6. Intellectual Property
All content, branding, and code associated with the app are the intellectual property of the company and may not be copied, modified, or distributed without written permission.

7. Limitation of Liability
To the fullest extent permitted by law, we shall not be liable for:
• Any loss of data, revenue, or profits
• Errors, bugs, or security breaches beyond our control
• Third-party service interruptions

Use of the app is at your own risk.

8. Termination
We reserve the right to suspend or terminate your access to the app at any time, with or without notice, for conduct we believe violates these terms or is otherwise harmful to other users or our operations.

9. Modifications
We may revise these Terms & Conditions at any time. Continued use of the app after changes constitutes your acceptance of the new terms.

10. Governing Law
These terms shall be governed by and interpreted in accordance with the laws of the jurisdiction in which our company is registered.

11. Contact
For questions or concerns, please contact:
terms@yourappdomain.com""",
            );
          }),

          const SizedBox(height: 24),

          // App info & logout
          Text("App", style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildTile(Icons.info_outline, "App Version", () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Version 1.0.0+1")));
          }),
          _buildTile(Icons.logout, "Logout", _logout, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
