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