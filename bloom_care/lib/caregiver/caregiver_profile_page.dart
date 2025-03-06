import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bottom_nav.dart';

class CaregiverProfilePage extends StatefulWidget {
  const CaregiverProfilePage({Key? key}) : super(key: key);

  @override
  State<CaregiverProfilePage> createState() => _CaregiverProfilePageState();
}

class _CaregiverProfilePageState extends State<CaregiverProfilePage> {
  // Add an editing state variable
  bool _isEditing = false;

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

  // Caregiver data
  final Map<String, dynamic> caregiverData = {
    "name": "Sarah Johnson",
    "title": "Senior Home Health Aide",
    "email": "sarah.johnson@carehealth.com",
    "phone": "(555) 123-4567",
    "address": "123 Healthcare Ave, Medical City, MC 12345",
    "experience": "5 years",
    "education": "Associate's Degree in Health Sciences",
    "certifications": [
      "Certified Nursing Assistant (CNA)",
      "Basic Life Support (BLS)",
      "First Aid Certification",
      "Medication Administration"
    ],
    "skills": [
      "Patient Care",
      "Vital Signs Monitoring",
      "Mobility Assistance",
      "Medication Management",
      "Wound Care",
      "Nutrition Support"
    ],
    "availability": "Monday to Friday, 8:00 AM - 5:00 PM",
    "about": "Compassionate caregiver with 5 years of experience providing personalized care to elderly and post-surgery patients. Specialized in chronic condition management and rehabilitation support."
  };

  // Updated color scheme based on the provided code
  final Color primaryColor = const Color(0xFF8B9CE0); // Light purple/blue
  final Color backgroundColor = const Color(0xFFE6ECFF); // Very light blue
  final Color accentColor = const Color(0xFF5B6EC7); // Deeper purple/blue

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: caregiverData["name"]);
    _titleController = TextEditingController(text: caregiverData["title"]);
    _emailController = TextEditingController(text: caregiverData["email"]);
    _phoneController = TextEditingController(text: caregiverData["phone"]);
    _addressController = TextEditingController(text: caregiverData["address"]);
    _experienceController = TextEditingController(text: caregiverData["experience"]);
    _educationController = TextEditingController(text: caregiverData["education"]);
    _aboutController = TextEditingController(text: caregiverData["about"]);
    _availabilityController = TextEditingController(text: caregiverData["availability"]);

    // Clone lists to avoid modifying the original data directly
    _certifications = List<String>.from(caregiverData["certifications"]);
    _skills = List<String>.from(caregiverData["skills"]);
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

  // Save changes to caregiverData
  void _saveChanges() {
    setState(() {
      caregiverData["name"] = _nameController.text;
      caregiverData["title"] = _titleController.text;
      caregiverData["email"] = _emailController.text;
      caregiverData["phone"] = _phoneController.text;
      caregiverData["address"] = _addressController.text;
      caregiverData["experience"] = _experienceController.text;
      caregiverData["education"] = _educationController.text;
      caregiverData["about"] = _aboutController.text;
      caregiverData["availability"] = _availabilityController.text;
      caregiverData["certifications"] = _certifications;
      caregiverData["skills"] = _skills;

      // Exit editing mode
      _isEditing = false;
    });

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Cancel editing and revert to original data
  void _cancelEditing() {
    setState(() {
      // Reset controllers to original data
      _nameController.text = caregiverData["name"];
      _titleController.text = caregiverData["title"];
      _emailController.text = caregiverData["email"];
      _phoneController.text = caregiverData["phone"];
      _addressController.text = caregiverData["address"];
      _experienceController.text = caregiverData["experience"];
      _educationController.text = caregiverData["education"];
      _aboutController.text = caregiverData["about"];
      _availabilityController.text = caregiverData["availability"];

      // Reset lists
      _certifications = List<String>.from(caregiverData["certifications"]);
      _skills = List<String>.from(caregiverData["skills"]);

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
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _saveChanges,
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