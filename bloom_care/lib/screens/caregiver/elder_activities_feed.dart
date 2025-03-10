import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bloom_care/widgets/navigation_bar_for_caregiver.dart';

class ElderActivityFeed extends StatefulWidget {
  final String? elderId;

  const ElderActivityFeed({Key? key, this.elderId}) : super(key: key);

  @override
  State<ElderActivityFeed> createState() => _ElderActivityFeedState();
}

class _ElderActivityFeedState extends State<ElderActivityFeed> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  String _elderName = "";
  String _elderProfileImage = "assets/default_avatar.png";

  // Form controllers for adding new activities
  final _activityNameController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Selected activity type and time
  String _selectedActivityType = 'activity';
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadElderActivities();
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadElderActivities() async {
    setState(() {
      _isLoading = true;
      _activities.clear();
    });

    try {
      if (widget.elderId == null) {
        throw Exception('Elder ID is required');
      }

      // Get elder's details
      final elderDoc = await _firestore.collection('users').doc(widget.elderId).get();
      if (elderDoc.exists) {
        setState(() {
          _elderName = elderDoc.data()?['name'] ?? 'Elder';
          _elderProfileImage = elderDoc.data()?['profileImage'] ?? 'assets/default_avatar.png';
        });
      }

      // Load activities from all relevant collections
      final collections = {
        'meals': 'meal',
        'meal_plans': 'meal',
        'hobby_times': 'hobby',
        'hobbies': 'hobby',
        'appointments': 'appointment',
        'activities': 'activity',
      };

      for (var entry in collections.entries) {
        try {
          final snapshot = await _firestore
              .collection('users')
              .doc(widget.elderId)
              .collection(entry.key)
              .get();

          for (var doc in snapshot.docs) {
            final data = doc.data();
            
            // Create activity data based on type
            Map<String, dynamic> activityData = {
              'id': doc.id,
              'type': entry.value,
              'timestamp': data['timestamp'] ?? data['createdAt'] ?? Timestamp.now(),
              'isCompleted': data['isCompleted'] ?? false,
              'color': const Color(0xFFD1ECF1).value,
              'textColor': const Color(0xFF0C5460).value,
              'iconColor': Colors.blue.value,
            };

            // Add type-specific data
            switch (entry.value) {
              case 'meal':
                activityData.addAll({
                  'title': data['mealType'] ?? data['name'] ?? 'Meal',
                  'message': data['description'] ?? '',
                  'time': data['time'] ?? '',
                  'icon': 'restaurant',
                });
                break;

              case 'hobby':
                activityData.addAll({
                  'title': data['activity'] ?? data['name'] ?? 'Hobby',
                  'message': '${data['duration'] ?? '30 minutes'} of ${data['activity'] ?? data['name'] ?? 'activity'}',
                  'time': data['time'] ?? '',
                  'icon': 'sports_esports',
                });
                break;

              case 'appointment':
                activityData.addAll({
                  'title': data['title'] ?? data['name'] ?? 'Appointment',
                  'message': '${data['location'] ?? 'No location'} - ${data['isConfirmed'] ? 'Confirmed' : 'Pending'}',
                  'time': '${data['date'] ?? ''} at ${data['time'] ?? ''}',
                  'icon': 'event',
                });
                break;

              default:
                activityData.addAll({
                  'title': data['name'] ?? 'Activity',
                  'message': data['notes'] ?? '',
                  'time': data['time'] ?? '',
                  'icon': 'directions_walk',
                });
            }

            _activities.add(activityData);
          }
        } catch (e) {
          print('Error loading ${entry.key}: $e');
        }
      }

      // Sort all activities by timestamp
      _activities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp;
        final bTime = b['timestamp'] as Timestamp;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading elder activities: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading activities: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        
        // Format time as string (e.g., "8:30 AM")
        final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final minute = picked.minute.toString().padLeft(2, '0');
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _timeController.text = '$hour:$minute $period';
      });
    }
  }

  // Add new activity
  Future<void> _addActivity() async {
    if (_activityNameController.text.isEmpty || _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter activity name and time'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Determine collection name based on activity type
      String collectionName;
      switch (_selectedActivityType) {
        case 'meal':
          collectionName = 'meals';
          break;
        case 'appointment':
          collectionName = 'appointments';
          break;
        case 'hobby':
          collectionName = 'hobbies';
          break;
        default:
          collectionName = 'activities';
      }
      
      // Create activity data
      Map<String, dynamic> activityData = {
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'createdByName': user.displayName ?? 'Caregiver',
        'isCompleted': false,
        'time': _timeController.text,
      };
      
      // Add type-specific fields
      switch (_selectedActivityType) {
        case 'meal':
          activityData.addAll({
            'mealType': _activityNameController.text,
            'description': _notesController.text,
          });
          break;
        case 'appointment':
          activityData.addAll({
            'title': _activityNameController.text,
            'location': _locationController.text,
            'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
            'isConfirmed': true,
          });
          break;
        case 'hobby':
          activityData.addAll({
            'activity': _activityNameController.text,
            'duration': _durationController.text.isEmpty ? '30 minutes' : _durationController.text,
            'notes': _notesController.text,
          });
          break;
        default:
          activityData.addAll({
            'name': _activityNameController.text,
            'duration': _durationController.text.isEmpty ? '30 minutes' : _durationController.text,
            'notes': _notesController.text,
          });
      }
      
      // Add to Firestore
      await _firestore
          .collection('users')
          .doc(widget.elderId)
          .collection(collectionName)
          .add(activityData);
      
      // Send notification to elder
      await _sendActivityNotification(_selectedActivityType, _activityNameController.text);
      
      // Clear form fields
      _activityNameController.clear();
      _timeController.clear();
      _durationController.clear();
      _notesController.clear();
      _locationController.clear();
      
      // Reload activities
      await _loadElderActivities();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activity added successfully for $_elderName'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error adding activity: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding activity: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Send notification about new activity to elder
  Future<void> _sendActivityNotification(String activityType, String activityName) async {
    try {
      final user = _auth.currentUser;
      if (user == null || widget.elderId == null) return;
      
      // Get caregiver's name
      final caregiverDoc = await _firestore.collection('users').doc(user.uid).get();
      final caregiverName = caregiverDoc.data()?['name'] ?? 'Your caregiver';
      
      // Create notification for the elder
      await _firestore
          .collection('users')
          .doc(widget.elderId)
          .collection('notifications')
          .add({
        'type': 'activity',
        'title': 'New ${_getActivityTypeLabel(activityType)} Added',
        'message': '$caregiverName has added $activityName to your schedule',
        'color': const Color(0xFFD4EDDA).value,
        'textColor': const Color(0xFF155724).value,
        'icon': _getActivityIcon(activityType),
        'iconColor': _getActivityTypeColor(activityType).value,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending activity notification: $e');
    }
  }

  // Replace the build method with this improved layout
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFD7E0FA),
    appBar: AppBar(
      backgroundColor: const Color(0xFF8FA2E6),
      title: Text(
        '$_elderName\'s Activity Feed',
        style: const TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadElderActivities,
          tooltip: 'Refresh activities',
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Elder info and add button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(_elderProfileImage),
                      child: _elderProfileImage == 'assets/default_avatar.png'
                          ? Text(
                              _elderName.isNotEmpty ? _elderName[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _elderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Activity Feed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddActivityBottomSheet(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B84DC),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Activity'),
                    ),
                  ],
                ),
              ),
              
              // Activity list
              Expanded(
                child: _activities.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: _activities.length,
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          return _buildActivityCard(activity);
                        },
                      ),
              ),
            ],
          ),
    bottomNavigationBar: const BottomNav_for_caregivers(currentIndex: -1),
  );
}

