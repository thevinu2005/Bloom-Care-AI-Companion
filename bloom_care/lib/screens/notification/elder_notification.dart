import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notification_detail.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _activeFilter = 'none';
  String _activeCategory = 'none';
  bool _allRead = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get notifications from Firestore
      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> notifications = [];

      for (var doc in notificationsSnapshot.docs) {
        final data = doc.data();
        
        // Convert Firestore timestamp to DateTime
        final timestamp = data['timestamp'] as Timestamp?;
        final DateTime time = timestamp?.toDate() ?? DateTime.now();
        
        // Convert stored color values back to Color objects
        final color = data['color'] != null 
            ? Color(data['color'] as int) 
            : const Color(0xFFD1ECF1);
            
        final textColor = data['textColor'] != null 
            ? Color(data['textColor'] as int) 
            : const Color(0xFF0C5460);
            
        final iconColor = data['iconColor'] != null 
            ? Color(data['iconColor'] as int) 
            : Colors.blue;

        // Convert icon string to IconData
        IconData icon;
        switch (data['icon']) {
          case 'medical_services_outlined':
            icon = Icons.medical_services_outlined;
            break;
          case 'directions_walk':
            icon = Icons.directions_walk;
            break;
          case 'mood_bad':
            icon = Icons.mood_bad;
            break;
          case 'palette':
            icon = Icons.palette;
            break;
          case 'home':
            icon = Icons.home;
            break;
          default:
            icon = Icons.notifications;
        }

        notifications.add({
          'id': doc.id,
          'type': data['type'] ?? 'other',
          'title': data['title'] ?? 'Notification',
          'message': data['message'] ?? '',
          'color': color,
          'textColor': textColor,
          'icon': icon,
          'iconColor': iconColor,
          'time': time,
          'frequency': data['frequency'] ?? 'daily',
          'isRead': data['isRead'] ?? false,
          'hobbyId': data['hobbyId'],
        });
      }

      // If no notifications exist yet, add some sample ones
      if (notifications.isEmpty) {
        notifications.addAll([
          {
            'id': 'sample1',
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
            'id': 'sample2',
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
        ]);
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _allRead = notifications.every((notification) => notification['isRead'] == true);
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
      });

      // Update local state
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
        }
        _allRead = _notifications.every((notification) => notification['isRead'] == true);
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create a batch to update all notifications
      final batch = _firestore.batch();
      
      for (var notification in _notifications) {
        if (notification['id'] != null && notification['id'].toString().startsWith('sample') == false) {
          final notificationRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .doc(notification['id'].toString());
              
          batch.update(notificationRef, {'isRead': true});
        }
      }
      
      await batch.commit();

      // Update local state
      setState(() {
        for (var notification in _notifications) {
          notification['isRead'] = true;
        }
        _allRead = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

                      const Text(
                        '   Notifications',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black87),
                        onPressed: _loadNotifications,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredNotifications.isEmpty
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
                                    // Mark as read when tapped
                                    if (!notification['isRead'] && notification['id'] != null && 
                                        notification['id'].toString().startsWith('sample') == false) {
                                      _markAsRead(notification['id'].toString());
                                    }
                                    
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
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('MMM d, yyyy • h:mm a').format(notification['time']),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: notification['textColor'].withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!notification['isRead'])
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.8),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.circle,
                                              color: Colors.blue,
                                              size: 16,
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
                        onPressed: _markAllAsRead,
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
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}

