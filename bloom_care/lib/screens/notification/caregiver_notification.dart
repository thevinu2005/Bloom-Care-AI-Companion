import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notification_detail.dart';
import 'package:bloom_care/widgets/navigation_bar_for_caregiver.dart';
import 'dart:async';

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
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _elders = [];
  List<Map<String, dynamic>> _notifications = [];
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupNotificationsStream();
  }
  
  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      _notificationsSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
            _processNotifications(snapshot);
          }, onError: (error) {
            print('Error in notifications stream: $error');
          });
    } catch (e) {
      print('Error setting up notifications stream: $e');
    }
  }
  
  void _processNotifications(QuerySnapshot snapshot) {
    try {
      final List<Map<String, dynamic>> notifications = [];
      
      for (var notificationDoc in snapshot.docs) {
        final notificationData = notificationDoc.data() as Map<String, dynamic>;
        
        // Convert Firestore timestamp to DateTime
        final timestamp = notificationData['timestamp'] as Timestamp?;
        final DateTime time = timestamp?.toDate() ?? DateTime.now();
        
        // Convert stored color values back to Color objects
        final color = notificationData['color'] != null 
            ? Color(notificationData['color'] as int) 
            : const Color(0xFFD1ECF1);
            
        final textColor = notificationData['textColor'] != null 
            ? Color(notificationData['textColor'] as int) 
            : const Color(0xFF0C5460);
            
        final iconColor = notificationData['iconColor'] != null 
            ? Color(notificationData['iconColor'] as int) 
            : Colors.blue;

        // Convert icon string to IconData
        IconData icon;
        switch (notificationData['icon']) {
          case 'warning_amber_rounded':
            icon = Icons.warning_amber_rounded;
            break;
          case 'medical_services_outlined':
            icon = Icons.medical_services_outlined;
            break;
          case 'directions_walk':
            icon = Icons.directions_walk;
            break;
          case 'mood_bad':
            icon = Icons.mood_bad;
            break;
          case 'person_add':
            icon = Icons.person_add;
            break;
          default:
            icon = Icons.notifications;
        }

        notifications.add({
          'id': notificationDoc.id,
          'elderId': notificationData['elderId'] ?? '',
          'elderName': notificationData['elderName'] ?? 'Unknown',
          'elderImage': notificationData['elderImage'] ?? 'assets/elder1.jpg',
          'elderStatus': notificationData['elderStatus'] ?? 'Normal',
          'type': notificationData['type'] ?? 'other',
          'title': notificationData['title'] ?? 'Notification',
          'message': notificationData['message'] ?? '',
          'color': color,
          'textColor': textColor,
          'icon': icon,
          'iconColor': iconColor,
          'time': time,
          'frequency': notificationData['frequency'] ?? 'daily',
          'isRead': notificationData['isRead'] ?? false,
          'status': notificationData['status'], // For caregiver requests
        });
      }

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
          _allRead = notifications.every((notification) => notification['isRead'] == true);
        });
      }
    } catch (e) {
      print('Error processing notifications: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Load assigned elders
      final assignedEldersQuery = await _firestore
          .collection('users')
          .where('assignedCaregiver', isEqualTo: user.uid)
          .where('userType', isEqualTo: 'elder')
          .get();

      final List<Map<String, dynamic>> elders = [];
      
      for (var elderDoc in assignedEldersQuery.docs) {
        final elderData = elderDoc.data();
        elders.add({
          'id': elderDoc.id,
          'name': elderData['name'] ?? 'Unknown',
          'imageUrl': elderData['profileImage'] ?? 'assets/elder1.jpg',
          'status': 'Normal', // Default status
        });
      }

      setState(() {
        _elders = elders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCaregiverRequest(String notificationId, String elderId, bool accept) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update notification status
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': accept ? 'accepted' : 'declined',
        'isRead': true,
      });

      // If accepted, update elder's assigned caregiver
      if (accept) {
        // Get caregiver's name
        final caregiverDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
            
        final caregiverName = caregiverDoc.data()?['name'] ?? 'Unknown Caregiver';

        // Update elder's document
        await _firestore
            .collection('users')
            .doc(elderId)
            .update({
          'assignedCaregiver': user.uid,
          'caregiverName': caregiverName,
        });

        // Update elder's request status
        await _firestore
            .collection('users')
            .doc(elderId)
            .collection('caregiver_requests')
            .doc(user.uid)
            .update({
          'status': 'accepted',
        });

        // Send notification to elder
        await _firestore
            .collection('users')
            .doc(elderId)
            .collection('notifications')
            .add({
          'type': 'caregiver_assigned',
          'title': 'Caregiver Assigned',
          'message': '$caregiverName has accepted your caregiver request',
          'caregiverName': caregiverName,
          'caregiverId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'color': const Color(0xFFD4EDDA).value,
          'textColor': const Color(0xFF155724).value,
          'icon': 'check_circle',
          'iconColor': Colors.green.value,
        });
      } else {
        // If declined, update elder's request status
        await _firestore
            .collection('users')
            .doc(elderId)
            .collection('caregiver_requests')
            .doc(user.uid)
            .update({
          'status': 'declined',
        });

        // Send notification to elder
        await _firestore
            .collection('users')
            .doc(elderId)
            .collection('notifications')
            .add({
          'type': 'caregiver_declined',
          'title': 'Caregiver Request Declined',
          'message': 'Your caregiver request has been declined',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'color': const Color(0xFFF8D7DA).value,
          'textColor': const Color(0xFF721C24).value,
          'icon': 'cancel',
          'iconColor': Colors.red.value,
        });
      }

      // Reload data
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request ${accept ? 'accepted' : 'declined'} successfully'),
          backgroundColor: accept ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('Error handling caregiver request: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
      _allRead = true;
    });
    
    // Update Firestore
    _updateNotificationsReadStatus();
  }

  Future<void> _updateNotificationsReadStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      
      for (var notification in _notifications) {
        final notificationRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notification['id']);
            
        batch.update(notificationRef, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error updating notification status: $e');
    }
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
      categories = ['medical', 'activity', 'emergency', 'other', 'caregiver_request'];
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
                    categories[index].substring(1).replaceAll('_', ' '),
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
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final elder = _elders[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedElder = elder['id'];
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedElder == elder['id'] ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage(elder['imageUrl']),
                      child: elder['status'] == 'Needs Attention'
                          ? Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    elder['name'].split(' ').length > 1 
                        ? elder['name'].split(' ')[1] // Show only last name
                        : elder['name'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaregiverRequestCard(Map<String, dynamic> notification) {
    final bool isPending = notification['status'] == 'pending';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      color: notification['color'],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(notification['elderImage']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['elderName'],
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
                if (!notification['isRead'] && !isPending)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.circle,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleCaregiverRequest(
                      notification['id'],
                      notification['elderId'],
                      false,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _handleCaregiverRequest(
                      notification['id'],
                      notification['elderId'],
                      true,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    // For caregiver requests, use a special card with accept/decline buttons
    if (notification['type'] == 'caregiver_request') {
      return _buildCaregiverRequestCard(notification);
    }
    
    // For regular notifications
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
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(notification['elderImage']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          notification['elderName'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: notification['textColor'],
                          ),
                        ),
                        if (notification['elderStatus'] == 'Needs Attention')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Needs Attention',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
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
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
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
                        'Caregiver Dashboard',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black87),
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                ),
              ),
              _buildElderSelector(),
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
                              return _buildNotificationCard(notification);
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
                          _markAllAsRead();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications marked as read'),
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
      bottomNavigationBar: const BottomNav_for_caregivers(currentIndex: 1),
    );
  }
}

