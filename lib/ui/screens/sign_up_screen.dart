import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'dart:math';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _currentStep = 0;
  bool _loading = false;
  String _errorMessage = '';
  bool _showErrorBanner = false;
  bool _isAdmin = false;

  final _formKey = GlobalKey<FormState>();

  String _generateIBAN(String userId) {
    final random = Random();
    String countryCode = "IR";
    String randomDigits = "${random.nextInt(90) + 10}"; // Random 2-digit number (10-99)
    String accountNumber = List.generate(8, (_) => random.nextInt(10)).join(); // Random 8-digit number
    return "RONB $countryCode$randomDigits-$accountNumber";
  }

  Future<void> _signUp() async {
    if (!_validateAllFields()) {
      setState(() => _showErrorBanner = true);
      return;
    }

    setState(() => _loading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        String iban = _generateIBAN(user.uid);
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'email': _emailController.text.trim(),
          'iban': iban,
          'funds': 0.0,
          'profilePicture': "",
          'role': _isAdmin ? "admin" : "user",
          'createdAt': FieldValue.serverTimestamp(),
        });

        print("✅ User Created: ${user.uid}, IBAN: $iban, Role: ${_isAdmin ? 'Admin' : 'User'}");

        // Pass the authenticated user to HomeScreen.
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomeScreen(user: user)));
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Sign-up failed. Please try again.");
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _validateAllFields() {
    if (!_validateField(_nameController, _validateName, 0)) return false;
    if (!_validateField(_surnameController, _validateName, 1)) return false;
    if (!_validateField(_emailController, _validateEmail, 2)) return false;
    if (!_validateField(_passwordController, _validatePassword, 3)) return false;
    return true;
  }

  bool _validateField(TextEditingController controller, String? Function(String?) validator, int step) {
    String? error = validator(controller.text);
    if (error != null) {
      setState(() {
        _errorMessage = error;
        _currentStep = step;
        _showErrorBanner = true;
      });
      return false;
    }
    return true;
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _showErrorBanner = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      setState(() => _showErrorBanner = false);
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return "Field cannot be empty.";
    if (!RegExp(r"^[A-Za-z]+$").hasMatch(value)) return "Only letters allowed.";
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Enter your email.";
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@gmail\.com$").hasMatch(value)) {
      return "Enter a valid Gmail address.";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Enter your password.";
    if (value.length < 8) return "Must be at least 8 characters.";
    if (!RegExp(r"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$").hasMatch(value)) {
      return "Must include uppercase, lowercase, number & special character.";
    }
    return null;
  }

  void _onStepContinue() {
    if (_currentStep < 3) {
      if (_currentStep == 0 && !_validateField(_nameController, _validateName, 0)) return;
      if (_currentStep == 1 && !_validateField(_surnameController, _validateName, 1)) return;
      if (_currentStep == 2 && !_validateField(_emailController, _validateEmail, 2)) return;
      setState(() => _currentStep++);
    } else {
      _signUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Setup Your Account")),
      body: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _showErrorBanner ? 50 : 0,
            color: Colors.redAccent,
            alignment: Alignment.center,
            child: _showErrorBanner
                ? Text(
              _errorMessage,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )
                : SizedBox(),
          ),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              onStepTapped: (step) {
                setState(() => _currentStep = step);
              },
              steps: [
                Step(title: Text("First Name"), content: TextField(controller: _nameController)),
                Step(title: Text("Surname"), content: TextField(controller: _surnameController)),
                Step(title: Text("Email"), content: TextField(controller: _emailController)),
                Step(title: Text("Password"), content: TextField(controller: _passwordController, obscureText: true)),
                Step(
                  title: Text("Account Type"),
                  content: Row(
                    children: [
                      Text("User"),
                      Switch(
                        value: _isAdmin,
                        onChanged: (value) {
                          setState(() => _isAdmin = value);
                        },
                      ),
                      Text("Admin"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: ElevatedButton(
              onPressed: _loading ? null : _signUp,
              child: _loading ? CircularProgressIndicator() : Text("Sign Up"),
            ),
          ),
        ],
      ),
    );
  }
}
