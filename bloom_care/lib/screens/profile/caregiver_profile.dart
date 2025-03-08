import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bloom_care/widgets/navigation_bar_for_caregiver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CaregiverProfilePage extends StatefulWidget {
  const CaregiverProfilePage({Key? key}) : super(key: key);

  @override
  State<CaregiverProfilePage> createState() => _CaregiverProfilePageState();
}

class _CaregiverProfilePageState extends State<CaregiverProfilePage> {
  // Add an editing state variable
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  File? _imageFile;
  String? _profileImageUrl;

  // Create controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _experienceController;
  late TextEditingController _educationController;
  late TextEditingController _aboutController;
  late TextEditingController _availabilityController;

  // Lists for skills and certifications
  late List<String> _certifications;
  late List<String> _skills;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Caregiver data
  Map<String, dynamic> caregiverData = {};

  // Default data for new users
  final Map<String, dynamic> defaultCaregiverData = {
    "name": "",
    "title": "Caregiver",
    "email": "",
    "phone": "",
    "address": "",
    "experience": "0 years",
    "education": "",
    "certifications": [],
    "skills": [],
    "availability": "Monday to Friday, 9:00 AM - 5:00 PM",
    "about": "I am a caregiver dedicated to providing quality care.",
    "profileImageUrl": "",
    "stats": {
      "visits": 0,
      "patients": 0,
      "hours": 0,
      "patientSatisfaction": 0.0,
      "attendanceRate": 0.0
    }
  };

  // Updated color scheme based on the provided code
  final Color primaryColor = const Color(0xFF8B9CE0); // Light purple/blue
  final Color backgroundColor = const Color(0xFFE6ECFF); // Very light blue
  final Color accentColor = const Color(0xFF5B6EC7); // Deeper purple/blue

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with empty values first
    _nameController = TextEditingController();
    _titleController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _experienceController = TextEditingController();
    _educationController = TextEditingController();
    _aboutController = TextEditingController();
    _availabilityController = TextEditingController();
    
    // Initialize empty lists
    _certifications = [];
    _skills = [];
    
