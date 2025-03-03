import 'package:flutter/material.dart';
import 'notification_detail.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _activeFilter = 'none';
  String _activeCategory = 'none';
  bool _allRead = true;

  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'medical',
      'title': 'Medication reminder',
      'message': 'Time for your blood pressure medicine!\nTake 1 tablet of Lisinopril at 8:00 AM.',
      'color': const Color(0xFFD1ECF1),
      'textColor': const Color(0xFF0C5460),
      'icon': Icons.medical_services_outlined,
      'iconColor': Colors.blue,
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'frequency': 'daily',
      'isRead': true,
    },
    {
      'type': 'activity',
      'title': 'Activity reminder',
      'message': 'Stretch & Walk Time!\nA 10-minute walk will help boost your energy. Let\'s go!',
      'color': const Color(0xFFFFF3CD),
      'textColor': const Color(0xFF856404),
      'icon': Icons.directions_walk,
      'iconColor': Colors.amber,
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'frequency': 'daily',
      'isRead': true,
    },
    {
      'type': 'mood',
      'title': 'Mood alert',
      'message': 'The AI has detected signs of distress or sadness in Mr.Martin at 7:45 PM. You may want to check in with them.',
      'color': const Color(0xFFE2D9F3),
      'textColor': const Color(0xFF6A359C),
      'icon': Icons.mood_bad,
      'iconColor': Colors.purple,
      'time': DateTime.now().subtract(const Duration(hours: 3)),
      'frequency': 'weekly',
      'isRead': true,
    },
    {
      'type': 'other',
      'title': 'Other',
      'message': '🏥 Upcoming Doctor\'s Appointment\nReminder: Dr. Smith, 10:30 AM tomorrow.',
      'color': const Color(0xFFD4EDDA),
      'textColor': const Color(0xFF155724),
      'icon': Icons.notifications,
      'iconColor': Colors.green,
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'frequency': 'monthly',
      'isRead': true,
    },
  ];

  void _markAllAsUnread() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = false;
      }
      _allRead = false;
    });
  }

  List<Map<String, dynamic>> get filteredNotifications {
    if (_activeFilter == 'none' && _activeCategory == 'none') {
      return _notifications;
    } else if (_activeFilter == 'all') {
      if (_activeCategory == 'none') {
        return _notifications;
      } else {
        return _notifications.where((notification) => notification['type'] == _activeCategory).toList();
      }
    } else if (_activeFilter == 'today') {
      if (_activeCategory == 'none') {
        return _notifications.where((notification) => 
          notification['time'].day == DateTime.now().day &&
          notification['time'].month == DateTime.now().month &&
          notification['time'].year == DateTime.now().year
        ).toList();
      } else {
        return _notifications.where((notification) => 
          notification['frequency'] == _activeCategory &&
          notification['time'].day == DateTime.now().day &&
          notification['time'].month == DateTime.now().month &&
          notification['time'].year == DateTime.now().year
        ).toList();
      }
    }
    return _notifications;
  }

  void _showCategoryDialog(String filterType) {
    List<String> categories = [];
    
    if (filterType == 'all') {
      categories = ['medical', 'activity', 'emergency', 'mood', 'other'];
    } else if (filterType == 'today') {
      categories = ['daily', 'weekly', 'monthly'];
    }
    
    