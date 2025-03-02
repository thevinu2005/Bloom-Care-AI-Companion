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
