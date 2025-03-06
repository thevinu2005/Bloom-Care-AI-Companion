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
      body: SafeArea(
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
                      ),
                      child: Stack(
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
                                  icon: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                  onPressed: () {
                                    // Photo upload functionality would go here
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Photo upload functionality would be implemented here'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
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
                          caregiverData["name"],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          caregiverData["title"],
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
                _buildInfoRow(Icons.phone, "Phone", caregiverData["phone"], controller: _phoneController),
                _buildInfoRow(Icons.email, "Email", caregiverData["email"], controller: _emailController),
                _buildInfoRow(Icons.location_on, "Address", caregiverData["address"], controller: _addressController),
                _buildInfoRow(Icons.work, "Experience", caregiverData["experience"], controller: _experienceController),
                _buildInfoRow(Icons.calendar_today, "Availability", caregiverData["availability"], controller: _availabilityController),
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
                  : _buildDetailCard(caregiverData["about"]),

              const SizedBox(height: 24),

              // Education & Certifications
              _buildSectionTitle("Education & Certifications"),
              _isEditing
                  ? _buildEditableInfoCard([
                _buildInfoRow(Icons.school, "Education", caregiverData["education"], controller: _educationController),
                const SizedBox(height: 8),
                _buildEditableListSection("Certifications", _certifications),
              ])
                  : _buildInfoCard([
                _buildInfoRow(Icons.school, "Education", caregiverData["education"]),
                const SizedBox(height: 8),
                _buildListSection("Certifications", caregiverData["certifications"]),
              ]),

              const SizedBox(height: 24),

              // Skills Section
              _buildSectionTitle("Skills & Expertise"),
              _isEditing
                  ? _buildEditableSkillsGrid(_skills)
                  : _buildSkillsGrid(caregiverData["skills"]),

              const SizedBox(height: 24),

              // Statistics Section
              _buildSectionTitle("Care Statistics"),
              _buildStatsCard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 4), // Assuming profile is the last tab
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
                  value,
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
        ...items.map((item) => Padding(
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