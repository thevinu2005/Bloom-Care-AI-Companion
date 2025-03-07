import 'package:flutter/material.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bloom_care/services/notification_service.dart';
import 'package:intl/intl.dart';

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

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  List<Medicine> medicines = [];
  TimeOfDay? _selectedTime;
  bool _showReminderOptions = false;
  bool _isLoading = true;
  
  // Selected days for recurring medication
  Map<String, bool> selectedDays = {
    'Mon': false,
    'Tue': false,
    'Wed': false,
    'Thu': false,
    'Fri': false,
    'Sat': false,
    'Sun': false,
  };

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  // Load medicines from Firestore
  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Clear existing data
      medicines.clear();

      // Load medicines
      final medicinesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .get();

      for (var doc in medicinesSnapshot.docs) {
        final data = doc.data();
        
        // Convert recurring days from Firestore
        Map<String, bool> recurringDays = {};
        if (data['recurringDays'] != null) {
          final Map<String, dynamic> storedDays = Map<String, dynamic>.from(data['recurringDays']);
          storedDays.forEach((key, value) {
            recurringDays[key] = value as bool;
          });
        } else {
          recurringDays = {
            'Mon': false,
            'Tue': false,
            'Wed': false,
            'Thu': false,
            'Fri': false,
            'Sat': false,
            'Sun': false,
          };
        }
        
        medicines.add(Medicine(
          id: doc.id,
          name: data['name'] ?? '',
          dosage: data['dosage'] ?? '',
          time: data['time'] ?? '',
          quantity: data['quantity'] ?? '',
          notes: data['notes'] ?? '',
          recurringDays: recurringDays,
          hasReminder: data['hasReminder'] ?? false,
        ));
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medicines: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading medicines: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Save medicine to Firestore
  Future<void> _saveMedicine(Medicine medicine) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // If the medicine has an ID, update it, otherwise add a new one
      if (medicine.id != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medicines')
            .doc(medicine.id)
            .update({
          'name': medicine.name,
          'dosage': medicine.dosage,
          'time': medicine.time,
          'quantity': medicine.quantity,
          'notes': medicine.notes,
          'hasReminder': medicine.hasReminder,
          'recurringDays': medicine.recurringDays,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new medicine and update the ID
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medicines')
            .add({
          'name': medicine.name,
          'dosage': medicine.dosage,
          'time': medicine.time,
          'quantity': medicine.quantity,
          'notes': medicine.notes,
          'hasReminder': medicine.hasReminder,
          'recurringDays': medicine.recurringDays,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Update the medicine with the new ID
        medicine.id = docRef.id;
      }
      
      // Send notification about the new medicine
      await _sendMedicineNotification(medicine);
      
      // Schedule reminder if needed
      if (medicine.hasReminder) {
        await _scheduleReminder(medicine);
      }
      
    } catch (e) {
      print('Error saving medicine: $e');
      throw e;
    }
  }

  // Delete medicine from Firestore
  Future<void> _deleteMedicine(Medicine medicine) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Only delete from Firestore if it has an ID
      if (medicine.id != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medicines')
            .doc(medicine.id)
            .delete();
      }
      
      // Remove from local list
      setState(() {
        medicines.remove(medicine);
      });
      
      // Cancel any scheduled reminders
      // This would require additional implementation in the NotificationService
      
    } catch (e) {
      print('Error deleting medicine: $e');
      throw e;
    }
  }

  // Send notification about medicine to elder and caregiver
  Future<void> _sendMedicineNotification(Medicine medicine) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create notification for the elder
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'type': 'medicine',
        'title': 'New Medication Added',
        'message': 'You have added ${medicine.name} (${medicine.dosage}) to take at ${medicine.time}',
        'color': const Color(0xFFE2D9F3).value,
        'textColor': const Color(0xFF6A359C).value,
        'icon': 'medication',
        'iconColor': const Color(0xFF6B84DC).value,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Notify caregiver about the new medicine
      await _notifyCaregiverAboutMedicine(medicine);

    } catch (e) {
      print('Error sending medicine notification: $e');
    }
  }

  // Notify caregiver about elder's medicine
  Future<void> _notifyCaregiverAboutMedicine(Medicine medicine) async {
    try {
      // Use the notification service to send the notification to caregiver
      await _notificationService.notifyCaregiverAboutElderActivity(
        activityType: 'medicine',
        activityName: medicine.name,
        activityDetails: '${medicine.dosage} at ${medicine.time}',
      );
    } catch (e) {
      print('Error sending medicine notification to caregiver: $e');
    }
  }

  // Schedule reminder for medicine
  Future<void> _scheduleReminder(Medicine medicine) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Parse the time string to get hours and minutes
      final timeParts = medicine.time.split(':');
      if (timeParts.length != 2) {
        // Try another format like "2:30 PM"
        final timeFormat = DateFormat('h:mm a');
        final dateTime = timeFormat.parse(medicine.time);
        final hour = dateTime.hour;
        final minute = dateTime.minute;
        
        // Create a reminder in Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .add({
          'type': 'medicine',
          'title': 'Medicine Reminder',
          'message': 'Time to take ${medicine.name} (${medicine.dosage})',
          'medicineId': medicine.id,
          'hour': hour,
          'minute': minute,
          'recurringDays': medicine.recurringDays,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Note: In a real app, you would also set up a background service or use
        // a package like flutter_local_notifications to schedule the actual reminder
        
      } else {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        // Create a reminder in Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .add({
          'type': 'medicine',
          'title': 'Medicine Reminder',
          'message': 'Time to take ${medicine.name} (${medicine.dosage})',
          'medicineId': medicine.id,
          'hour': hour,
          'minute': minute,
          'recurringDays': medicine.recurringDays,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
    } catch (e) {
      print('Error scheduling reminder: $e');
    }
  }

  void _addMedicine() async {
    if (_medicineNameController.text.isNotEmpty &&
        _dosageController.text.isNotEmpty &&
        _timeController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty) {
      
      try {
        // Create new medicine object
        final newMedicine = Medicine(
          name: _medicineNameController.text,
          dosage: _dosageController.text,
          time: _timeController.text,
          quantity: _quantityController.text,
          notes: _notesController.text,
          hasReminder: _showReminderOptions,
          recurringDays: Map.from(selectedDays),
        );
        
        // Save to Firestore
        await _saveMedicine(newMedicine);
        
        // Add to local list
        setState(() {
          medicines.add(newMedicine);
        });

        // Clear fields after adding
        _medicineNameController.clear();
        _dosageController.clear();
        _timeController.clear();
        _quantityController.clear();
        _notesController.clear();
        setState(() {
          _showReminderOptions = false;
          // Reset selected days
          selectedDays.forEach((key, value) {
            selectedDays[key] = false;
          });
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
      } catch (e) {
        print('Error adding medicine: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding medicine: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      // Show error for empty fields
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _removeMedicine(int index) async {
    try {
      await _deleteMedicine(medicines[index]);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Medicine removed successfully'),
          backgroundColor: const Color(0xFF6B84DC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error removing medicine: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing medicine: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8FA2E6)))
          : SingleChildScrollView(
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

                        const SizedBox(height: 16),

                        // Add Medicine Button - full width now
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _addMedicine,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B84DC),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text(
                              'Add Medication',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Medicine List Title
                  const Text(
                    'Your Medications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Medicine List
                  medicines.isEmpty
                      ? _emptyMedicationState()
                      : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = medicines[index];
                      return _buildMedicineCard(medicine, index);
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: -1),
    );
  }

  Widget _buildDayChip(String day) {
    return ChoiceChip(
      label: Text(day),
      selected: selectedDays[day] ?? false,
      onSelected: (bool selected) {
        setState(() {
          selectedDays[day] = selected;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF8FA2E6),
      labelStyle: TextStyle(
        color: selectedDays[day] ?? false ? Colors.white : const Color(0xFF6B84DC),
        fontWeight: selectedDays[day] ?? false ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _emptyMedicationState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No medications added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your medications above to track them',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine, int index) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3C1F0).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: Color(0xFF6B84DC),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Dosage: ${medicine.dosage}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeMedicine(index),
                  tooltip: 'Remove medication',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF6B84DC),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Time: ${medicine.time}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: Color(0xFF6B84DC),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Qty: ${medicine.quantity}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (medicine.hasReminder) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB3C1F0).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          size: 14,
                          color: Color(0xFF6B84DC),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Reminder Set',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B84DC),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (medicine.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${medicine.notes}',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            if (medicine.hasReminder && medicine.recurringDays.values.any((value) => value)) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: medicine.recurringDays.entries
                    .where((entry) => entry.value)
                    .map((entry) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8FA2E6).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B84DC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Medicine data class
class Medicine {
  String? id;
  String name;
  String dosage;
  String time;
  String quantity;
  String notes;
  bool hasReminder;
  Map<String, bool> recurringDays;

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.quantity,
    this.notes = '',
    this.hasReminder = false,
    Map<String, bool>? recurringDays,
  }) : this.recurringDays = recurringDays ?? {
          'Mon': false,
          'Tue': false,
          'Wed': false,
          'Thu': false,
          'Fri': false,
          'Sat': false,
          'Sun': false,
        };
}