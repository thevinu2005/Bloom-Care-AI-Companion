import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfessionalRemindersPage extends StatefulWidget {
  final String patientName;
  final List<dynamic> initialReminders;

  const ProfessionalRemindersPage({
    Key? key,
    required this.patientName,
    this.initialReminders = const [],
  }) : super(key: key);

  @override
  _ProfessionalRemindersPageState createState() => _ProfessionalRemindersPageState();
}

class _ProfessionalRemindersPageState extends State<ProfessionalRemindersPage> {
  late List<ProfessionalReminder> _reminders;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'General';

  final List<String> _categories = [
    'General',
    'Medical',
    'Personal',
    'Work',
    'Health',
    'Medication'
  ];

  // Color palette matching the image
  final Color primaryColor = Color(0xFF6B7ACD); // Slate Blue from the app bar
  final Color accentColor = Color(0xFFF5F6FA); // Light background color
  final Color textColor = Colors.black87;
  final Color secondaryTextColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    _reminders = widget.initialReminders.map((r) =>
        ProfessionalReminder.fromMap(r is Map<String, dynamic> ? r : {})).toList();
  }

  void _addReminder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create New Reminder',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Reminder Title',
                labelStyle: TextStyle(color: primaryColor),
                prefixIcon: Icon(Icons.title, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            )