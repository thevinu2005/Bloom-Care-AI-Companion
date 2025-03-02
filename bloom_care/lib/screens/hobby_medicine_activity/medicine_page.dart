import 'package:flutter/material.dart';
import 'bottom_nav.dart';

class MedicinePage extends StatefulWidget {
  const MedicinePage({super.key});

  @override
  _MedicinePageState createState() => _MedicinePageState();
}

class _MedicinePageState extends State<MedicinePage> {
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, String>> medicines = [];
  TimeOfDay? _selectedTime;
  bool _showReminderOptions = false;

  void _addMedicine() {
    if (_medicineNameController.text.isNotEmpty &&
        _dosageController.text.isNotEmpty &&
        _timeController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty) {
      setState(() {
        medicines.add({
          'name': _medicineNameController.text,
          'dosage': _dosageController.text,
          'time': _timeController.text,
          'quantity': _quantityController.text,
          'notes': _notesController.text,
        });
      });

      // Clear fields after adding
      _medicineNameController.clear();
      _dosageController.clear();
      _timeController.clear();
      _quantityController.clear();
      _notesController.clear();
      setState(() {
        _showReminderOptions = false;
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Medicine added successfully!'),
          backgroundColor: const Color(0xFF6B84DC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _removeMedicine(int index) {
    setState(() {
      medicines.removeAt(index);
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _selectedTime!.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7E0FA), // Match home page background
      appBar: AppBar(
        backgroundColor: const Color(0xFF8FA2E6), // Match home page app bar
        title: const Text(
          'Medication',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB3C1F0), // Match home page container
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightBlueAccent.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Your Medications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your prescriptions to receive reminders',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Add Medicine Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Medication',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medicine Name
                  TextField(
                    controller: _medicineNameController,
                    decoration: InputDecoration(
                      labelText: 'Medicine Name',
                      labelStyle: const TextStyle(color: Color(0xFF6B84DC)),
                      prefixIcon: const Icon(Icons.medication, color: Color(0xFF6B84DC)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6B84DC), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dosage
                  TextField(
                    controller: _dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage (e.g. 500mg)',
                      labelStyle: const TextStyle(color: Color(0xFF6B84DC)),
                      prefixIcon: const Icon(Icons.local_pharmacy, color: Color(0xFF6B84DC)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6B84DC), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time to Take - with time picker
                  TextField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: () => _selectTime(context),
                    decoration: InputDecoration(
                      labelText: 'Time to Take',
                      labelStyle: const TextStyle(color: Color(0xFF6B84DC)),
                      prefixIcon: const Icon(Icons.access_time, color: Color(0xFF6B84DC)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, color: Color(0xFF6B84DC)),
                        onPressed: () => _selectTime(context),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6B84DC), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quantity
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      labelStyle: const TextStyle(color: Color(0xFF6B84DC)),
                      prefixIcon: const Icon(Icons.format_list_numbered, color: Color(0xFF6B84DC)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6B84DC), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reminder options toggle
                  Row(
                    children: [
                      const Text('Add reminder options?',
                        style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B84DC),
                            fontWeight: FontWeight.w500
                        ),
                      ),
                      Switch(
                        value: _showReminderOptions,
                        onChanged: (value) {
                          setState(() {
                            _showReminderOptions = value;
                          });
                        },
                        activeColor: const Color(0xFF6B84DC),
                      ),
                    ],
                  ),

                  // Additional options if toggle is on
                  if (_showReminderOptions) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Special Instructions',
                        labelStyle: const TextStyle(color: Color(0xFF6B84DC)),
                        prefixIcon: const Icon(Icons.notes, color: Color(0xFF6B84DC)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6B84DC), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Recurring options
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Repeat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B84DC),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildDayChip('Mon'),
                              _buildDayChip('Tue'),
                              _buildDayChip('Wed'),
                              _buildDayChip('Thu'),
                              _buildDayChip('Fri'),
                              _buildDayChip('Sat'),
                              _buildDayChip('Sun'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