    // Load data from Firebase
    _loadCaregiverData();
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _aboutController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  // Load caregiver data from Firestore
  Future<void> _loadCaregiverData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user document from Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        // Document exists, load the data
        setState(() {
          caregiverData = docSnapshot.data() ?? {};
          
          // Set profile image URL if it exists
          _profileImageUrl = caregiverData['profileImageUrl'];
          
          // Update controllers with data
          _nameController.text = caregiverData['name'] ?? '';
          _titleController.text = caregiverData['title'] ?? '';
          _emailController.text = caregiverData['email'] ?? user.email ?? '';
          _phoneController.text = caregiverData['phone'] ?? '';
          _addressController.text = caregiverData['address'] ?? '';
          _experienceController.text = caregiverData['experience'] ?? '';
          _educationController.text = caregiverData['education'] ?? '';
          _aboutController.text = caregiverData['about'] ?? '';
          _availabilityController.text = caregiverData['availability'] ?? '';
          
          // Update lists
          _certifications = List<String>.from(caregiverData['certifications'] ?? []);
          _skills = List<String>.from(caregiverData['skills'] ?? []);
        });
      } else {
        // Document doesn't exist, create a new one with default values
        final newUserData = Map<String, dynamic>.from(defaultCaregiverData);
        newUserData['email'] = user.email ?? '';
        newUserData['name'] = user.displayName ?? '';
        
        // Save default data to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUserData);
        
        setState(() {
          caregiverData = newUserData;
          
          // Update controllers with default data
          _nameController.text = newUserData['name'];
          _titleController.text = newUserData['title'];
          _emailController.text = newUserData['email'];
          _phoneController.text = newUserData['phone'];
          _addressController.text = newUserData['address'];
          _experienceController.text = newUserData['experience'];
          _educationController.text = newUserData['education'];
          _aboutController.text = newUserData['about'];
          _availabilityController.text = newUserData['availability'];
          
          // Update lists
          _certifications = List<String>.from(newUserData['certifications']);
          _skills = List<String>.from(newUserData['skills']);
        });
      }
    } catch (e) {
      print('Error loading caregiver data: $e');
      setState(() {
        _errorMessage = 'Failed to load profile data. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create a reference to the file location
      final storageRef = _storage.ref().child('profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library),
                        SizedBox(width: 10),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(),
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt),
                        SizedBox(width: 10),
                        Text('Camera'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Save changes to Firestore
  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Upload image if a new one was selected
      String? imageUrl = _profileImageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
        if (imageUrl == null) {
          throw Exception('Failed to upload profile image');
        }
      }

      // Prepare data to save
      final updatedData = {
        "name": _nameController.text,
        "title": _titleController.text,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
        "experience": _experienceController.text,
        "education": _educationController.text,
        "about": _aboutController.text,
        "availability": _availabilityController.text,
        "certifications": _certifications,
        "skills": _skills,
        "profileImageUrl": imageUrl,
        "lastUpdated": FieldValue.serverTimestamp(),
      };

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update(updatedData);

      // Update local state
      setState(() {
        caregiverData = {...caregiverData, ...updatedData};
        _profileImageUrl = imageUrl;
        _imageFile = null;
        _isEditing = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error saving profile: $e');
      setState(() {
        _errorMessage = 'Failed to save profile. Please try again.';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $_errorMessage'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Cancel editing and revert to original data
  void _cancelEditing() {
    setState(() {
      // Reset controllers to original data
      _nameController.text = caregiverData["name"] ?? '';
      _titleController.text = caregiverData["title"] ?? '';
      _emailController.text = caregiverData["email"] ?? '';
      _phoneController.text = caregiverData["phone"] ?? '';
      _addressController.text = caregiverData["address"] ?? '';
      _experienceController.text = caregiverData["experience"] ?? '';
      _educationController.text = caregiverData["education"] ?? '';
      _aboutController.text = caregiverData["about"] ?? '';
      _availabilityController.text = caregiverData["availability"] ?? '';

      // Reset lists
      _certifications = List<String>.from(caregiverData["certifications"] ?? []);
      _skills = List<String>.from(caregiverData["skills"] ?? []);

      // Reset image
      _imageFile = null;

      // Exit editing mode
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          _isEditing ? "Edit Profile" : "My Profile",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: _isEditing
            ? IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _cancelEditing,
        )
            : null,
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isSaving 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(Icons.check, color: Colors.white),
              onPressed: _isSaving ? null : _saveChanges,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header with image and basic info
                    Center(
                      child: Column(
                        children: [
                          // Profile image
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor,
                                width: 3.0,
                              ),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(_profileImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                            ),
                            child: _imageFile == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Center(
                                        child: Icon(
                                          Icons.person,
                                          size: 70,
                                          color: accentColor,
                                        ),
                                      ),
                                      if (_isEditing)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: CircleAvatar(
                                            backgroundColor: accentColor,
                                            radius: 18,
                                            child: IconButton(
                                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                              onPressed: _showImageSourceDialog,
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : _isEditing
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: CircleAvatar(
                                              backgroundColor: accentColor,
                                              radius: 18,
                                              child: IconButton(
                                                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                                onPressed: _showImageSourceDialog,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          // Name and title
                          _isEditing
                              ? Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                      child: TextField(
                                        controller: _nameController,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Full Name",
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                      child: TextField(
                                        controller: _titleController,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Professional Title",
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Text(
                                      caregiverData["name"] ?? "Caregiver",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      caregiverData["title"] ?? "Healthcare Professional",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 8),
                          // Quick contact buttons (only in view mode)
                          if (!_isEditing)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildContactButton(Icons.call, "Call"),
                                const SizedBox(width: 16),
                                _buildContactButton(Icons.message, "Message"),
                                const SizedBox(width: 16),
                                _buildContactButton(Icons.email, "Email"),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Personal Info Section
                    _buildSectionTitle("Personal Information"),
                    _buildInfoCard([
                      _buildInfoRow(Icons.phone, "Phone", caregiverData["phone"] ?? "", controller: _phoneController),
                      _buildInfoRow(Icons.email, "Email", caregiverData["email"] ?? "", controller: _emailController),
                      _buildInfoRow(Icons.location_on, "Address", caregiverData["address"] ?? "", controller: _addressController),
                      _buildInfoRow(Icons.work, "Experience", caregiverData["experience"] ?? "", controller: _experienceController),
                      _buildInfoRow(Icons.calendar_today, "Availability", caregiverData["availability"] ?? "", controller: _availabilityController),
                    ]),

                    const SizedBox(height: 24),

                    // About Me Section
                    _buildSectionTitle("About Me"),
                    _isEditing
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _aboutController,
                              maxLines: 5,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: "Write about yourself",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          )
                        : _buildDetailCard(caregiverData["about"] ?? "No information provided."),

                    const SizedBox(height: 24),

                    // Education & Certifications
                    _buildSectionTitle("Education & Certifications"),
                    _isEditing
                        ? _buildEditableInfoCard([
                            _buildInfoRow(Icons.school, "Education", caregiverData["education"] ?? "", controller: _educationController),
                            const SizedBox(height: 8),
                            _buildEditableListSection("Certifications", _certifications),
                          ])
                        : _buildInfoCard([
                            _buildInfoRow(Icons.school, "Education", caregiverData["education"] ?? ""),
                            const SizedBox(height: 8),
                            _buildListSection("Certifications", caregiverData["certifications"] ?? []),
                          ]),

                    const SizedBox(height: 24),

                    // Skills Section
                    _buildSectionTitle("Skills & Expertise"),
                    _isEditing
                        ? _buildEditableSkillsGrid(_skills)
                        : _buildSkillsGrid(caregiverData["skills"] ?? []),

                    const SizedBox(height: 24),

                    // Statistics Section
                    _buildSectionTitle("Care Statistics"),
                    _buildStatsCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNav_for_caregivers(currentIndex: 2), // Assuming profile is the last tab
    );
  }

  Widget _buildContactButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildEditableInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                _isEditing && controller != null
                    ? TextField(
                        controller: controller,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter $label",
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          isDense: true,
                        ),
                      )
                    : Text(
                        value.isEmpty ? "Not provided" : value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String label, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        items.isEmpty
            ? Text(
                "No $label added yet",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              )
            : Column(
                children: items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
      ],
    );
  }

  Widget _buildEditableListSection(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: accentColor),
              onPressed: () {
                _showAddItemDialog(
                  title: "Add $label",
                  onAdd: (value) {
                    setState(() {
                      _certifications.add(value);
                    });
                  },
                );
              },
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 8),
        items.isEmpty
            ? Text(
                "No $label added yet. Tap + to add.",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              )
            : Column(
                children: items.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              items.removeAt(idx);
                            });
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildSkillsGrid(List<dynamic> skills) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: skills.isEmpty
          ? Center(
              child: Text(
                "No skills added yet",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) => _buildSkillChip(skill)).toList(),
            ),
    );
  }

  Widget _buildEditableSkillsGrid(List<String> skills) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          skills.isEmpty
              ? Center(
                  child: Text(
                    "No skills added yet. Add your first skill below.",
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[500],
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: skills.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String skill = entry.value;
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4, right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              fontSize: 13,
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                skills.removeAt(idx);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Skill"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _showAddItemDialog(
                  title: "Add Skill",
                  onAdd: (value) {
                    setState(() {
                      skills.add(value);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to show add item dialog
  void _showAddItemDialog({required String title, required Function(String) onAdd}) {
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(hintText: "Enter $title"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Add"),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  onAdd(textController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 13,
          color: accentColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    // Get stats from caregiverData or use defaults
    final stats = caregiverData['stats'] as Map<String, dynamic>? ?? {
      "visits": 0,
      "patients": 0,
      "hours": 0,
      "patientSatisfaction": 0.0,
      "attendanceRate": 0.0
    };
    
    final visits = stats['visits'] ?? 0;
    final patients = stats['patients'] ?? 0;
    final hours = stats['hours'] ?? 0;
    final patientSatisfaction = (stats['patientSatisfaction'] ?? 0.0).toDouble();
    final attendanceRate = (stats['attendanceRate'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(visits.toString(), "Visits"),
              _buildStatItem(patients.toString(), "Patients"),
              _buildStatItem(hours.toString(), "Hours"),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRatingIndicator("Patient Satisfaction", patientSatisfaction),
              _buildRatingIndicator("Attendance Rate", attendanceRate),
            ],
          ),
        ],
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

  Widget _buildRatingIndicator(String label, double rating) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (index) => Icon(
              Icons.star,
              size: 16,
              color: index < rating.floor()
                  ? accentColor
                  : (index < rating ? accentColor : Colors.grey[300]),
            )),
          ],
        ),
      ],
    );
  }
}

