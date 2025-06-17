import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _loading = false;
  String _message = "";

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = "";
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentPassController.text,
      );

      await user.reauthenticateWithCredential(cred);

      if (_newPassController.text != _confirmPassController.text) {
        throw FirebaseAuthException(code: 'passwords-do-not-match', message: 'Passwords do not match.');
      }

      await user.updatePassword(_newPassController.text);
      setState(() {
        _message = "Password updated successfully.";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? "Failed to change password.";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains("success") ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              TextFormField(
                controller: _currentPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Current Password"),
                validator: (val) => val == null || val.length < 6 ? "Enter current password" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
                validator: (val) => val != null && val.length >= 6 ? null : "Minimum 6 characters",
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm New Password"),
                validator: (val) => val == _newPassController.text ? null : "Passwords do not match",
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _changePassword,
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Update Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