// Add this method to show a bottom sheet for adding activities
void _showAddActivityBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Add New Activity for $_elderName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B6EC7),
              ),
            ),
          ),
          
          // Activity Type Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActivityTypeButton('Activity', 'activity', Icons.directions_walk),
                _buildActivityTypeButton('Meal', 'meal', Icons.restaurant),
                _buildActivityTypeButton('Hobby', 'hobby', Icons.sports_esports),
                _buildActivityTypeButton('Appointment', 'appointment', Icons.event),
              ],
            ),
          ),
          
          const Divider(height: 32),
          
          // Form fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Name
                  TextField(
                    controller: _activityNameController,
                    decoration: InputDecoration(
                      labelText: _getActivityNameLabel(),
                      labelStyle: const TextStyle(color: Color(0xFF6B84DC)),
                      prefixIcon: Icon(_getActivityTypeIcon(_selectedActivityType), color: const Color(0xFF6B84DC)),
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
                  const SizedBox(height: 16),
                  
                  // Time
                  TextField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: () => _selectTime(context),
                    decoration: InputDecoration(
                      labelText: 'Time',
                      labelStyle: const TextStyle(color: Color(0xFF6B84DC)),
                      prefixIcon: const Icon(Icons.access_time, color: Color(0xFF6B84DC)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.schedule, color: Color(0xFF6B84DC)),
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
                  const SizedBox(height: 16),
                  
                  // Duration (not needed for appointments)
                  if (_selectedActivityType != 'appointment')
                    TextField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration (e.g. 30 minutes)',
                        labelStyle: const TextStyle(color: Color(0xFF6B84DC)),
                        prefixIcon: const Icon(Icons.timer, color: Color(0xFF6B84DC)),
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
                  if (_selectedActivityType != 'appointment')
                    const SizedBox(height: 16),
                  
                  // Location (only for appointments)
                  if (_selectedActivityType == 'appointment')
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: const TextStyle(color: Color(0xFF6B84DC)),
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6B84DC)),
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
                  if (_selectedActivityType == 'appointment')
                    const SizedBox(height: 16),
                  
                  // Notes (optional for all types)
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: _selectedActivityType == 'meal' ? 'Description' : 'Notes (optional)',
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
                ],
              ),
            ),
          ),
          
          // Add Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  _addActivity();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B84DC),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  'Add ${_getActivityTypeLabel(_selectedActivityType)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Add this method to create activity type buttons
