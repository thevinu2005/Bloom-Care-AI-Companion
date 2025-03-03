import 'package:flutter/material.dart';
import 'bottom_nav.dart';

// Define a simple Elder model class
class Elder {
  String name;
  int age;
  DateTime dateOfBirth;
  String gender;
  String roomNumber;
  String bloodType;
  List<String> allergies;
  List<String> medications;
  List<String> medicalConditions;
  EmergencyContact emergencyContact;
  String? profileImagePath;
  List<RecentActivity> recentActivities; // Added this field

  Elder({
    required this.name,
    required this.age,
    required this.dateOfBirth,
    required this.gender,
    required this.roomNumber,
    required this.bloodType,
    required this.allergies,
    required this.medications,
    required this.medicalConditions,
    required this.emergencyContact,
    this.profileImagePath,
    this.recentActivities = const [], // Default to empty list
  });
}

// Define EmergencyContact class
class EmergencyContact {
  String name;
  String relationship;
  String phone;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
  });
}

// Simple activity class to replace the ActivityType enum
class RecentActivity {
  final String type;
  final String description;
  final DateTime timestamp;
  final String? performedBy;

  RecentActivity({
    required this.type,
    required this.description,
    required this.timestamp,
    this.performedBy,
  });
}

class ElderCareProfilePage extends StatefulWidget {
  final Elder elder;

  const ElderCareProfilePage({Key? key, required this.elder}) : super(key: key);

  @override
  State<ElderCareProfilePage> createState() => _ElderCareProfilePageState();
}

class _ElderCareProfilePageState extends State<ElderCareProfilePage> {
  late Elder _elder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _elder = widget.elder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_elder.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  shadows: [
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.black45,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB3C1F0), Color(0xFF6B84DC)],
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: _elder.profileImagePath != null
                          ? Image.asset(
                        _elder.profileImagePath!,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      )
                          : const Icon(
                        Icons.person,
                        size: 80,
                        color: Color(0xFF6B84DC),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoCard(),
                  const SizedBox(height: 16),
                  _buildMedicalInfoCard(),
                  const SizedBox(height: 16),
                  _buildEmergencyContactCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEditProfile,
        backgroundColor: const Color(0xFF6B84DC),
        child: const Icon(Icons.edit),
      ),
    );
  }

  