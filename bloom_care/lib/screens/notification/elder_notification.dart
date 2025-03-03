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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assest/images/notification page background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.3),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
                Colors.white.withOpacity(0.5),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            children: [
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredNotifications.length,
                        padding: const EdgeInsets.all(12.0),
                        itemBuilder: (context, index) {
                          final notification = filteredNotifications[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            elevation: 2,
                            color: notification['color'],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationDetailPage(
                                      notification: notification,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: notification['iconColor'].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        notification['icon'],
                                        color: notification['iconColor'],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notification['title'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: notification['textColor'],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notification['message'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: notification['textColor'],
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (notification['isRead'])
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        label: const Text(
                          'Mark all as read',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          _markAllAsUnread();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications marked as unread'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.green,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.green, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showCategoryDialog('all');
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: _activeFilter == 'all' ? Colors.white : Colors.blue,
                        backgroundColor: _activeFilter == 'all' ? Colors.blue : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        side: const BorderSide(color: Colors.blue, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'All',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showCategoryDialog('today');
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: _activeFilter == 'today' ? Colors.white : Colors.blue,
                        backgroundColor: _activeFilter == 'today' ? Colors.blue : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        side: const BorderSide(color: Colors.blue, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}