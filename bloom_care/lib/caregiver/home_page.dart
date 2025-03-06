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
              const SizedBox(height: 24),

              // Stats Overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("3", "Patients Today"),
                    _buildStatItem("7", "Tasks"),
                    _buildDailyProgress(0.6),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Upcoming Tasks Section
              const Text(
                "Upcoming Tasks",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...upcomingTasks.map((task) => _buildTaskCard(task)),

              const SizedBox(height: 24),

              // Patients Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Patients",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    return _buildPatientCard(patients[index]);
                  },
                ),
              ),

              const SizedBox(height: 24),



            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailsPage(patient: patient),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient photo placeholder
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: primaryColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient["name"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${patient["age"]} yrs • ${patient["condition"]}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgress(double progress) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: accentColor,
          width: 8.0 * progress,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Center(
        child: Text(
          "${(progress * 100).toInt()}%",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    Color cardColor = task["isUrgent"] ? Colors.red[50]! : primaryColor.withOpacity(0.1);
    Color iconColor = task["isUrgent"] ? Colors.red : accentColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cardColor,
          child: Icon(
            Icons.assignment,
            color: iconColor,
          ),
        ),
        title: Text(
          task["title"],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${task["patient"]} • ${task["time"]}"),
        trailing: IconButton(
          icon: Icon(Icons.check_circle_outline, color: accentColor),
          onPressed: () {
            // Mark task as completed
          },
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}