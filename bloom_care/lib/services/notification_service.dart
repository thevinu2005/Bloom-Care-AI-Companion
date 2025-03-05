import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

      // 1. Create notification for the user
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

      // 2. If notifyCaregivers is true, send notification to assigned caregiver
      if (notifyCaregivers) {
        await _sendNotificationToCaregivers(user.uid, type, title, message, notificationColor, textColor, iconString, itemId);
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
      
      // Create a notification for the caregiver
      await _firestore
          .collection('users')
          .doc(assignedCaregiverId)
          .collection('notifications')
          .add({
        'type': 'elder_activity',  // Special type for caregiver notifications
        'elderName': elderName,
        'elderId': elderUid,
        'activityType': type,      // To know what kind of activity (meal, hobby, etc.)
        'title': 'Elder Activity Update',
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
      
      // Only send if the user is an elder
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
        default:
          notificationColor = const Color(0xFFD1ECF1);
          textColor = const Color(0xFF0C5460);
          iconString = 'notifications';
      }
      
      // Create notification message
      final message = '$userName has added ${activityType == 'meal' ? 'a' : 'an'} $activityType: $activityName - $activityDetails';
      
      // Send to caregiver
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
        'title': 'Elder Activity Update',
        'message': message,
        'color': notificationColor.value,
        'textColor': textColor.value,
        'icon': iconString,
        'iconColor': const Color(0xFF6B84DC).value,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': 'normal',
      });
      
      print('Caregiver notification sent about $userName\'s $activityType');
    } catch (e) {
      print('Error notifying caregiver about elder activity: $e');
    }
  }
}

