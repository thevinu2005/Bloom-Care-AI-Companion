import 'package:flutter/material.dart';
import 'package:bloom_care/screens/emotion_check/emotion_check.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Check',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF87CEEB), // Light blue background
      ),
      home: const EmotionCheck(),
    );
  }
}