import 'package:banking_app1/ui/screens/TransactionsScreen.dart';
import 'package:banking_app1/ui/screens/people_screen.dart';
import 'package:banking_app1/ui/screens/profile_screen.dart';
import 'package:banking_app1/ui/screens/request_money_screen.dart';
import 'package:banking_app1/ui/screens/send_money_screen.dart';
import 'package:banking_app1/ui/screens/sign_up_screen.dart';
import 'package:banking_app1/ui/screens/home_screen.dart';
import 'package:banking_app1/ui/screens/transfer_screen.dart';
import 'package:banking_app1/ui/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a StreamBuilder to listen to authentication changes.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Get the current user if available.
        User? currentUser = snapshot.data;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Banking App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          // Redirect based on login status.
          initialRoute: currentUser == null ? '/login' : '/',
          routes: {
            '/': (context) => HomeScreen(user: currentUser),
            '/transfer': (context) => TransferScreen(),
            '/signup': (context) => SignUpScreen(),
            '/login': (context) => LoginScreen(),
            '/profile': (context) => ProfileScreen(),
            '/sendMoney': (context) => SendMoneyScreen(user: currentUser),
            '/requestMoney': (context) => RequestMoneyScreen(),
            '/people': (context) => PeopleScreen(),
            '/transactions': (context) => TransactionsScreen(),
          },
        );
      },
    );
  }
}
