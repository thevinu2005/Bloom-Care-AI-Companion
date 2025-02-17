import 'package:flutter/material.dart';
import 'package:bloom_care/screens/auth/welcomepage.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom Care',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: welcomepage(),
    );
  }
}