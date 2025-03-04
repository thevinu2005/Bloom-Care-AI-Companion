import 'package:flutter/material.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Define a simple Elder model class
class Elder {
  String id;
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
  List<RecentActivity> recentActivities;

  Elder({
    required this.id,
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
    this.recentActivities = const [],
  });

  // Create Elder from Firestore document
  factory Elder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse date of birth
    DateTime dob = DateTime.now().subtract(const Duration(days: 365 * 70)); // Default to 70 years ago
    if (data['dateOfBirth'] != null) {
      try {
        final parts = (data['dateOfBirth'] as String).split('/');
        if (parts.length == 3) {
          dob = DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      } catch (e) {
        print('Error parsing date of birth: $e');
      }
    }
    
    // Calculate age
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    
    // Parse emergency contact
    EmergencyContact contact = EmergencyContact(
      name: data['emergencyContactName'] ?? 'Not specified',
      relationship: data['emergencyContactRelationship'] ?? 'Not specified',
      phone: data['emergencyContactPhone'] ?? 'Not specified',
    );
    
    return Elder(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      age: age,
      dateOfBirth: dob,
      gender: data['gender'] ?? 'Not specified',
      roomNumber: data['roomNumber'] ?? 'Not specified',
      bloodType: data['bloodType'] ?? 'Not specified',
      allergies: List<String>.from(data['allergies'] ?? []),
      medications: List<String>.from(data['medications'] ?? []),
      medicalConditions: List<String>.from(data['medicalConditions'] ?? []),
      emergencyContact: contact,
      profileImagePath: data['profileImagePath'],
      recentActivities: [], // We'll load activities separately if needed
    );
  }
  
  // Convert Elder to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'dateOfBirth': '${dateOfBirth.day}/${dateOfBirth.month}/${dateOfBirth.year}',
      'gender': gender,
      'roomNumber': roomNumber,
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications,
      'medicalConditions': medicalConditions,
      'emergencyContactName': emergencyContact.name,
      'emergencyContactRelationship': emergencyContact.relationship,
      'emergencyContactPhone': emergencyContact.phone,
      'profileImagePath': profileImagePath,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
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

// Simple activity class
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
  const ElderCareProfilePage({Key? key}) : super(key: key);

  @override
  State<ElderCareProfilePage> createState() => _ElderCareProfilePageState();
}

class _ElderCareProfilePageState extends State<ElderCareProfilePage> {
  Elder? _elder;
  bool _isLoading = true;
  String? _errorMessage;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }
      
      setState(() {
        _elder = Elder.fromFirestore(userDoc);
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserData(Elder elder) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      await _firestore.collection('users').doc(user.uid).update(elder.toFirestore());
      
      setState(() {
        _elder = elder;
        _isLoading = false;
      });
      
      _showMessage('Profile updated successfully');
      
    } catch (e) {
      print('Error updating user data: $e');
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const BottomNav(currentIndex: 3),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 3),
      );
    }
    
    if (_elder == null) {
      return Scaffold(
        body: const Center(child: Text('No profile data available')),
        bottomNavigationBar: const BottomNav(currentIndex: 3),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_elder!.name,
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
                      child: _elder!.profileImagePath != null
                          ? Image.asset(
                        _elder!.profileImagePath!,
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
            _infoRow('Age', _elder!.age.toString()),
            _infoRow('Date of Birth', DateFormat('MM/dd/yyyy').format(_elder!.dateOfBirth)),
            _infoRow('Gender', _elder!.gender),
            _infoRow('Room Number', _elder!.roomNumber),
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
            _infoRow('Blood Type', _elder!.bloodType),
            _infoRow('Allergies', _elder!.allergies.isEmpty ? 'None' : _elder!.allergies.join(', ')),
            _infoRow('Medications', _elder!.medications.isEmpty ? 'None' : _elder!.medications.join(', ')),
            _infoRow('Medical Conditions', _elder!.medicalConditions.isEmpty ? 'None' : _elder!.medicalConditions.join(', ')),
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
            _infoRow('Name', _elder!.emergencyContact.name),
            _infoRow('Relationship', _elder!.emergencyContact.relationship),
            _infoRow('Phone', _elder!.emergencyContact.phone),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  onPressed: () {
                    _showMessage('Calling ${_elder!.emergencyContact.name}...');
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  onPressed: () {
                    _showMessage('Messaging ${_elder!.emergencyContact.name}...');
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
    // Create controllers for each field
    final nameController = TextEditingController(text: _elder!.name);
    final genderController = TextEditingController(text: _elder!.gender);
    final roomController = TextEditingController(text: _elder!.roomNumber);
    final bloodTypeController = TextEditingController(text: _elder!.bloodType);
    final allergiesController = TextEditingController(text: _elder!.allergies.join(', '));
    final medicationsController = TextEditingController(text: _elder!.medications.join(', '));
    final conditionsController = TextEditingController(text: _elder!.medicalConditions.join(', '));
    final emergencyNameController = TextEditingController(text: _elder!.emergencyContact.name);
    final emergencyRelationController = TextEditingController(text: _elder!.emergencyContact.relationship);
    final emergencyPhoneController = TextEditingController(text: _elder!.emergencyContact.phone);
    
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
                controller: nameController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Gender'),
                controller: genderController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Room Number'),
                controller: roomController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Blood Type'),
                controller: bloodTypeController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Allergies (comma separated)'),
                controller: allergiesController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Medications (comma separated)'),
                controller: medicationsController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Medical Conditions (comma separated)'),
                controller: conditionsController,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Emergency Contact',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                controller: emergencyNameController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Relationship'),
                controller: emergencyRelationController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Phone'),
                controller: emergencyPhoneController,
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
              // Create updated elder object
              final updatedElder = Elder(
                id: _elder!.id,
                name: nameController.text,
                age: _elder!.age, // Age is calculated from DOB
                dateOfBirth: _elder!.dateOfBirth, // Keep the same DOB
                gender: genderController.text,
                roomNumber: roomController.text,
                bloodType: bloodTypeController.text,
                allergies: allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                medications: medicationsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                medicalConditions: conditionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                emergencyContact: EmergencyContact(
                  name: emergencyNameController.text,
                  relationship: emergencyRelationController.text,
                  phone: emergencyPhoneController.text,
                ),
                profileImagePath: _elder!.profileImagePath,
                recentActivities: _elder!.recentActivities,
              );
              
              // Update in Firebase
              _updateUserData(updatedElder);
              
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

