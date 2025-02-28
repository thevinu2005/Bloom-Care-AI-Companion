import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:bloom_care/screens/emotion_check/emotion_check.dart';
import 'package:bloom_care/screens/emergancy/emergancy_page_1.dart';
import 'package:bloom_care/screens/emergancy/emergancy_page_2.dart';
import 'package:bloom_care/screens/splash_screen.dart';
// import 'package:bloom_care/screens/notifications/notifications_page.dart';
// import 'package:bloom_care/screens/profile/caregiver_profile.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF87CEEB),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const EmotionCheck(),
        '/emergency': (context) => const EmergencyServicesScreen(),
        '/emergency2': (context) => const EmergencyPage2(),
        // '/notifications': (context) => const NotificationsPage(),
        // '/profile': (context) => const ProfilePage(),
      },
      navigatorObservers: [routeObserver],
    );
  }
}

