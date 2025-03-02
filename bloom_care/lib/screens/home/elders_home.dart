import 'package:flutter/material.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';

class BloomCareHomePage extends StatefulWidget {
  const BloomCareHomePage({super.key});

  @override
  State<BloomCareHomePage> createState() => _BloomCareHomePageState();
}

class _BloomCareHomePageState extends State<BloomCareHomePage> {
  String? selectedMood;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD7E0FA), // Light blue background
      appBar: AppBar(
        backgroundColor: Color(0xFF8FA2E6), // App bar color
        elevation: 0, // Remove shadow for a cleaner look
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: Text(
                "IW",
                style: TextStyle(
                  color: Color(0xFF8FA2E6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Welcome Back,',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                ),
                Text(
                  'Imsarie Williams',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting and Date
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'How are you today?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5578),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'March 1, 2025',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B84DC),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mood Section with larger buttons and better spacing
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8FA2E6).withOpacity(0.15),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFFD7E0FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'You selected: $selectedMood',
                        style: TextStyle(
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

            // Quick Actions with improved layout
            Text(
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
                Expanded(child: _buildActionCard('Daily Activities', Icons.directions_run, Color(0xFF8FA2E6))),
                SizedBox(width: 16),
                Expanded(child: _buildActionCard('Daily reminders',Icons.event_note, Color(0xFF8FA2E6))),
              ],
            ),

            const SizedBox(height: 24),

            // AI Assistant Button with improved design
            _buildAIAssistantBar(),

            const SizedBox(height: 24),

            // Your Profile Section with improved layout
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8FA2E6).withOpacity(0.15),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                      color: Color(0xFFF5F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFD7E0FA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileInfoRow('Name:', 'Imsarie Williams'),
                        Divider(height: 24, color: Color(0xFFD7E0FA)),
                        _buildProfileInfoRow('Age:', '68 years'),
                        Divider(height: 24, color: Color(0xFFD7E0FA)),
                        _buildProfileInfoRow('Caregiver:', 'Dr. Michael Chen'),
                        Divider(height: 24, color: Color(0xFFD7E0FA)),
                        _buildProfileInfoRow('Next Appointment:', 'March 5, 2025'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.edit, size: 18),
                      label: Text('Update Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6B84DC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B84DC),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
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
      onTap: () {
        setState(() {
          selectedMood = mood;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFB3C1F0) : Colors.white,
          border: Border.all(
            color: isSelected ? Color(0xFF6B84DC) : Color(0xFFD7E0FA),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Color(0xFF8FA2E6).withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 4,
              offset: Offset(0, 2),
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
                color: isSelected ? Color(0xFF4A5578) : Color(0xFF6B84DC),
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
          if (title == 'Daily Activities') {
            Navigator.pushNamed(context, '/activity');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF4A5578),
                ),
              ),
              SizedBox(height: 4),
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

  Widget _buildAIAssistantBar() {
    return InkWell(
      onTap: () {
        // Add AI assistant navigation
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6B84DC), Color(0xFF8FA2E6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6B84DC).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
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
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}