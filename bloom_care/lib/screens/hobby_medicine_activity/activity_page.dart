import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medicine_page.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'hobbies_page.dart';
import 'daily_activities_page.dart';
import 'package:bloom_care/screens/caregiver/add_caregiver.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String _userName = 'User';
  String? _profileImageUrl;
  String _userStatus = 'Active Member';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user data from Firestore
      final userData = await _firestore.collection('users').doc(user.uid).get();
      
      if (userData.exists) {
        final data = userData.data()!;
        
        setState(() {
          _userName = data['name'] ?? 'User';
          _profileImageUrl = data['profileImage'];
          
          // Optional: Get user status if available
          if (data.containsKey('status')) {
            _userStatus = data['status'];
          }
          
          _isLoading = false;
        });
      } else {
        // If user document doesn't exist, use data from Firebase Auth
        setState(() {
          _userName = user.displayName ?? 'User';
          _profileImageUrl = user.photoURL;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7E0FA), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF8FA2E6), // App bar color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/'),
        ),
        title: const Text(
          'daily activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header with curved bottom
                  Container(
                    padding: const EdgeInsets.only(bottom: 30),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8FA2E6),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 50,
                                          backgroundImage: NetworkImage(_profileImageUrl!),
                                        )
                                      : const CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Color(0xFF8FA2E6),
                                          ),
                                        ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF8FA2E6), width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Color(0xFF8FA2E6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _userStatus,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Activity Management Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCreativeSectionHeader('Activity Management', Icons.directions_run),
                        const SizedBox(height: 20),

                        // Main Activity Cards with more creative design
                        _buildCreativeActivityCard(
                          context,
                          'Hobbies & Interests',
                          'Explore and manage your favorite activities',
                          Icons.sports_esports,
                          const Color(0xFF8FA2E6),
                          const Color(0xFFB3C1F0),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HobbiesPage()),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildCreativeActivityCard(
                          context,
                          'Medication',
                          'Track your medicines & schedule with reminders',
                          Icons.medical_services,
                          const Color(0xFF6B84DC),
                          const Color(0xFFD7E0FA),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MedicinePage()),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildCreativeActivityCard(
                          context,
                          'Caregiver Assignment',
                          'Connect and manage your care providers',
                          Icons.people_alt_outlined,
                          const Color(0xFF5D77D6),
                          const Color(0xFFCBD6F9),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddCaregiverScreen()),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildCreativeActivityCard(
                          context,
                          'Daily Activities',
                          'Set up your personalized routine schedule',
                          Icons.event_note,
                          const Color(0xFF4A5578),
                          const Color(0xFFB3C1F0),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DailyActivitiesPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: -1), // Use -1 to indicate no selection
    );
  }

  Widget _buildCreativeSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8FA2E6), Color(0xFF6B84DC)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8FA2E6).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeActivityCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color primaryColor,
      Color secondaryColor,
      VoidCallback onTap
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, secondaryColor.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A5578),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

