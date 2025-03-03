import 'package:flutter/material.dart';
import 'notification_detail.dart';

class CaregiverNotificationPage extends StatefulWidget {
  const CaregiverNotificationPage({Key? key}) : super(key: key);

  @override
  State<CaregiverNotificationPage> createState() => _CaregiverNotificationPageState();
}

class _CaregiverNotificationPageState extends State<CaregiverNotificationPage> {
  String _activeFilter = 'none';
  String _activeCategory = 'none';
  String? _selectedElder;
  bool _allRead = true;

  // Elder information integrated into a simple list
  final List<Map<String, dynamic>> _elders = [
    {
      'id': '1',
      'name': 'Mr. Martin',
      'imageUrl': 'assets/elder1.jpg',
      'status': 'Normal',
    },
    {
      'id': '2',
      'name': 'Mrs. Johnson',
      'imageUrl': 'assets/elder2.jpg',
      'status': 'Needs Attention',
    },
    {
      'id': '3',
      'name': 'Mr. Williams',
      'imageUrl': 'assets/elder3.jpg',
      'status': 'Normal',
    },
  ];

  final List<Map<String, dynamic>> _notifications = [
    {
      'elderId': '1',
      'elderName': 'Mr. Martin',
      'elderImage': 'assets/elder1.jpg',
      'elderStatus': 'Normal',
      'type': 'emergency',
      'title': 'Emergency alert',
      'message': 'Emergency Alert from Mr.Martin!\nMr.Martin has pressed the emergency button at 3:15 PM. Please check on them immediately',
      'color': const Color(0xFFF8D7DA),
      'textColor': const Color(0xFF721C24),
      'icon': Icons.warning_amber_rounded,
      'iconColor': Colors.red,
      'time': DateTime.now(),
      'frequency': 'daily',
      'isRead': true,
    },
    {
      'elderId': '2',
      'elderName': 'Mrs. Johnson',
      'elderImage': 'assets/elder2.jpg',
      'elderStatus': 'Needs Attention',
      'type': 'medical',
      'title': 'Medication reminder',
      'message': 'Mrs. Johnson needs to take blood pressure medicine!\nOne tablet of Lisinopril at 8:00 AM.',
      'color': const Color(0xFFD1ECF1),
      'textColor': const Color(0xFF0C5460),
      'icon': Icons.medical_services_outlined,
      'iconColor': Colors.blue,
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'frequency': 'daily',
      'isRead': true,
    },
    {
      'elderId': '3',
      'elderName': 'Mr. Williams',
      'elderImage': 'assets/elder3.jpg',
      'elderStatus': 'Normal',
      'type': 'activity',
      'title': 'Activity reminder',
      'message': 'Time for Mr. Williams\' walk!\nA 10-minute walk will help boost energy levels.',
      'color': const Color(0xFFFFF3CD),
      'textColor': const Color(0xFF856404),
      'icon': Icons.directions_walk,
      'iconColor': Colors.amber,
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'frequency': 'daily',
      'isRead': true,
    },
    {
      'elderId': '1',
      'elderName': 'Mr. Martin',
      'elderImage': 'assets/elder1.jpg',
      'elderStatus': 'Normal',
      'type': 'mood',
      'title': 'Mood alert',
      'message': 'The AI has detected signs of distress in Mr.Martin at 7:45 PM. Please check on them.',
      'color': const Color(0xFFE2D9F3),
      'textColor': const Color(0xFF6A359C),
      'icon': Icons.mood_bad,
      'iconColor': Colors.purple,
      'time': DateTime.now().subtract(const Duration(hours: 3)),
      'frequency': 'weekly',
      'isRead': true,
    },
    {
      'elderId': '2',
      'elderName': 'Mrs. Johnson',
      'elderImage': 'assets/elder2.jpg',
      'elderStatus': 'Needs Attention',
      'type': 'other',
      'title': 'Appointment reminder',
      'message': '🏥 Mrs. Johnson\'s Doctor\'s Appointment\nDr. Smith, 10:30 AM tomorrow.',
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
    var notifications = _notifications;
    
    if (_selectedElder != null) {
      notifications = notifications.where((n) => n['elderId'] == _selectedElder).toList();
    }

    if (_activeFilter == 'none' && _activeCategory == 'none') {
      return notifications;
    } else if (_activeFilter == 'all') {
      if (_activeCategory == 'none') {
        return notifications;
      } else {
        return notifications.where((notification) => notification['type'] == _activeCategory).toList();
      }
    } else if (_activeFilter == 'today') {
      if (_activeCategory == 'none') {
        return notifications.where((notification) => 
          notification['time'].day == DateTime.now().day &&
          notification['time'].month == DateTime.now().month &&
          notification['time'].year == DateTime.now().year
        ).toList();
      } else {
        return notifications.where((notification) => 
          notification['frequency'] == _activeCategory &&
          notification['time'].day == DateTime.now().day &&
          notification['time'].month == DateTime.now().month &&
          notification['time'].year == DateTime.now().year
        ).toList();
      }
    }
    return notifications;
  }

  void _showCategoryDialog(String filterType) {
    List<String> categories = [];
    
    if (filterType == 'all') {
      categories = ['medical', 'activity', 'emergency', 'other'];
    } else if (filterType == 'today') {
      categories = ['daily', 'weekly', 'monthly'];
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select ${filterType == 'all' ? 'Category' : 'Frequency'}'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    categories[index].substring(0, 1).toUpperCase() + 
                    categories[index].substring(1),
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    setState(() {
                      _activeFilter = filterType;
                      _activeCategory = categories[index];
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Show All'),
              onPressed: () {
                setState(() {
                  _activeFilter = filterType;
                  _activeCategory = 'none';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildElderSelector() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _elders.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedElder = null;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _selectedElder == null ? Colors.blue : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
  