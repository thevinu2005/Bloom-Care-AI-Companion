import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationDetailPage extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailPage({
    Key? key,
    required this.notification,
  }) : super(key: key);

  Future<void> _logHobbyActivity(BuildContext context) async {
    // Check if this notification is related to a hobby
    if (notification['hobbyId'] == null) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final hobbyId = notification['hobbyId'];
      final today = DateTime.now().toString().substring(0, 10);

      // Get the current hobby data
      final hobbyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('hobbies')
          .doc(hobbyId)
          .get();

      if (!hobbyDoc.exists) {
        throw Exception('Hobby not found');
      }

      final hobbyData = hobbyDoc.data()!;
      final newActivityCount = (hobbyData['activityCount'] as int? ?? 0) + 1;

      // Update the hobby with new activity count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('hobbies')
          .doc(hobbyId)
          .update({
        'lastDone': today,
        'activityCount': newActivityCount,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${hobbyData['name']} logged for today!'),
          backgroundColor: const Color(0xFF6B84DC),
        ),
      );
    } catch (e) {
      print('Error logging hobby activity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging activity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely format the timestamp with extensive error handling
    String formattedTime = 'Unknown time';
    try {
      if (notification.containsKey('time')) {
        final time = notification['time'] as DateTime;
        formattedTime = DateFormat('h:mm a').format(time);
      }
    } catch (e) {
      print('Error formatting time: $e');
      // Final fallback
      try {
        formattedTime = notification['formattedTime']?.toString() ?? 'Unknown time';
      } catch (e) {
        print('Error getting formatted time: $e');
      }
    }
    
    // Get notification type and other details
    String notificationType = notification['type']?.toString() ?? 'Unknown';
    String title = notification['title']?.toString() ?? 'Notification';
    String message = notification['message']?.toString() ?? '';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Notification Details',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notification['color'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    notification['icon'],
                    color: notification['textColor'],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: notification['textColor'],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notification Details Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notification Type
                  _buildDetailCard(
                    icon: Icons.category_outlined,
                    title: 'Type',
                    value: notificationType.substring(0, 1).toUpperCase() + notificationType.substring(1),
                  ),
                  
                  // Time
                  _buildDetailCard(
                    icon: Icons.access_time,
                    title: 'Time',
                    value: formattedTime,
                  ),
                  
                  // Message
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.message_outlined, color: Colors.grey[600], size: 24),
                              const SizedBox(width: 16),
                              const Text(
                                'Message',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons (if this is a hobby notification)
            if (notification['hobbyId'] != null) ...[
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _logHobbyActivity(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Log this activity now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B84DC),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

