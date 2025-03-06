import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'bottom_nav.dart';
import 'patient_details_page.dart';
import 'caregiver_profile_page.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({Key? key}) : super(key: key);

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  final String caregiverName = "Sarah";

  // Made patients list mutable to allow adding new patients
  List<Map<String, dynamic>> patients = [
    {
      "name": "John Smith",
      "age": 72,
      "condition": "Post-Surgery Recovery",
      "gender": "Male",
      "dateOfBirth": "1951-05-15",
      "image": "assets/patient1.png",
    },
    {
      "name": "Mary Johnson",
      "age": 65,
      "condition": "Chronic Pain",
      "gender": "Female",
      "dateOfBirth": "1958-09-22",
      "image": "assets/patient2.png",
    },
    {
      "name": "Robert Davis",
      "age": 78,
      "condition": "Diabetes Management",
      "gender": "Male",
      "dateOfBirth": "1945-11-10",
      "image": "assets/patient3.png",
    },
  ];

  final List<Map<String, dynamic>> upcomingTasks = [
    {
      "title": "Medication Reminder",
      "patient": "John Smith",
      "time": "10:30 AM",
      "isUrgent": true,
    },
    {
      "title": "Physical Therapy",
      "patient": "Mary Johnson",
      "time": "1:15 PM",
      "isUrgent": false,
    },
    {
      "title": "Vital Signs Check",
      "patient": "Robert Davis",
      "time": "3:00 PM",
      "isUrgent": false,
    },
  ];

  // Updated color scheme based on the image
  final Color primaryColor = const Color(0xFF8B9CE0); // Light purple/blue
  final Color backgroundColor = const Color(0xFFE6ECFF); // Very light blue
  final Color accentColor = const Color(0xFF5B6EC7); // Deeper purple/blue

  @override
  Widget build(BuildContext context) {
    // Get current date
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormat.format(now);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Caregiver Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CaregiverProfilePage()),
              );
            },
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting and Date
              Text(
                "Hello, $caregiverName!",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),