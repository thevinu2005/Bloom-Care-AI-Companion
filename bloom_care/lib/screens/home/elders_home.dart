import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'package:bloom_care/screens/emotion_check/emotion_check.dart';
import 'package:bloom_care/screens/hobby_medicine_activity/activity_page.dart';
import 'dart:math';
import 'package:bloom_care/screens/mental_health_check_ins/mental_health_check_ins.dart';


class BloomCareHomePage extends StatefulWidget {
  const BloomCareHomePage({super.key});

  @override
  State<BloomCareHomePage> createState() => _BloomCareHomePageState();
}

class _BloomCareHomePageState extends State<BloomCareHomePage> {
  String? selectedMood;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  Map<String, dynamic>? _userData;
  late Stream<DocumentSnapshot> _userStream;
  late Stream<String> _timeStream;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _setupStreams();
    _startTimeStream();
  }

  void _setupStreams() {
    final user = _auth.currentUser;
    if (user != null) {
      _userStream = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots();

      // Load initial mood
      _loadCurrentMood();
    }
  }

  Stream<String> _getTimeStream() {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return DateFormat('MMMM d, yyyy').format(DateTime.now());
    });
  }

  void _startTimeStream() {
    _timeStream = _getTimeStream();
  }

  Future<void> _loadCurrentMood() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final latestMood = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('emotions')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (latestMood.docs.isNotEmpty) {
          setState(() {
            selectedMood = latestMood.docs.first.data()['emotion'];
          });
        }
      }
    } catch (e) {
      print('Error loading mood: $e');
    }
  }

  Future<void> _saveMoodToFirebase(String mood) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('emotions')
            .add({
          'emotion': mood,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('Mood saved successfully');
      }
    } catch (e) {
      print('Error saving mood: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving mood: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7E0FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8FA2E6),
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error loading user data');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final name = userData?['name'] ?? 'User';

            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Text(
                    _getInitials(name),
                    style: const TextStyle(
                      color: Color(0xFF8FA2E6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back,',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/eldernotification');
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          if (userData == null) {
            return const Center(child: Text('No user data found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'How are you today?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A5578),
                        ),
                      ),
                      StreamBuilder<String>(
                        stream: _timeStream,
                        builder: (context, snapshot) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              snapshot.data ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B84DC),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Mood Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8FA2E6).withOpacity(0.15),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.mood, color: Color(0xFF6B84DC), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'How is your mood today?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A5578),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildMoodButton('Happy', '😊'),
                          _buildMoodButton('Relaxed', '😌'),
                          _buildMoodButton('Tired', '😫'),
                          _buildMoodButton('Stressed', '😰'),
                          _buildMoodButton('Anxious', '😨'),
                          _buildMoodButton('Lonely', '🥺'),
                        ],
                      ),
                      if (selectedMood != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7E0FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'You selected: $selectedMood',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4A5578),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5578),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Daily Activities',
                        Icons.directions_run,
                        const Color(0xFF8FA2E6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard2(
                        'Healthy check-in',
                        Icons.health_and_safety,
                        const Color(0xFF8FA2E6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // AI Assistant Button
                _buildAIAssistantBar(),

                const SizedBox(height: 24),

                // Profile Section
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8FA2E6).withOpacity(0.15),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person, color: Color(0xFF6B84DC), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Your Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A5578),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD7E0FA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileInfoRow('Name:', userData['name'] ?? 'Not set'),
                            const Divider(height: 24, color: Color(0xFFD7E0FA)),
                            _buildProfileInfoRow(
                              'Age:',
                              _calculateAge(userData['dateOfBirth']),
                            ),
                            const Divider(height: 24, color: Color(0xFFD7E0FA)),
                            _buildProfileInfoRow(
                              'Caregiver:',
                              userData['caregiverName'] ?? 'Not assigned',
                            ),
                            const Divider(height: 24, color: Color(0xFFD7E0FA)),
                            _buildProfileInfoRow(
                              'Next Appointment:',
                              userData['nextAppointment'] ?? 'Not scheduled',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  String _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 'Age not set';
    
    try {
      final parts = dateOfBirth.split('/');
      if (parts.length != 3) return 'Invalid date';
      
      final birthDate = DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
      
      final age = DateTime.now().difference(birthDate).inDays ~/ 365;
      return '$age years';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF6B84DC),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4A5578),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodButton(String mood, String emoji) {
    final isSelected = selectedMood == mood;
    return InkWell(
      onTap: () async {
        setState(() {
          selectedMood = mood;
        });
        await _saveMoodToFirebase(mood);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB3C1F0) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B84DC)
                : const Color(0xFFD7E0FA),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8FA2E6).withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              mood,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF4A5578)
                    : const Color(0xFF6B84DC),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ActivityPage()),
         );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF4A5578),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to view',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildActionCard2(String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MentalHealthStartPage()),
         );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF4A5578),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to view',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
// second botton card to navigate to daily reminders
  Widget _buildAIAssistantBar() {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const EmotionCheck()),
         );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B84DC), Color(0xFF8FA2E6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B84DC).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Virtual Companion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ask questions or get help with daily tasks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