Widget _buildActivityTypeButton(String label, String type, IconData icon) {
  final bool isSelected = _selectedActivityType == type;
  final Color selectedColor = const Color(0xFF6B84DC);
  
  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedActivityType = type;
      });
    },
    child: Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey[600],
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? selectedColor : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

// Update the activity card to be more visually appealing
Widget _buildActivityCard(Map<String, dynamic> activity) {
  final Color backgroundColor = Color(activity['color']);
  final Color textColor = Color(activity['textColor']);
  final Color iconColor = Color(activity['iconColor']);
  
  IconData getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'event':
        return Icons.event;
      case 'directions_walk':
        return Icons.directions_walk;
      default:
        return Icons.event_note;
    }
  }

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6.0),
    elevation: 2,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: iconColor.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: InkWell(
      onTap: () {
        // Handle tap if needed
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getIconData(activity['icon']),
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (activity['isCompleted'])
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getActivityTypeLabel(activity['type']),
                    style: TextStyle(
                      fontSize: 12,
                      color: iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  // Helper methods for activity types
  String _getActivityTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'meal':
        return 'Meal';
      case 'appointment':
        return 'Appointment';
      case 'hobby':
        return 'Hobby';
      default:
        return 'Activity';
    }
  }

  String _getActivityNameLabel() {
    switch (_selectedActivityType) {
      case 'meal':
        return 'Meal Type';
      case 'appointment':
        return 'Appointment Title';
      case 'hobby':
        return 'Hobby Name';
      default:
        return 'Activity Name';
    }
  }

  String _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'meal':
        return 'restaurant';
      case 'appointment':
        return 'event';
      case 'hobby':
        return 'sports_esports';
      default:
        return 'directions_walk';
    }
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'meal':
        return Icons.restaurant;
      case 'appointment':
        return Icons.event;
      case 'hobby':
        return Icons.sports_esports;
      default:
        return Icons.directions_walk;
    }
  }

  Color _getActivityTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'meal':
        return Colors.orange;
      case 'appointment':
        return Colors.purple;
      case 'hobby':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.history,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'No activities recorded yet',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add activities using the button above',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
}

