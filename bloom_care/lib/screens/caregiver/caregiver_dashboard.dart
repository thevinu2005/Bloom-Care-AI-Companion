import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:bloom_care/screens/caregiver/medication_page.dart';

class ElderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> elder;

  const ElderDetailsPage({Key? key, required this.elder}) : super(key: key);

  @override
  _ElderDetailsPageState createState() => _ElderDetailsPageState();
}

class _ElderDetailsPageState extends State<ElderDetailsPage> {
  late Map<String, dynamic> _elder;
  bool _isLoading = false;
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _activities = [];
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _elder = widget.elder;
    _loadElderDetails();
  }

  // Update the _loadElderDetails method to properly fetch and display daily activities
  Future<void> _loadElderDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load medications
      final medicationsSnapshot = await _firestore
          .collection('users')
          .doc(_elder['id'])
          .collection('medicines')
          .limit(5)
          .get();
          
      final meds = medicationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown medication',
          'dosage': data['dosage'] ?? '',
          'schedule': data['schedule'] ?? [],
          'instructions': data['instructions'] ?? '',
        };
      }).toList();
      
      // Load activities - try both collection names that might be used
      QuerySnapshot activitiesSnapshot;
      try {
        activitiesSnapshot = await _firestore
            .collection('users')
            .doc(_elder['id'])
            .collection('dailyActivities')
            .limit(5)
            .get();
            
        if (activitiesSnapshot.docs.isEmpty) {
          // Try alternative collection name
          activitiesSnapshot = await _firestore
              .collection('users')
              .doc(_elder['id'])
              .collection('daily_activities')
              .limit(5)
              .get();
        }
      } catch (e) {
        print('Error loading dailyActivities, trying hobby_times: $e');
        // Try hobby_times collection as fallback
        activitiesSnapshot = await _firestore
            .collection('users')
            .doc(_elder['id'])
            .collection('hobby_times')
            .limit(5)
            .get();
      }
          
      final activities = activitiesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? data['activity'] ?? 'Unknown activity',
          'time': data['time'] ?? '',
          'description': data['description'] ?? data['duration'] ?? '',
          'category': data['category'] ?? 'Other',
        };
      }).toList();
      
      // If no activities found, try to load from hobbies collection
      if (activities.isEmpty) {
        final hobbiesSnapshot = await _firestore
            .collection('users')
            .doc(_elder['id'])
            .collection('hobbies')
            .limit(5)
            .get();
            
        hobbiesSnapshot.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          activities.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown hobby',
            'time': data['lastDone'] ?? '',
            'description': data['frequency'] ?? '',
            'category': data['category'] ?? 'Hobby',
          });
        });
      }
      
      // Debug print
      print('Loaded ${activities.length} activities and ${meds.length} medications');
      
      setState(() {
        _medications = meds;
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading elder details: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (name.length > 1) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return name.toUpperCase();
    }
  }

  // Update the Activities Card to better display activities or show a message when none are found
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_elder['name']} - Details'),
        backgroundColor: const Color(0xFF8B9FE8),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadElderDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B9FE8),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFEEF1FF),
                          backgroundImage: _elder['profileImage'] != 'assets/default_avatar.png'
                              ? AssetImage(_elder['profileImage'])
                              : null,
                          child: _elder['profileImage'] == 'assets/default_avatar.png'
                              ? Text(
                                  _getInitials(_elder['name']),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B9FE8),
                                  ),
                                )
                              : null,
                        ),
                        // Mood indicator
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getMoodEmoji(_elder['mood']),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Current mood
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getMoodColor(_elder['mood']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Current mood: ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            _elder['mood'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getMoodColor(_elder['mood']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information Card
                  _buildDetailsCard(
                    title: 'Personal Information',
                    children: [
                      _buildDetailRow('Full Name', _elder['name']),
                      _buildDetailRow('Age', '${_elder['age']} years'),
                      _buildDetailRow('Phone', _elder['phone']),
                      _buildDetailRow('Address', _elder['address']),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Medications Card
                  _buildDetailsCard(
                    title: 'Medications',
                    children: _medications.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  'No medications found',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ]
                        : _medications.map((med) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                med['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${med['dosage']} - ${med['instructions']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.medication,
                                color: Color(0xFF8B9FE8),
                              ),
                            );
                          }).toList(),
                    actionText: 'View All Medications',
                    onActionPressed: () {
                      print('Navigating to medications page for elder: ${_elder['name']} (ID: ${_elder['id']})');
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MedicinePage(elderId: _elder['id'])),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Activities Card
                  _buildDetailsCard(
                    title: 'Daily Activities',
                    children: _activities.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  'No activities found',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ]
                        : _activities.map((activity) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                activity['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${activity['time']} - ${activity['category']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.directions_walk,
                                color: Color(0xFF8B9FE8),
                              ),
                            );
                          }).toList(),
                    actionText: 'View All Activities',
                    onActionPressed: () {
                      // Navigate to activities page
                    },
                  ),

                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActionsSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required List<Widget> children,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B6EC7),
                  ),
                ),
                if (actionText != null && onActionPressed != null)
                  TextButton(
                    onPressed: onActionPressed,
                    child: Text(
                      actionText,
                      style: const TextStyle(
                        color: Color(0xFF8B9FE8),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B6EC7),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: Icons.medication,
                  label: 'Medications',
                  onTap: () {
                    print('Navigating to medications page for elder: ${_elder['name']} (ID: ${_elder['id']})');
                    // Make sure we're passing the elder ID correctly
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MedicinePage(elderId: _elder['id'])),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.directions_walk,
                  label: 'Activities',
                  onTap: () {
                    // Navigate to activities page
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: const Color(0xFF5B6EC7),
            size: 28,
          ),
          onPressed: onTap,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
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

