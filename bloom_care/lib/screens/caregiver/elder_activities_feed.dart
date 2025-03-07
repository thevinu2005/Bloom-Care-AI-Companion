import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bloom_care/widgets/navigation_bar_for_caregiver.dart';

class ElderActivityFeed extends StatefulWidget {
  final String? elderId;

  const ElderActivityFeed({Key? key, this.elderId}) : super(key: key);

  @override
  State<ElderActivityFeed> createState() => _ElderActivityFeedState();
}

class _ElderActivityFeedState extends State<ElderActivityFeed> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _elders = [];
  String? _selectedElderId;
  List<Map<String, dynamic>> _activities = [];
  
  @override
  void initState() {
    super.initState();
    _selectedElderId = widget.elderId;
    _loadCaregiverData();
  }
  
  Future<void> _loadCaregiverData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get all elders assigned to this caregiver
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
          'name': elderData['name'] ?? 'Unknown Elder',
          'profileImage': elderData['profileImage'] ?? 'assest/images/default_avatar.png',
        });
      }
      
      setState(() {
        _elders = elders;
        
        // If no elderId provided and we have elders, select the first one
        if (_selectedElderId == null && elders.isNotEmpty) {
          _selectedElderId = elders.first['id'];
        }
        
        _isLoading = false;
      });
      
      // Now load activities for the selected elder
      if (_selectedElderId != null) {
        _loadElderActivities(_selectedElderId!);
      }
    } catch (e) {
      print('Error loading caregiver data: $e');
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
  
  Future<void> _loadElderActivities(String elderId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get notifications about this elder
      final activityQuery = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .where('elderId', isEqualTo: elderId)
          .where('type', isEqualTo: 'elder_activity')
          .orderBy('timestamp', descending: true)
          .get();
      
      final List<Map<String, dynamic>> activities = [];
      
      for (var doc in activityQuery.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        
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
          case 'restaurant':
            icon = Icons.restaurant;
            break;
          case 'sports_esports':
            icon = Icons.sports_esports;
            break;
          case 'event':
            icon = Icons.event;
            break;
          default:
            icon = Icons.notification_important;
        }
        
        activities.add({
          'id': doc.id,
          'elderName': data['elderName'] ?? 'Unknown Elder',
          'elderId': data['elderId'] ?? '',
          'activityType': data['activityType'] ?? 'activity',
          'message': data['message'] ?? '',
          'time': timestamp?.toDate() ?? DateTime.now(),
          'color': color,
          'textColor': textColor,
          'icon': icon,
          'iconColor': iconColor,
          'isRead': data['isRead'] ?? false,
        });
      }
      
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading elder activities: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading activities: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _markActivityAsRead(String activityId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(activityId)
          .update({
        'isRead': true,
      });
      
      setState(() {
        final index = _activities.indexWhere((a) => a['id'] == activityId);
        if (index != -1) {
          _activities[index]['isRead'] = true;
        }
      });
    } catch (e) {
      print('Error marking activity as read: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8FA2E6),
        title: const Text(
          'Elder Activity Feed',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Elder selector
                if (_elders.length > 1) 
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _elders.length,
                      itemBuilder: (context, index) {
                        final elder = _elders[index];
                        final isSelected = elder['id'] == _selectedElderId;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedElderId = elder['id'];
                            });
                            _loadElderActivities(elder['id']);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF8FA2E6) : Colors.transparent,
                                      width: 2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundImage: AssetImage(elder['profileImage']),
                                    child: elder['profileImage'] == 'assest/images/default_avatar.png'
                                        ? Text(
                                            elder['name'].substring(0, 1).toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  elder['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF8FA2E6) : Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                // Activity feed
                Expanded(
                  child: _activities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No activities recorded yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Activities will appear here when the elder adds them',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _activities.length,
                          padding: const EdgeInsets.all(12.0),
                          itemBuilder: (context, index) {
                            final activity = _activities[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              elevation: 2,
                              color: activity['color'],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Mark as read when tapped
                                  if (!activity['isRead']) {
                                    _markActivityAsRead(activity['id']);
                                  }
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
                                          color: activity['iconColor'].withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          activity['icon'],
                                          color: activity['iconColor'],
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getActivityTitle(activity),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: activity['textColor'],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              activity['message'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: activity['textColor'],
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('MMM d, yyyy • h:mm a').format(activity['time']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: activity['textColor'].withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!activity['isRead'])
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
              ],
            ),
      bottomNavigationBar: const BottomNav_for_caregivers(currentIndex: -1),
    );
  }
  
  String _getActivityTitle(Map<String, dynamic> activity) {
    switch (activity['activityType']) {
      case 'meal':
        return 'Meal Activity';
      case 'hobby':
        return 'Hobby Activity';
      case 'appointment':
        return 'Appointment Update';
      default:
        return 'Elder Activity';
    }
  }
}

