import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:bloom_care/screens/emergancy/emergancy_page_1.dart';
import 'package:bloom_care/screens/emergancy/emergancy_page_2.dart';
import 'package:bloom_care/screens/splash_screen.dart';
import 'package:bloom_care/screens/home/elders_home.dart';
import 'package:bloom_care/screens/auth/welcome_page.dart';
import 'package:bloom_care/screens/profile/elder_care_profile.dart';
import 'package:bloom_care/screens/notification/elder_notification.dart';
import 'package:bloom_care/screens/notification/caregiver_notification.dart';
import 'package:bloom_care/screens/home/caregviver_home.dart';


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
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomePage(),
        '/': (context) => const BloomCareHomePage(),
        '/emergency': (context) => const EmergencyServicesScreen(),
        '/emergency2': (context) => const EmergencyPage2(),
        '/profile': (context) => const ElderCareProfilePage(),
        '/eldernotification': (context) => const NotificationPage(),
        '/caregivernotification': (context) => const CaregiverNotificationPage(),
        '/caregiverhome': (context) => const CaregiverHomePage(),
        
      },
      navigatorObservers: [routeObserver],
    );
  }
}

