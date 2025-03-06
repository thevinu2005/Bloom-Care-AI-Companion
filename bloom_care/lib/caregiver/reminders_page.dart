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
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: primaryColor),
                prefixIcon: Icon(Icons.description, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: primaryColor),
                prefixIcon: Icon(Icons.category, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                      style: TextStyle(color: primaryColor),
                    ),
                    trailing: Icon(Icons.calendar_today, color: primaryColor),
                    onTap: _pickDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(
                      'Time: ${_selectedTime.format(context)}',
                      style: TextStyle(color: primaryColor),
                    ),
                    trailing: Icon(Icons.access_time, color: primaryColor),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                final newReminder = ProfessionalReminder(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  date: _selectedDate,
                  time: _selectedTime,
                  category: _selectedCategory,
                );
                setState(() {
                  _reminders.add(newReminder);
                });
                _titleController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: Text(
                'Create Reminder',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _deleteReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group reminders by category
    Map<String, List<ProfessionalReminder>> groupedReminders = {};
    for (var reminder in _reminders) {
      groupedReminders.putIfAbsent(reminder.category, () => []).add(reminder);
    }

    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        title: Text(
          'Reminders: ${widget.patientName}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notification action
            },
          ),
          IconButton(
            icon: Icon(Icons.person_outline),
            onPressed: () {
              // Profile action
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _reminders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 100,
              color: primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No Reminders Yet',
              style: TextStyle(
                fontSize: 18,
                color: primaryColor,
              ),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: groupedReminders.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              ...entry.value.map((reminder) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.description,
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${DateFormat('MMM dd, yyyy').format(reminder.date)} '
                              'at ${reminder.time.format(context)}',
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      onPressed: () => _deleteReminder(
                          _reminders.indexOf(reminder)),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ProfessionalReminder {
  String title;
  String description;
  DateTime date;
  TimeOfDay time;
  String category;

  ProfessionalReminder({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.category = 'General',
  });

  // Convert Reminder to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'category': category,
    };
  }

  // Create Reminder from Map
  factory ProfessionalReminder.fromMap(Map<String, dynamic> map) {
    return ProfessionalReminder(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      time: map['time'] != null
          ? TimeOfDay(
          hour: int.parse(map['time'].split(':')[0]),
          minute: int.parse(map['time'].split(':')[1])
      )
          : TimeOfDay.now(),
      category: map['category'] ?? 'General',
    );
  }
}