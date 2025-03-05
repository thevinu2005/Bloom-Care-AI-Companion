import 'package:flutter/material.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmergencyPage2 extends StatefulWidget {
  const EmergencyPage2({Key? key}) : super(key: key);

  @override
  State<EmergencyPage2> createState() => _EmergencyPage2State();
}

class _EmergencyPage2State extends State<EmergencyPage2> {
  bool _isSendingNotification = false;
  bool _notificationSent = false;
  String _userName = 'User';
  String _userType = '';
  bool _isLoadingData = true;

  // Add caregiver information variables
  String _caregiverName = 'Not Assigned';
  String _caregiverPhone = '';
  String? _caregiverImageUrl;
  String _caregiverRelationship = 'Caregiver';
  bool _hasCaregiverAssigned = false;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Update the _loadUserData method to also fetch caregiver details
  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingData = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          final data = userData.data()!;
          setState(() {
            _userName = data['name'] ?? 'User';
            _userType = data['userType'] ?? '';
            
            // Get assigned caregiver ID
            final assignedCaregiverId = data['assignedCaregiver'] as String?;
            _hasCaregiverAssigned = assignedCaregiverId != null && assignedCaregiverId.isNotEmpty;
            
            if (_hasCaregiverAssigned && assignedCaregiverId != null) {
              // Fetch caregiver details
              _loadCaregiverDetails(assignedCaregiverId);
            } else {
              _isLoadingData = false;
            }
          });
        } else {
          setState(() {
            _isLoadingData = false;
          });
        }
      } else {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // Add a new method to load caregiver details
  Future<void> _loadCaregiverDetails(String caregiverId) async {
    try {
      final caregiverDoc = await _firestore
          .collection('users')
          .doc(caregiverId)
          .get();
          
      if (caregiverDoc.exists) {
        final caregiverData = caregiverDoc.data()!;
        setState(() {
          _caregiverName = caregiverData['name'] ?? 'Unknown Caregiver';
          _caregiverPhone = caregiverData['phone'] ?? 'No phone number';
          _caregiverImageUrl = caregiverData['profileImage'];
          _caregiverRelationship = caregiverData['familyMemberType'] ?? 'Caregiver';
          _isLoadingData = false;
        });
      } else {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading caregiver details: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // Update the _sendEmergencyNotification method to remove location-related code
  Future<void> _sendEmergencyNotification() async {
    if (_isSendingNotification || _notificationSent) return;
    
    setState(() {
      _isSendingNotification = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }
      
      final userData = userDoc.data()!;
      final String assignedCaregiverId = userData['assignedCaregiver'] as String? ?? '';
      
      if (assignedCaregiverId.isEmpty) {
        _showNoAssignedCaregiverDialog();
        setState(() {
          _isSendingNotification = false;
        });
        return;
      }
      
      // Get current time formatted
      final now = DateTime.now();
      final formattedTime = DateFormat('h:mm a').format(now);
      
      // Get caregiver data
      final caregiverDoc = await _firestore.collection('users').doc(assignedCaregiverId).get();
      final caregiverName = caregiverDoc.data()?['name'] ?? 'Your Caregiver';
      
      // Create emergency notification with real-time details
      final notificationData = {
        'type': 'emergency',
        'emergencyType': 'Emergency Button Press', // Actual emergency type
        'title': 'Emergency Alert',
        'message': '${userData['name']} has triggered an emergency alert and needs immediate assistance!',
        'elderId': user.uid,
        'elderName': userData['name'] ?? 'Elder',
        'elderImage': userData['profileImage'] ?? 'assets/default_avatar.png',
        'elderStatus': 'Immediate Attention Required',
        'timestamp': FieldValue.serverTimestamp(), // Use Firestore server timestamp
        'formattedTime': formattedTime, // Backup formatted time
        'isRead': false,
        'color': const Color(0xFFF8D7DA).value,
        'textColor': const Color(0xFF721C24).value,
        'icon': 'warning_amber_rounded',
        'iconColor': Colors.red.value,
        'priority': 'high',
      };
      
      // Send notification to caregiver
      await _firestore
          .collection('users')
          .doc(assignedCaregiverId)
          .collection('notifications')
          .add(notificationData);
      
      // Also record this emergency in the user's history
      final historyData = {
        'timestamp': FieldValue.serverTimestamp(),
        'formattedTime': formattedTime,
        'status': 'active',
        'caregiverId': assignedCaregiverId,
        'caregiverName': caregiverName,
        'emergencyType': 'Emergency Button Press',
        'resolved': false,
      };
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_history')
          .add(historyData);
      
      // Update user's emergency status
      final updateData = {
        'emergency': true,
        'lastEmergencyTime': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(updateData);
      
      setState(() {
        _isSendingNotification = false;
        _notificationSent = true;
      });
      
      _showNotificationSentDialog(caregiverName);
      
    } catch (e) {
      print('Error sending emergency notification: $e');
      setState(() {
        _isSendingNotification = false;
      });
      
      ScaffoldMessenger.of((context)).showSnackBar(
        SnackBar(
          content: Text('Error sending emergency notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showNoAssignedCaregiverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Caregiver Assigned'),
          content: const Text(
            'You don\'t have an assigned caregiver yet. Please add a caregiver from your profile settings first.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void _showNotificationSentDialog(String caregiverName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Emergency Alert Sent'),
          content: Text(
            'Your emergency alert has been sent to $caregiverName. They will be notified immediately.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: const Color(0xFFE85D5D),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Simplified Profile Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Emergency Contact',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoadingData
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : _hasCaregiverAssigned
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[300],
                                        image: _caregiverImageUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(_caregiverImageUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _caregiverImageUrl == null
                                          ? Center(
                                              child: Text(
                                                _caregiverName.isNotEmpty
                                                    ? _caregiverName[0].toUpperCase()
                                                    : 'C',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _caregiverName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'No caregiver assigned',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ],
                ),
              ),
              
              // Main Content with white background
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Having an Emergency',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (_notificationSent)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Emergency notification sent to your caregiver',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      
                      // Simple Emergency Button
                      ElevatedButton.icon(
                        onPressed: _isSendingNotification || !_hasCaregiverAssigned 
                            ? null 
                            : _sendEmergencyNotification,
                        icon: _isSendingNotification
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.warning_amber_rounded),
                        label: Text(
                          _isSendingNotification
                              ? 'Sending...'
                              : 'Send Emergency Alert',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        !_hasCaregiverAssigned
                            ? 'Please assign a caregiver first'
                            : _isSendingNotification 
                                ? 'Sending emergency notification...'
                                : _notificationSent 
                                    ? 'Tap again to send another notification'
                                    : 'Tap to send emergency notification',
                        style: TextStyle(
                          color: !_hasCaregiverAssigned 
                              ? Colors.grey 
                              : _isSendingNotification 
                                  ? Colors.orange 
                                  : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      
                      // Warning stripes container
                      Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.yellow.shade600,
                              Colors.black,
                            ],
                            stops: const [0.5, 0.5],
                            tileMode: TileMode.repeated,
                            transform: GradientRotation(45 * 3.14159 / 180), // 45 degrees in radians
                          ),
                        ),
                      ),
                      
                      // Cancel Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40, top: 20),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'cancel',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 1,
      ),
    );
  }
}

