import 'package:flutter/material.dart';
import 'package:bloom_care/screens/emotion_check/emotion_check.dart';
import 'package:bloom_care/screens/emergancy/emergancy_page_1.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom Care',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF87CEEB),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const EmotionCheck(),
        '/emergency': (context) => const EmergencyServicesScreen(),
      },
      navigatorObservers: [RouteObserver<PageRoute>()],
    );
  }
}