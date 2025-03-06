import 'package:flutter/material.dart';

class EditPatientPage extends StatefulWidget {
  final Map<String, dynamic> patient;

  const EditPatientPage({Key? key, required this.patient}) : super(key: key);

  @override
  _EditPatientPageState createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _conditionController;
  late TextEditingController _allergiesController;
  String? _selectedGender;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing patient data
    _nameController = TextEditingController(text: widget.patient['name']);
    _ageController = TextEditingController(text: widget.patient['age'].toString());
    _dateOfBirthController = TextEditingController(text: widget.patient['dateOfBirth'] ?? '');
    _conditionController = TextEditingController(text: widget.patient['condition'] ?? '');
    _allergiesController = TextEditingController(text: widget.patient['allergies'] ?? '');
    _selectedGender = widget.patient['gender'];
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _ageController.dispose();
    _dateOfBirthController.dispose();
    _conditionController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _savePatientDetails() {
    if (_formKey.currentState!.validate()) {
      // Collect updated patient information
      final updatedPatient = {
        ...widget.patient,
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'dateOfBirth': _dateOfBirthController.text.trim(),
        'condition': _conditionController.text.trim(),
        'allergies': _allergiesController.text.trim(),
      };

      // Return updated patient data to previous screen
      Navigator.pop(context, updatedPatient);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Patient Details'),
        backgroundColor: const Color(0xFF8B9CE0),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePatientDetails,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B9CE0).withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: Color(0xFF5B6EC7),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF5B6EC7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: () {
                            // TODO: Implement image picker
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Form
              _buildSectionTitle('Personal Information'),
              _buildTextFormField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _ageController,
                label: 'Age',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter patient age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              )