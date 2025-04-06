import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  static final Random _random = Random();

  // Initialize the notification service
  static Future<void> initialize() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();
    
    // Initialize notification settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize notification settings for iOS
    final DarwinInitializationSettings initializationSettingsIOS = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Handle iOS foreground notification
      },
    );
    
    // Combine platform-specific settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        print('Notification clicked: ${response.payload}');
        // You can navigate to specific screens based on the payload
      },
    );
    
    // Request permission (for iOS)
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    
    // For Android 13+, request permission
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }
    
    print('Local notification service initialized');
  }
  
  // Show an immediate notification
  static Future<void> showNotification({
    required String title,
    required String body,
    required String type,
    String? payload,
  }) async {
    // Generate a unique ID for the notification
    int id = _random.nextInt(1000);
    
    // Define notification details for Android
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bloom_care_channel',
      'Bloom Care Notifications',
      channelDescription: 'Notifications for the Bloom Care app',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: _getColorForType(type),
      icon: 'notification_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    
    // Define notification details for iOS
    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    // Combine platform-specific details
    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Show the notification
    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
    
    print('Local notification shown: $title - $body');
  }
  
  // Schedule a notification for a future time
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required String type,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Generate a unique ID for the notification
    int id = _random.nextInt(1000);
    
    // Define notification details for Android
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bloom_care_scheduled_channel',
      'Bloom Care Scheduled Notifications',
      channelDescription: 'Scheduled notifications for the Bloom Care app',
      importance: Importance.max,
      priority: Priority.high,
      color: _getColorForType(type),
      icon: 'notification_icon',
    );
    
    // Define notification details for iOS
    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    // Combine platform-specific details
    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Schedule the notification
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    
    print('Scheduled notification for ${scheduledTime.toString()}: $title - $body');
  }
  
  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
  
  // Cancel a specific notification by ID
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
  
  // Helper method to get color based on notification type
  static Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'meal':
        return const Color(0xFFD1ECF1);
      case 'hobby':
        return const Color(0xFFFFF3CD);
      case 'appointment':
        return const Color(0xFFE2D9F3);
      case 'mental_health':
        return const Color(0xFFE2D9F3);
      default:
        return const Color(0xFF6B84DC);
    }
  }

  // Check for pending notifications for the current user
  static Future<void> checkPendingNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      print('Checking pending notifications for user: ${user.uid}');
      
      // Get all unprocessed pending notifications
      final pendingNotifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pendingNotifications')
          .where('processed', isEqualTo: false)
          .get();
      
      print('Found ${pendingNotifications.docs.length} pending notifications');
      
      // Show each notification locally
      for (var doc in pendingNotifications.docs) {
        final data = doc.data();
        
        // Show the notification
        await showNotification(
          title: data['title'] ?? 'Notification',
          body: data['message'] ?? 'You have a new notification',
          type: data['type'] ?? 'general',
        );
        
        // Mark as processed
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('pendingNotifications')
            .doc(doc.id)
            .update({
          'processed': true,
        });
        
        print('Processed notification: ${doc.id}');
      }
    } catch (e) {
      print('Error checking pending notifications: $e');
    }
  }
}

