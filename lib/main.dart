import 'package:banking_app1/ui/screens/profile_screen.dart';
import 'package:banking_app1/ui/screens/request_money_screen.dart';
import 'package:banking_app1/ui/screens/send_money_screen.dart';
import 'package:banking_app1/ui/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:banking_app1/ui/screens/home_screen.dart';
import 'package:banking_app1/ui/screens/transfer_screen.dart';
import 'package:banking_app1/ui/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Banking App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/transfer': (context) => TransferScreen(),
        '/signup': (context) => SignUpScreen(),
        '/login': (context) => LoginScreen(),
        '/profile': (context) => ProfileScreen(),
        '/sendMoney': (context) => SendMoneyScreen(),
        '/requestMoney': (context) => RequestMoneyScreen(),
      },
    );
  }
}
