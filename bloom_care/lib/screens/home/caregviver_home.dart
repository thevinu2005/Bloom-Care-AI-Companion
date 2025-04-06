import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bloom_care/widgets/navigation_bar_for_caregiver.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:bloom_care/screens/caregiver/caregiver_dashboard.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({super.key});

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  bool _isLoading = true;
  String _caregiverName = 'Caregiver';
  String _caregiverEmail = '';
  String _caregiverProfileImage = 'assets/default_avatar.png';
  List<Map<String, dynamic>> _assignedElders = [];
  int _unreadNotifications = 0;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream subscriptions for real-time updates
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, StreamSubscription> _moodSubscriptions = {};
  final Map<String, StreamSubscription> _emergencySubscriptions = {};

  @override
  void initState() {
    super.initState();
    _loadCaregiverData();
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions when widget is disposed
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    
    // Cancel all mood subscriptions
    _moodSubscriptions.forEach((_, subscription) {
      subscription.cancel();
    });
    
    // Cancel all emergency subscriptions
    _emergencySubscriptions.forEach((_, subscription) {
      subscription.cancel();
    });
    
    super.dispose();
  }

  Future<void> _loadCaregiverData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get caregiver's data
        final caregiverDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (caregiverDoc.exists) {
          final caregiverData = caregiverDoc.data() ?? {};
          
          setState(() {
            _caregiverName = caregiverData['name'] ?? 'Caregiver';
            _caregiverEmail = caregiverData['email'] ?? user.email ?? '';
            _caregiverProfileImage = caregiverData['profileImage'] ?? 'assets/default_avatar.png';
          });

          // Set up real-time listener for unread notifications
          final notificationsStream = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots();
              
          final notificationSubscription = notificationsStream.listen((snapshot) {
            setState(() {
              _unreadNotifications = snapshot.docs.length;
            });
          });
          
          _subscriptions.add(notificationSubscription);

          // Set up real-time listener for assigned elders
          final assignedEldersStream = _firestore
              .collection('users')
              .where('assignedCaregiver', isEqualTo: user.uid)
              .where('userType', isEqualTo: 'elder')
              .snapshots();
              
          final eldersSubscription = assignedEldersStream.listen((snapshot) async {
            final List<Map<String, dynamic>> elders = [];
            
            // Cancel existing mood subscriptions for elders that might have been removed
            final currentElderIds = snapshot.docs.map((doc) => doc.id).toSet();
            _moodSubscriptions.keys
                .where((id) => !currentElderIds.contains(id))
                .toList()
                .forEach((id) {
                  _moodSubscriptions[id]?.cancel();
                  _moodSubscriptions.remove(id);
                });
            
            // Cancel existing emergency subscriptions for elders that might have been removed
            _emergencySubscriptions.keys
                .where((id) => !currentElderIds.contains(id))
                .toList()
                .forEach((id) {
                  _emergencySubscriptions[id]?.cancel();
                  _emergencySubscriptions.remove(id);
                });
            
            for (var elderDoc in snapshot.docs) {
              final elderData = elderDoc.data();
              final dateOfBirth = elderData['dateOfBirth'] as String?;
              int age = 0;
              
              if (dateOfBirth != null) {
                final parts = dateOfBirth.split('/');
                if (parts.length == 3) {
                  final birthDate = DateTime(
                    int.parse(parts[2]), // year
                    int.parse(parts[1]), // month
                    int.parse(parts[0]), // day
                  );
                  age = DateTime.now().difference(birthDate).inDays ~/ 365;
                }
              }

              // Get initial mood data
              final latestEmotionQuery = await _firestore
                  .collection('users')
                  .doc(elderDoc.id)
                  .collection('emotions')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();

              String mood = 'Unknown';
              if (latestEmotionQuery.docs.isNotEmpty) {
                mood = latestEmotionQuery.docs.first.data()['emotion'] ?? 'Unknown';
              }

              final elderInfo = {
                'id': elderDoc.id,
                'name': elderData['name'] ?? 'Unknown',
                'age': age,
                'mood': mood,
                'emergency': elderData['emergency'] ?? false,
                'profileImage': elderData['profileImage'] ?? 'assets/default_avatar.png',
                'address': elderData['address'] ?? 'No address provided',
                'phone': elderData['phone'] ?? 'No phone provided',
              };
              
              elders.add(elderInfo);
              
              // Set up real-time listener for mood updates for this elder
              _setupMoodListener(elderDoc.id);
              
              // Set up real-time listener for emergency status updates
              _setupEmergencyListener(elderDoc.id);
            }

            setState(() {
              _assignedElders = elders;
              _isLoading = false;
            });
          });
          
          _subscriptions.add(eldersSubscription);
        } else {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Caregiver profile not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
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

  void _setupMoodListener(String elderId) {
    // Cancel existing subscription if it exists
    _moodSubscriptions[elderId]?.cancel();
    
    // Create new subscription for this elder's emotions
    final moodStream = _firestore
        .collection('users')
        .doc(elderId)
        .collection('emotions')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
        
    final subscription = moodStream.listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final newMood = snapshot.docs.first.data()['emotion'] ?? 'Unknown';
        
        setState(() {
          // Find and update the elder's mood in the list
          for (int i = 0; i < _assignedElders.length; i++) {
            if (_assignedElders[i]['id'] == elderId) {
              _assignedElders[i]['mood'] = newMood;
              break;
            }
          }
        });
      }
    });
    
    _moodSubscriptions[elderId] = subscription;
  }

  // Add a new method to listen for emergency status changes
  void _setupEmergencyListener(String elderId) {
    // Cancel existing subscription if it exists
    _emergencySubscriptions[elderId]?.cancel();
    
    // Create new subscription for this elder's document to monitor emergency status
    final emergencyStream = _firestore
        .collection('users')
        .doc(elderId)
        .snapshots();
        
    final subscription = emergencyStream.listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final bool isEmergency = data['emergency'] ?? false;
          print('Emergency status changed for elder $elderId: $isEmergency');
          
          setState(() {
            // Find and update the elder's emergency status in the list
            for (int i = 0; i < _assignedElders.length; i++) {
              if (_assignedElders[i]['id'] == elderId) {
                _assignedElders[i]['emergency'] = isEmergency;
                break;
              }
            }
          });
        }
      }
    });
    
    _emergencySubscriptions[elderId] = subscription;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      // Get first letter of first name and first letter of last name
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (name.length > 1) {
      // If only one name, get first two letters
      return name.substring(0, 2).toUpperCase();
    } else {
      // If name is just one character
      return name.toUpperCase();
    }
  }

  // Method to reset emergency status when clicking on an elder's profile
  Future<void> _resetEmergencyStatus(String elderId) async {
    try {
      print('Resetting emergency status for elder: $elderId');
      await _firestore.collection('users').doc(elderId).update({
        'emergency': false,
      });
      
      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency status cleared'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error resetting emergency status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing emergency status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewElderDetails(Map<String, dynamic> elder) {
    // Check if this elder is in emergency mode
    final bool isEmergency = elder['emergency'] == true;
    
    // If in emergency mode, reset it first
    if (isEmergency) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Emergency Alert'),
            content: Text('${elder['name']} is in emergency mode. Do you want to clear the emergency status?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _resetEmergencyStatus(elder['id']); // Reset emergency status
                  
                  // Then navigate to elder details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ElderDetailsPage(elder: elder),
                    ),
                  );
                },
                child: const Text('Yes'),
              ),
            ],
          );
        },
      );
    } else {
      // If not in emergency mode, just navigate to elder details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ElderDetailsPage(elder: elder),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B9FE8),
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/caregivernotification');
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B9FE8),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCaregiverData,
              color: const Color(0xFF8B9FE8),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section with gradient background
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B9FE8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFFEEF1FF),
                                backgroundImage: _caregiverProfileImage != 'assets/default_avatar.png' 
                                    ? AssetImage(_caregiverProfileImage)
                                    : null,
                                child: _caregiverProfileImage == 'assets/default_avatar.png'
                                    ? Text(
                                        _getInitials(_caregiverName),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF8B9FE8),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, $_caregiverName!',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(now),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (_caregiverEmail.isNotEmpty)
                                      Text(
                                        _caregiverEmail,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stats section - Only showing patients count
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: _buildStatCard(
                        'Elders',
                        _assignedElders.length.toString(),
                        Icons.people_outline,
                      ),
                    ),

                    // Your Patients section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Your Elders',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_assignedElders.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    // Navigate to all patients page
                                  },
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(
                                      color: Color(0xFF8B9FE8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _assignedElders.isEmpty
                              ? _buildEmptyState(
                                  icon: Icons.people_outline,
                                  title: 'No elders assigned yet',
                                  subtitle: 'Elders will appear here once assigned to you',
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _assignedElders.length,
                                  itemBuilder: (context, index) {
                                    final elder = _assignedElders[index];
                                    return GestureDetector(
                                      onTap: () => _viewElderDetails(elder),
                                      child: ElderProfileCard(
                                        elder: elder,
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNav_for_caregivers(currentIndex: 0),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8B9FE8),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B9FE8),
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ElderProfileCard extends StatelessWidget {
  final Map<String, dynamic> elder;

  const ElderProfileCard({
    super.key,
    required this.elder,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      // Get first letter of first name and first letter of last name
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (name.length > 1) {
      // If only one name, get first two letters
      return name.substring(0, 2).toUpperCase();
    } else {
      // If name is just one character
      return name.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if emergency is true - ensure it's a boolean
    final bool isEmergency = elder['emergency'] == true;
    
    // Debug print to verify the emergency status
    print('Building elder card for ${elder['name']}, Emergency status: $isEmergency');
    
    // Get the mood emoji based on the mood
    String moodEmoji = _getMoodEmoji(elder['mood']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.red.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isEmergency 
            ? Border.all(color: Colors.red.shade300, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isEmergency 
                      ? Colors.red.shade50 
                      : const Color(0xFFEEF1FF),
                  backgroundImage: elder['profileImage'] != 'assets/default_avatar.png'
                      ? AssetImage(elder['profileImage'])
                      : null,
                  child: elder['profileImage'] == 'assets/default_avatar.png'
                      ? Text(
                          _getInitials(elder['name']),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isEmergency 
                                ? Colors.red.shade700 
                                : const Color(0xFF8B9FE8),
                          ),
                        )
                      : null,
                ),
                // Mood indicator in the bottom right of the avatar
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEmergency ? Colors.red.shade100 : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      moodEmoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    elder['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEmergency ? Colors.red.shade700 : Colors.black87,
                    ),
                  ),
                  Text(
                    '${elder['age']} years',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Current mood: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        elder['mood'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getMoodColor(elder['mood']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isEmergency)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Emergency',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (!isEmergency)
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'relaxed':
      case 'calm':
        return Colors.blue;
      case 'tired':
      case 'sleepy':
        return Colors.orange;
      case 'stressed':
      case 'anxious':
      case 'sad':
        return Colors.red;
      case 'lonely':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'relaxed':
      case 'calm':
        return '😌';
      case 'tired':
      case 'sleepy':
        return '😴';
      case 'stressed':
      case 'anxious':
        return '😰';
      case 'sad':
        return '😢';
      case 'lonely':
        return '😔';
      default:
        return '😐';
    }
  }
}

