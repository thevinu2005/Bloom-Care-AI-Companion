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
import 'package:bloom_care/screens/profile/caregiver_profile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bloom_care/services/local_notification_service.dart';
import 'package:bloom_care/services/notification_service.dart';
import 'dart:async';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// Background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");
  
  // Show a local notification for the background message
  await LocalNotificationService.showNotification(
    title: message.notification?.title ?? 'New Notification',
    body: message.notification?.body ?? '',
    type: message.data['type'] ?? 'default',
    payload: message.data['itemId'],
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize local notifications
  await LocalNotificationService.initialize();
  
  // Set up Firebase Cloud Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Request permission for iOS
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  print('User granted permission: ${settings.authorizationStatus}');
  
  // Get FCM token for this device
  String? token = await messaging.getToken();
  print('FCM Token: $token');
  
  // Save the token to Firestore for the current user if logged in
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && token != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({
      'fcmToken': token,
    });
  }
  
  // Handle token refresh
  messaging.onTokenRefresh.listen((newToken) async {
    print('FCM Token refreshed: $newToken');
    
    // Save the new token to Firestore
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': newToken,
      });
    }
  });
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      
      // Show a local notification
      await LocalNotificationService.showNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        type: message.data['type'] ?? 'default',
        payload: message.data['itemId'],
      );
    }
  });
  
  // Handle notification click when app is in background but not terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A notification was clicked when the app was in the background!');
    // You can navigate to a specific screen based on the message data
  });

  checkForPendingNotifications();
  
  runApp(const MyApp());
}

// In your main.dart file, add this to your app initialization
// This should be in your main() function or in the initState of your root widget
void checkForPendingNotifications() {
  // Check for pending notifications when the app starts
  LocalNotificationService.checkPendingNotifications();
  
  // Set up a periodic check for new notifications
  Timer.periodic(const Duration(minutes: 5), (timer) {
    LocalNotificationService.checkPendingNotifications();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    
    // Check for pending notifications when the app starts
    _checkPendingNotifications();
    
    // Set up auth state listener to update FCM token when user logs in
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        // User is logged in, update their FCM token
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'fcmToken': token,
          });
        }
        
        // Check for pending notifications
        _checkPendingNotifications();
      }
    });
  }
  
  Future<void> _checkPendingNotifications() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await _notificationService.checkAndShowPendingNotifications();
    }
  }

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
        '/welcome': (context) => WelcomePage(),
        '/': (context) => const BloomCareHomePage(),
        '/emergency': (context) => const EmergencyServicesScreen(),
        '/emergency2': (context) => const EmergencyPage2(),
        '/profile': (context) => const ElderCareProfilePage(),
        '/eldernotification': (context) => const NotificationPage(),
        '/caregivernotification': (context) => const CaregiverNotificationPage(),
        '/caregiverhome': (context) => const CaregiverHomePage(),
        '/profile_caregiver': (context) => const CaregiverProfilePage(),
      },
      navigatorObservers: [routeObserver],
    );
  }
}

