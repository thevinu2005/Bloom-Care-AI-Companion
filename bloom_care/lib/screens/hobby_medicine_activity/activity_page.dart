import 'package:flutter/material.dart';
import 'package:bloom_care/screens/hobby_medicine_activity/medicine_page.dart'; // Import MedicinePage
import 'package:bloom_care/widgets/navigation_bar.dart'; // Import the BottomNav widget
import 'package:bloom_care/screens/hobby_medicine_activity/hobbies_page.dart'; // Import HobbiesPage

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD7E0FA), // Light blue background
      appBar: AppBar(
        backgroundColor: Color(0xFF8FA2E6), // App bar color
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'daily activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        // Settings icon removed
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header with curved bottom
            Container(
              padding: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
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
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
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
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Color(0xFF8FA2E6), width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Color(0xFF8FA2E6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Imsarie Williams',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active Member',
                          style: TextStyle(
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

            // Personal Information section removed

            // Activity Management Section - Made more creative
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
                  Color(0xFF8FA2E6),
                  Color(0xFFB3C1F0),
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
                    Color(0xFF6B84DC),
                    Color(0xFFD7E0FA),
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
                    Color(0xFF5D77D6),
                    Color(0xFFCBD6F9),
                        () {},
                  ),

                  const SizedBox(height: 16),

                  _buildCreativeActivityCard(
                    context,
                    'Daily Activities',
                    'Set up your personalized routine schedule',
                    Icons.event_note,
                    Color(0xFF4A5578),
                    Color(0xFFB3C1F0),
                        () {},
                  ),

                  const SizedBox(height: 20),

                  // Need Assistance section removed
                ],
              ),
            ),
          ],
        ),
      ),
      // Replaced the built-in BottomNavigationBar with the custom BottomNav widget
      bottomNavigationBar: const BottomNav(currentIndex: -1), // Use -1 to indicate no selection
    );
  }

  Widget _buildCreativeSectionHeader(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8FA2E6), Color(0xFF6B84DC)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8FA2E6).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
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
        padding: EdgeInsets.all(20),
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
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: Offset(0, 3),
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
                    style: TextStyle(
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
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 5,
                    offset: Offset(0, 2),
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

