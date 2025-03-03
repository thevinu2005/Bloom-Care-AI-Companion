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

  // Basic info card
  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Color(0xFF6B84DC)),
                SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow('Age', _elder.age.toString()),
            _infoRow('Date of Birth', '${_elder.dateOfBirth.month}/${_elder.dateOfBirth.day}/${_elder.dateOfBirth.year}'),
            _infoRow('Gender', _elder.gender),
            _infoRow('Room Number', _elder.roomNumber),
          ],
        ),
      ),
    );
  }

  // Medical info card
  Widget _buildMedicalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_services, color: Color(0xFF6B84DC)),
                SizedBox(width: 8),
                Text(
                  'Medical Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow('Blood Type', _elder.bloodType),
            _infoRow('Allergies', _elder.allergies.isEmpty ? 'None' : _elder.allergies.join(', ')),
            _infoRow('Medications', _elder.medications.isEmpty ? 'None' : _elder.medications.join(', ')),
            _infoRow('Medical Conditions', _elder.medicalConditions.isEmpty ? 'None' : _elder.medicalConditions.join(', ')),
          ],
        ),
      ),
    );
  }

  // Emergency contact card
  Widget _buildEmergencyContactCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emergency, color: Color(0xFF6B84DC)),
                SizedBox(width: 8),
                Text(
                  'Emergency Contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow('Name', _elder.emergencyContact.name),
            _infoRow('Relationship', _elder.emergencyContact.relationship),
            _infoRow('Phone', _elder.emergencyContact.phone),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  onPressed: () {
                    _showMessage('Calling ${_elder.emergencyContact.name}...');
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  onPressed: () {
                    _showMessage('Messaging ${_elder.emergencyContact.name}...');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Simple info row
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Navigation method to edit profile
  void _navigateToEditProfile() {
    // Show edit profile dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                controller: TextEditingController(text: _elder.name),
                onChanged: (value) {
                  setState(() {
                    _elder.name = value;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Age'),
                controller: TextEditingController(text: _elder.age.toString()),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _elder.age = int.tryParse(value) ?? _elder.age;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Gender'),
                controller: TextEditingController(text: _elder.gender),
                onChanged: (value) {
                  setState(() {
                    _elder.gender = value;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Room Number'),
                controller: TextEditingController(text: _elder.roomNumber),
                onChanged: (value) {
                  setState(() {
                    _elder.roomNumber = value;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Blood Type'),
                controller: TextEditingController(text: _elder.bloodType),
                onChanged: (value) {
                  setState(() {
                    _elder.bloodType = value;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Allergies (comma separated)'),
                controller: TextEditingController(text: _elder.allergies.join(', ')),
                onChanged: (value) {
                  setState(() {
                    _elder.allergies = value.split(',').map((e) => e.trim()).toList();
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Medications (comma separated)'),
                controller: TextEditingController(text: _elder.medications.join(', ')),
                onChanged: (value) {
                  setState(() {
                    _elder.medications = value.split(',').map((e) => e.trim()).toList();
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Medical Conditions (comma separated)'),
                controller: TextEditingController(text: _elder.medicalConditions.join(', ')),
                onChanged: (value) {
                  setState(() {
                    _elder.medicalConditions = value.split(',').map((e) => e.trim()).toList();
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B84DC),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _showMessage('Profile updated');
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}