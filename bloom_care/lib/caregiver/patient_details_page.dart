import 'package:flutter/material.dart';
import 'medications_page.dart';
import 'edit_patient_page.dart'; // Import the new edit page
import 'reminders_page.dart';

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailsPage({Key? key, required this.patient}) : super(key: key);

  @override
  _PatientDetailsPageState createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  late Map<String, dynamic> _patient;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  void _navigateToEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPatientPage(patient: _patient),
      ),
    );

    if (result != null) {
      setState(() {
        _patient = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_patient['name']} - Details'),
        backgroundColor: const Color(0xFF8B9CE0),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Picture Section (same as before)
            Center(
              child: Container(
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
            ),
            const SizedBox(height: 24),

            // Personal Information Card
            _buildDetailsCard(
              title: 'Personal Information',
              children: [
                _buildDetailRow('Full Name', _patient['name']),
                _buildDetailRow('Age', '${_patient['age']} years'),
                _buildDetailRow('Gender', _patient['gender'] ?? 'Not specified'),
                _buildDetailRow('Date of Birth', _patient['dateOfBirth'] ?? 'Not specified'),
              ],
            ),

            const SizedBox(height: 16),

            // Medical Information Card
            _buildDetailsCard(
              title: 'Medical Information',
              children: [
                _buildDetailRow('Primary Condition', _patient['condition'] ?? 'Not specified'),
                _buildDetailRow('Current Medications', 'Not available'),
                _buildDetailRow('Allergies', 'Not specified'),
              ],
            ),

            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B6EC7),
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B6EC7),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: Icons.medication,
                  label: 'Medications',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicationsPage(
                          patientName: _patient['name'],
                          initialMedications: _patient['medications'] ?? [],
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.event_note,
                  label: 'Reminders',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfessionalRemindersPage(
                          patientName: _patient['name'],
                          initialReminders: _patient['reminders'] ?? [],
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: const Color(0xFF5B6EC7),
            size: 36,
          ),
          onPressed: onTap,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

