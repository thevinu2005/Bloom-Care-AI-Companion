import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'local_notification_service.dart';

/// A utility class to handle sending notifications to caregivers
class NotificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a notification to the current user
  Future<void> sendNotification({
    required String type,
    required String title,
    required String message,
    String? itemId,
    bool notifyCaregivers = true,
    bool showLocalNotification = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Determine notification color and icon based on type
      Color notificationColor;
      Color textColor;
      String iconString;

      switch (type) {
        case 'meal':
          notificationColor = const Color(0xFFD1ECF1);
          textColor = const Color(0xFF0C5460);
          iconString = 'restaurant';
          break;
        case 'hobby':
          notificationColor = const Color(0xFFFFF3CD);
          textColor = const Color(0xFF856404);
          iconString = 'sports_esports';
          break;
        case 'appointment':
          notificationColor = const Color(0xFFE2D9F3);
          textColor = const Color(0xFF6A359C);
          iconString = 'event';
          break;
        default:
          notificationColor = const Color(0xFFD1ECF1);
          textColor = const Color(0xFF0C5460);
          iconString = 'notifications';
      }

      // 1. Create notification for the user in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'type': type,
        'title': title,
        'message': message,
        'color': notificationColor.value,
        'textColor': textColor.value,
        'icon': iconString,
        'iconColor': const Color(0xFF6B84DC).value,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'itemId': itemId,
      });

      // 2. Show local notification if requested
      if (showLocalNotification) {
        await LocalNotificationService.showNotification(
          title: title,
          body: message,
          type: type,
          payload: itemId,
        );
      }

      // 3. If notifyCaregivers is true, send notification to assigned caregiver
      if (notifyCaregivers) {
        await _sendNotificationToCaregivers(
          user.uid, 
          type, 
          title, 
          message, 
          notificationColor, 
          textColor, 
          iconString, 
          itemId,
          showLocalNotification,
        );
      }

      print('Notification sent: $title - $message');
    } catch (e) {
      print('Error sending notification: $e');
      throw e;
    }
  }

  // New method to send notifications to caregivers
  Future<void> _sendNotificationToCaregivers(
    String elderUid, 
    String type, 
    String title, 
    String message,
    Color notificationColor,
    Color textColor,
    String iconString,
    String? itemId,
    bool showLocalNotification,
  ) async {
    try {
      // Get the elder's user data to retrieve their name and assigned caregiver
      final elderDoc = await _firestore.collection('users').doc(elderUid).get();
      
      if (!elderDoc.exists) {
        print('Elder document not found');
        return;
      }
      
      final elderData = elderDoc.data()!;
      final elderName = elderData['name'] ?? 'Unknown Elder';
      final assignedCaregiverId = elderData['assignedCaregiver'] as String?;
      
      // If no caregiver is assigned, exit
      if (assignedCaregiverId == null || assignedCaregiverId.isEmpty) {
        print('No caregiver assigned to elder $elderName');
        return;
      }
      
      // Modify the message to indicate which elder has performed the action
      final caregiverMessage = '$elderName $message';
      final caregiverTitle = 'Elder Activity Update';
      
      // Create a notification for the caregiver in Firestore
      await _firestore
          .collection('users')
          .doc(assignedCaregiverId)
          .collection('notifications')
          .add({
        'type': 'elder_activity',  // Special type for caregiver notifications
        'elderName': elderName,
        'elderId': elderUid,
        'activityType': type,      // To know what kind of activity (meal, hobby, etc.)
        'title': caregiverTitle,
        'message': caregiverMessage,
        'color': notificationColor.value,
        'textColor': textColor.value,
        'icon': iconString,
        'iconColor': const Color(0xFF6B84DC).value,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'itemId': itemId,
        'priority': 'normal',  // Can be used for filtering in caregiver's UI
      });
      
      // Get the caregiver's FCM token for push notification
      final caregiverDoc = await _firestore
          .collection('users')
          .doc(assignedCaregiverId)
          .get();
      
      // Show local notification to caregiver if they have the app installed
      if (showLocalNotification) {
        // We can't directly show a local notification on the caregiver's device
        // from the elder's device. Instead, we'll use Firebase Cloud Messaging (FCM)
        // which is handled in the main.dart file.
        
        // However, we can store a flag in Firestore that the caregiver's app
        // can listen for and then show a local notification
        await _firestore
            .collection('users')
            .doc(assignedCaregiverId)
            .collection('pendingNotifications')
            .add({
          'type': type,
          'title': caregiverTitle,
          'message': caregiverMessage,
          'timestamp': FieldValue.serverTimestamp(),
          'processed': false,
        });
      }
      
      print('Caregiver notification sent for $elderName');
    } catch (e) {
      print('Error sending notification to caregiver: $e');
    }
  }

  // Get all notifications for the current user
  Stream<QuerySnapshot> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      throw e;
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
      throw e;
    }
  }

  // New method specifically for sending elder activity notifications to caregivers
  Future<void> notifyCaregiverAboutElderActivity({
    required String activityType,
    required String activityName,
    required String activityDetails,
    String? targetUserId,  // Add this parameter to specify the target user
    bool showLocalNotification = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get user data to verify if they are an elder
      final userData = await _firestore.collection('users').doc(user.uid).get();
      if (!userData.exists) {
        throw Exception('User data not found');
      }
      
      final data = userData.data()!;
      final userType = data['userType'] as String?;
      final userName = data['name'] ?? 'Unknown User';
      
      // If targetUserId is provided, this is a caregiver sending to an elder
      if (targetUserId != null) {
        // Get elder's data
        final elderDoc = await _firestore.collection('users').doc(targetUserId).get();
        if (elderDoc.exists) {
          // Create notification for the elder
          await _firestore
              .collection('users')
              .doc(targetUserId)
              .collection('notifications')
              .add({
            'type': activityType,
            'title': 'Medication Update',
            'message': '$userName has added $activityName - $activityDetails to your medications',
            'color': const Color(0xFFE2D9F3).value,
            'textColor': const Color(0xFF6A359C).value,
            'icon': 'medication',
            'iconColor': const Color(0xFF6B84DC).value,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
          
          // Add pending notification for elder
          if (showLocalNotification) {
            await _firestore
                .collection('users')
                .doc(targetUserId)
                .collection('pendingNotifications')
                .add({
              'type': activityType,
              'title': 'Medication Update',
              'message': '$userName has added $activityName - $activityDetails to your medications',
              'timestamp': FieldValue.serverTimestamp(),
              'processed': false,
            });
          }
          
          print('Notification sent to elder $targetUserId about medication');
          return;
        }
      }
      
      // Only send if the user is an elder (original functionality)
      if (userType?.toLowerCase() != 'elder') {
        print('User is not an elder, not sending caregiver notification');
        return;
      }
      
      // Get assigned caregiver
      final assignedCaregiverId = data['assignedCaregiver'] as String?;
      if (assignedCaregiverId == null || assignedCaregiverId.isEmpty) {
        print('No caregiver assigned to elder $userName');
        return;
      }
      
      // Determine notification styling based on activity type
      Color notificationColor;
      Color textColor;
      String iconString;

      switch (activityType) {
        case 'meal':
          notificationColor = const Color(0xFFD1ECF1);
          textColor = const Color(0xFF0C5460);
          iconString = 'restaurant';
          break;
        case 'hobby':
          notificationColor = const Color(0xFFFFF3CD);
          textColor = const Color(0xFF856404);
          iconString = 'sports_esports';
          break;
        case 'appointment':
          notificationColor = const Color(0xFFE2D9F3);
          textColor = const Color(0xFF6A359C);
          iconString = 'event';
          break;
        case 'mental_health':
          notificationColor = const Color(0xFFE2D9F3);
          textColor = const Color(0xFF6A359C);
          iconString = 'psychology';
          break;
        case 'medicine':
          notificationColor = const Color(0xFFE2D9F3);
          textColor = const Color(0xFF6A359C);
          iconString = 'medication';
          break;
        default:
          notificationColor = const Color(0xFFD1ECF1);
          textColor = const Color(0xFF0C5460);
          iconString = 'notifications';
      }
      
      // Create notification message
      final message = '$userName has added ${activityType == 'meal' ? 'a' : 'an'} $activityType: $activityName - $activityDetails';
      final title = 'Elder Activity Update';
      
      // Send to caregiver's Firestore notifications collection
      await _firestore
          .collection('users')
          .doc(assignedCaregiverId)
          .collection('notifications')
          .add({
        'type': 'elder_activity',
        'elderName': userName,
        'elderId': user.uid,
        'activityType': activityType,
        'activityName': activityName,
        'activityDetails': activityDetails,
        'title': title,
        'message': message,
        'color': notificationColor.value,
        'textColor': textColor.value,
        'icon': iconString,
        'iconColor': const Color(0xFF6B84DC).value,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': 'normal',
      });
      
      // Show local notification to elder
      if (showLocalNotification) {
        await LocalNotificationService.showNotification(
          title: 'Activity Logged',
          body: 'Your $activityType has been logged and your caregiver has been notified',
          type: activityType,
        );
        
        // Add pending notification for caregiver
        await _firestore
            .collection('users')
            .doc(assignedCaregiverId)
            .collection('pendingNotifications')
            .add({
          'type': activityType,
          'title': title,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'processed': false,
        });
      }
      
      print('Caregiver notification sent about $userName\'s $activityType');
    } catch (e) {
      print('Error notifying caregiver about elder activity: $e');
    }
  }
  
  // Check for pending notifications and show them locally
  Future<void> checkAndShowPendingNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get all unprocessed pending notifications
      final pendingNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pendingNotifications')
          .where('processed', isEqualTo: false)
          .get();
      
      // Show each notification locally
      for (var doc in pendingNotifications.docs) {
        final data = doc.data();
        
        // Show the notification
        await LocalNotificationService.showNotification(
          title: data['title'],
          body: data['message'],
          type: data['type'],
        );
        
        // Mark as processed
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('pendingNotifications')
            .doc(doc.id)
            .update({
          'processed': true,
        });
      }
    } catch (e) {
      print('Error checking pending notifications: $e');
    }
  }
}

