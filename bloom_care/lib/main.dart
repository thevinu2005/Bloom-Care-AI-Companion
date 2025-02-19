import 'package:flutter/material.dart';
import 'package:bloom_care/screens/auth/login_screen.dart';
// import 'package:bloom_care/screens/auth/welcomepage.dart';
// import 'package:bloom_care/screens/auth/signup_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom Care',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SignInScreen(),
        // '/forgot-password': (context) => ForgotPasswordScreen(),
        // '/signup': (context) => const SignupPage(),
      },
    );
  }
}