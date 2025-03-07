import 'package:flutter/material.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bloom_care/services/notification_service.dart';

class DailyActivitiesPage extends StatefulWidget {
  const DailyActivitiesPage({super.key});

  @override
  State<DailyActivitiesPage> createState() => _DailyActivitiesPageState();
}

class _DailyActivitiesPageState extends State<DailyActivitiesPage> {
  // Lists to store activities
  List<MealPlan> mealPlans = [];
  List<HobbyTime> hobbyTimes = [];
  List<Appointment> appointments = [];
  
  // Loading state
  bool _isLoading = true;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Load data when the page is initialized
    _loadData();
  }

  // Load data from Firestore
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Clear existing data
      mealPlans.clear();
      hobbyTimes.clear();
      appointments.clear();

      // Load meal plans
      final mealPlansSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meal_plans')
          .get();

      for (var doc in mealPlansSnapshot.docs) {
        final data = doc.data();
        mealPlans.add(MealPlan(
          time: data['time'] ?? '',
          mealType: data['mealType'] ?? '',
          description: data['description'] ?? '',
          isCompleted: data['isCompleted'] ?? false,
          id: doc.id, // Store document ID for updates
        ));
      }

      // Load hobby times
      final hobbyTimesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('hobby_times')
          .get();

      for (var doc in hobbyTimesSnapshot.docs) {
        final data = doc.data();
        hobbyTimes.add(HobbyTime(
          time: data['time'] ?? '',
          activity: data['activity'] ?? '',
          duration: data['duration'] ?? '',
          isCompleted: data['isCompleted'] ?? false,
          id: doc.id, // Store document ID for updates
        ));
      }

      // Load appointments
      final appointmentsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .get();

      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        appointments.add(Appointment(
          date: data['date'] ?? '',
          time: data['time'] ?? '',
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          isConfirmed: data['isConfirmed'] ?? false,
          id: doc.id, // Store document ID for updates
        ));
      }

      // If no data was loaded, add sample data (optional)
      if (mealPlans.isEmpty) {
        mealPlans = [
          MealPlan(
            time: "7:30 AM",
            mealType: "Breakfast",
            description: "Oatmeal with fruits",
            isCompleted: false,
          ),
          MealPlan(
            time: "12:00 PM",
            mealType: "Lunch",
            description: "Grilled chicken salad",
            isCompleted: false,
          ),
          MealPlan(
            time: "6:30 PM",
            mealType: "Dinner",
            description: "Salmon with vegetables",
            isCompleted: false,
          ),
        ];
      }

      if (hobbyTimes.isEmpty) {
        hobbyTimes = [
          HobbyTime(
            time: "9:00 AM",
            activity: "Reading",
            duration: "30 minutes",
            isCompleted: false,
          ),
          HobbyTime(
            time: "3:00 PM",
            activity: "Walking",
            duration: "45 minutes",
            isCompleted: false,
          ),
          HobbyTime(
            time: "8:00 PM",
            activity: "Painting",
            duration: "60 minutes",
            isCompleted: false,
          ),
        ];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Save a single meal plan to Firestore
  Future<void> _saveMealPlan(MealPlan meal) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // If the meal has an ID, update it, otherwise add a new one
      if (meal.id != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('meal_plans')
            .doc(meal.id)
            .update({
          'time': meal.time,
          'mealType': meal.mealType,
          'description': meal.description,
          'isCompleted': meal.isCompleted,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new meal and update the ID
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('meal_plans')
            .add({
          'time': meal.time,
          'mealType': meal.mealType,
          'description': meal.description,
          'isCompleted': meal.isCompleted,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Update the meal with the new ID
        meal.id = docRef.id;
      }
    } catch (e) {
      print('Error saving meal plan: $e');
      throw e;
    }
  }

  // Save a single hobby time to Firestore
  Future<void> _saveHobbyTime(HobbyTime hobby) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // If the hobby has an ID, update it, otherwise add a new one
      if (hobby.id != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('hobby_times')
            .doc(hobby.id)
            .update({
          'time': hobby.time,
          'activity': hobby.activity,
          'duration': hobby.duration,
          'isCompleted': hobby.isCompleted,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new hobby and update the ID
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('hobby_times')
            .add({
          'time': hobby.time,
          'activity': hobby.activity,
          'duration': hobby.duration,
          'isCompleted': hobby.isCompleted,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Update the hobby with the new ID
        hobby.id = docRef.id;
      }
    } catch (e) {
      print('Error saving hobby time: $e');
      throw e;
    }
  }

  // Save a single appointment to Firestore
  Future<void> _saveAppointment(Appointment appointment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // If the appointment has an ID, update it, otherwise add a new one
      if (appointment.id != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('appointments')
            .doc(appointment.id)
            .update({
          'date': appointment.date,
          'time': appointment.time,
          'title': appointment.title,
          'location': appointment.location,
          'isConfirmed': appointment.isConfirmed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new appointment and update the ID
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('appointments')
            .add({
          'date': appointment.date,
          'time': appointment.time,
          'title': appointment.title,
          'location': appointment.location,
          'isConfirmed': appointment.isConfirmed,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Update the appointment with the new ID
        appointment.id = docRef.id;
      }
    } catch (e) {
      print('Error saving appointment: $e');
      throw e;
    }
  }

  // Delete a meal plan from Firestore
  Future<void> _deleteMealPlan(MealPlan meal) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Only delete from Firestore if it has an ID
      if (meal.id != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('meal_plans')
            .doc(meal.id)
            .delete();
      }
      
      // Remove from local list
      setState(() {
        mealPlans.remove(meal);
      });
    } catch (e) {
      print('Error deleting meal plan: $e');
      throw e;
    }
  }

  // Delete a hobby time from Firestore
  Future<void> _deleteHobbyTime(HobbyTime hobby) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Only delete from Firestore if it has an ID
      if (hobby.id != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('hobby_times')
            .doc(hobby.id)
            .delete();
      }
      
      // Remove from local list
      setState(() {
        hobbyTimes.remove(hobby);
      });
    } catch (e) {
      print('Error deleting hobby time: $e');
      throw e;
    }
  }

  // Delete an appointment from Firestore
  Future<void> _deleteAppointment(Appointment appointment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Only delete from Firestore if it has an ID
      if (appointment.id != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('appointments')
            .doc(appointment.id)
            .delete();
      }
      
      // Remove from local list
      setState(() {
        appointments.remove(appointment);
      });
    } catch (e) {
      print('Error deleting appointment: $e');
      throw e;
    }
  }

  // Save changes to local storage and Firestore
  Future<void> _saveChanges() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Save all meal plans
      for (var meal in mealPlans) {
        await _saveMealPlan(meal);
      }

      // Save all hobby times
      for (var hobby in hobbyTimes) {
        await _saveHobbyTime(hobby);
      }

      // Save all appointments
      for (var appointment in appointments) {
        await _saveAppointment(appointment);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily activities saved successfully!'),
          backgroundColor: Color(0xFF8FA2E6),
        ),
      );
    } catch (e) {
      print('Error saving activities: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving activities: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Send notification to user
  Future<void> _sendNotification(String type, String title, String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Determine notification color and icon based on type
      Color notificationColor;
      Color textColor;
      String iconString;

      switch (type) {
        case 'meal':
          notificationColor = const Color(0xFFD1ECF1);
          textColor = const Color(0xFF0C5460);
          iconString = 'restaurant';
          break;
        case 'hobby':
          notificationColor = const Color(0xFFFFF3CD);
          textColor = const Color(0xFF856404);
          iconString = 'sports_esports';
          break;
        case 'appointment':
          notificationColor = const Color(0xFFE2D9F3);
          textColor = const Color(0xFF6A359C);
          iconString = 'event';
          break;
        default:
          notificationColor = const Color(0xFFD1ECF1);
          textColor = const Color(0xFF0C5460);
          iconString = 'notifications';
      }

      // 1. Create notification for the elder
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'type': type,
        'title': title,
        'message': message,
        'color': notificationColor.value,
        'textColor': textColor.value,
        'icon': iconString,
        'iconColor': const Color(0xFF6B84DC).value,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 2. Send notification to assigned caregiver if available
      await _notifyCaregiverAboutActivity(type, title, message);

      print('Notification sent: $title - $message');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Updated method to notify the caregiver about elder activities using NotificationService
  Future<void> _notifyCaregiverAboutActivity(String type, String title, String message) async {
    try {
      // Extract activity details from the message
      String activityName = '';
      String activityDetails = '';
      
      // Parse the message to extract relevant information
      if (type == 'meal') {
        // For meal notifications, format: "You have added [MealType] at [Time]"
        if (message.contains('added')) {
          final parts = message.replaceFirst('You have added ', '').split(' at ');
          if (parts.length >= 2) {
            activityName = parts[0]; // Meal type
            activityDetails = 'at ${parts[1]}'; // Time
          }
        }
      } else if (type == 'hobby') {
        // For hobby notifications, format: "You have added [Activity] at [Time] for [Duration]"
        if (message.contains('added')) {
          final parts = message.replaceFirst('You have added ', '').split(' at ');
          if (parts.length >= 2) {
            activityName = parts[0]; // Activity name
            activityDetails = 'at ${parts[1]}'; // Time and duration
          }
        }
      } else if (type == 'appointment') {
        // For appointment notifications, format: "You have added [Title] on [Date] at [Time]"
        if (message.contains('added')) {
          final parts = message.replaceFirst('You have added ', '').split(' on ');
          if (parts.length >= 2) {
            activityName = parts[0]; // Appointment title
            activityDetails = 'on ${parts[1]}'; // Date and time
          }
        }
      }
      
      // Use the notification service to send the notification to caregiver
      await _notificationService.notifyCaregiverAboutElderActivity(
        activityType: type,
        activityName: activityName,
        activityDetails: activityDetails,
      );
      
    } catch (e) {
      print('Error sending notification to caregiver: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD7E0FA), // Light blue background
      appBar: AppBar(
        backgroundColor: Color(0xFF8FA2E6), // App bar color
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Daily Activities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildDailyActivitiesContent(),
      bottomNavigationBar: const BottomNav(currentIndex: 0), // Added BottomNav with currentIndex 0
    );
  }

  // Daily activities content
  Widget _buildDailyActivitiesContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with curved bottom
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF8FA2E6),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Today, ${_getFormattedDate()}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // Meal Planning Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Meal Plan', Icons.restaurant),
                const SizedBox(height: 15),
                ...mealPlans.map((meal) => _buildMealItem(meal)).toList(),

                // Add meal button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    onTap: () {
                      // Add functionality to add new meal
                      _addNewMeal();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF8FA2E6), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Color(0xFF8FA2E6)),
                          SizedBox(width: 5),
                          Text(
                            'Add Meal',
                            style: TextStyle(
                              color: Color(0xFF8FA2E6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Hobby Time Section
                _buildSectionHeader('Hobby Time', Icons.sports_esports),
                const SizedBox(height: 15),
                ...hobbyTimes.map((hobby) => _buildHobbyItem(hobby)).toList(),

                // Add hobby time button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    onTap: () {
                      // Add functionality to add new hobby time
                      _addNewHobby();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF8FA2E6), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Color(0xFF8FA2E6)),
                          SizedBox(width: 5),
                          Text(
                            'Add Hobby Time',
                            style: TextStyle(
                              color: Color(0xFF8FA2E6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Upcoming Appointments Section
                _buildSectionHeader('Upcoming Appointments', Icons.event),
                const SizedBox(height: 15),
                ...appointments.map((appointment) => _buildAppointmentItem(appointment)).toList(),

                // Add appointment button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    onTap: () {
                      // Add functionality to add new appointment
                      _addNewAppointment();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF8FA2E6), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Color(0xFF8FA2E6)),
                          SizedBox(width: 5),
                          Text(
                            'Add Appointment',
                            style: TextStyle(
                              color: Color(0xFF8FA2E6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add new meal with notification
  void _addNewMeal() {
    TextEditingController timeController = TextEditingController(text: "");
    TextEditingController typeController = TextEditingController(text: "");
    TextEditingController descController = TextEditingController(text: "");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Meal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (timeController.text.isNotEmpty && 
                    typeController.text.isNotEmpty && 
                    descController.text.isNotEmpty) {
                  
                  final newMeal = MealPlan(
                    time: timeController.text,
                    mealType: typeController.text,
                    description: descController.text,
                    isCompleted: false,
                  );
                  
                  setState(() {
                    mealPlans.add(newMeal);
                  });
                  
                  // Save the new meal to Firestore immediately
                  try {
                    await _saveMealPlan(newMeal);
                    
                    // Send notification to elder
                    await _sendNotification(
                      'meal',
                      'New Meal Added',
                      'You have added ${typeController.text} at ${timeController.text}',
                    );
                    
                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${typeController.text} added to your meal plan'),
                          backgroundColor: const Color(0xFF8FA2E6),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error saving new meal: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving meal: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  
                  Navigator.of(context).pop();
                } else {
                  // Show error for empty fields
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Add new hobby with notification
  void _addNewHobby() {
    TextEditingController timeController = TextEditingController(text: "");
    TextEditingController activityController = TextEditingController(text: "");
    TextEditingController durationController = TextEditingController(text: "");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Hobby Time'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: activityController,
                  decoration: const InputDecoration(
                    labelText: 'Activity',
                    prefixIcon: Icon(Icons.sports_esports),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    prefixIcon: Icon(Icons.timer),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (timeController.text.isNotEmpty && 
                    activityController.text.isNotEmpty && 
                    durationController.text.isNotEmpty) {
                  
                  final newHobby = HobbyTime(
                    time: timeController.text,
                    activity: activityController.text,
                    duration: durationController.text,
                    isCompleted: false,
                  );
                  
                  setState(() {
                    hobbyTimes.add(newHobby);
                  });
                  
                  // Save the new hobby to Firestore immediately
                  try {
                    await _saveHobbyTime(newHobby);
                    
                    // Send notification
                    await _sendNotification(
                      'hobby',
                      'New Hobby Added',
                      'You have added ${activityController.text} at ${timeController.text} for ${durationController.text}',
                    );
                    
                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${activityController.text} added to your hobby schedule'),
                          backgroundColor: const Color(0xFF8FA2E6),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error saving new hobby: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving hobby: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  
                  Navigator.of(context).pop();
                } else {
                  // Show error for empty fields
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Add new appointment with notification
  void _addNewAppointment() {
    TextEditingController dateController = TextEditingController(text: "");
    TextEditingController timeController = TextEditingController(text: "");
    TextEditingController titleController = TextEditingController(text: "");
    TextEditingController locationController = TextEditingController(text: "");
    bool isConfirmed = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Text('Confirmed:'),
                        const SizedBox(width: 10),
                        Switch(
                          value: isConfirmed,
                          activeColor: const Color(0xFF8FA2E6),
                          onChanged: (value) {
                            setState(() {
                              isConfirmed = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    if (dateController.text.isNotEmpty && 
                        timeController.text.isNotEmpty && 
                        titleController.text.isNotEmpty && 
                        locationController.text.isNotEmpty) {
                      
                      final newAppointment = Appointment(
                        date: dateController.text,
                        time: timeController.text,
                        title: titleController.text,
                        location: locationController.text,
                        isConfirmed: isConfirmed,
                      );
                      
                      this.setState(() {
                        appointments.add(newAppointment);
                      });
                      
                      // Save the new appointment to Firestore immediately
                      try {
                        await _saveAppointment(newAppointment);
                        
                        // Send notification
                        await _sendNotification(
                          'appointment',
                          'New Appointment Added',
                          'You have added ${titleController.text} on ${dateController.text} at ${timeController.text}',
                        );
                        
                        // Show success message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${titleController.text} added to your appointments'),
                              backgroundColor: const Color(0xFF8FA2E6),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error saving new appointment: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving appointment: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      
                      Navigator.of(context).pop();
                    } else {
                      // Show error for empty fields
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to format current date
  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // Section header widget
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8FA2E6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D77D6),
          ),
        ),
      ],
    );
  }

  // Meal item widget
  Widget _buildMealItem(MealPlan meal) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteMealPlan(meal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal plan deleted'),
            backgroundColor: Color(0xFF8FA2E6),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E0FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant,
              color: Color(0xFF8FA2E6),
            ),
          ),
          title: Text(
            meal.mealType,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D77D6),
            ),
          ),
          subtitle: Text(
            '${meal.time} - ${meal.description}',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: meal.isCompleted,
                activeColor: const Color(0xFF8FA2E6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (bool? value) {
                  setState(() {
                    meal.isCompleted = value ?? false;
                  });
                  // Update in Firestore
                  if (meal.id != null) {
                    _saveMealPlan(meal);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[300]),
                onPressed: () {
                  _showDeleteConfirmationDialog(
                    context,
                    'Delete Meal',
                    'Are you sure you want to delete this meal plan?',
                    () {
                      _deleteMealPlan(meal);
                    },
                  );
                },
              ),
            ],
          ),
          onTap: () {
            // Open edit dialog or screen
            _editMealPlan(meal);
          },
        ),
      ),
    );
  }

  // Hobby item widget
  Widget _buildHobbyItem(HobbyTime hobby) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteHobbyTime(hobby);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hobby time deleted'),
            backgroundColor: Color(0xFF8FA2E6),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E0FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sports_esports,
              color: Color(0xFF8FA2E6),
            ),
          ),
          title: Text(
            hobby.activity,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D77D6),
            ),
          ),
          subtitle: Text(
            '${hobby.time} - ${hobby.duration}',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: hobby.isCompleted,
                activeColor: const Color(0xFF8FA2E6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (bool? value) {
                  setState(() {
                    hobby.isCompleted = value ?? false;
                  });
                  // Update in Firestore
                  if (hobby.id != null) {
                    _saveHobbyTime(hobby);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[300]),
                onPressed: () {
                  _showDeleteConfirmationDialog(
                    context,
                    'Delete Hobby',
                    'Are you sure you want to delete this hobby time?',
                    () {
                      _deleteHobbyTime(hobby);
                    },
                  );
                },
              ),
            ],
          ),
          onTap: () {
            // Open edit dialog or screen
            _editHobbyTime(hobby);
          },
        ),
      ),
    );
  }

  // Appointment item widget
  Widget _buildAppointmentItem(Appointment appointment) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteAppointment(appointment);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment deleted'),
            backgroundColor: Color(0xFF8FA2E6),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E0FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event,
              color: Color(0xFF8FA2E6),
            ),
          ),
          title: Text(
            appointment.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D77D6),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${appointment.date} at ${appointment.time}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                appointment.location,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: appointment.isConfirmed
                      ? const Color(0xFFD7E0FA)
                      : Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  appointment.isConfirmed ? 'Confirmed' : 'Pending',
                  style: TextStyle(
                    color: appointment.isConfirmed
                        ? const Color(0xFF5D77D6)
                        : Colors.amber[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[300]),
                onPressed: () {
                  _showDeleteConfirmationDialog(
                    context,
                    'Delete Appointment',
                    'Are you sure you want to delete this appointment?',
                    () {
                      _deleteAppointment(appointment);
                    },
                  );
                },
              ),
            ],
          ),
          onTap: () {
            // Open edit dialog or screen
            _editAppointment(appointment);
          },
        ),
      ),
    );
  }

  // Delete confirmation dialog
  void _showDeleteConfirmationDialog(BuildContext context, String title, String message, Function onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Edit meal plan dialog
  void _editMealPlan(MealPlan meal) {
    TextEditingController timeController = TextEditingController(text: meal.time);
    TextEditingController typeController = TextEditingController(text: meal.mealType);
    TextEditingController descController = TextEditingController(text: meal.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Meal Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                setState(() {
                  meal.time = timeController.text;
                  meal.mealType = typeController.text;
                  meal.description = descController.text;
                });
                
                // Save changes to Firestore
                try {
                  await _saveMealPlan(meal);
                  
                  // Send notification for edit
                  await _sendNotification(
                    'meal',
                    'Meal Plan Updated',
                    'You have updated ${typeController.text} at ${timeController.text}',
                  );
                } catch (e) {
                  print('Error updating meal: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating meal: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Edit hobby time dialog
  void _editHobbyTime(HobbyTime hobby) {
    TextEditingController timeController = TextEditingController(text: hobby.time);
    TextEditingController activityController = TextEditingController(text: hobby.activity);
    TextEditingController durationController = TextEditingController(text: hobby.duration);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Hobby Time'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: activityController,
                  decoration: const InputDecoration(
                    labelText: 'Activity',
                    prefixIcon: Icon(Icons.sports_esports),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    prefixIcon: Icon(Icons.timer),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                setState(() {
                  hobby.time = timeController.text;
                  hobby.activity = activityController.text;
                  hobby.duration = durationController.text;
                });
                
                // Save changes to Firestore
                try {
                  await _saveHobbyTime(hobby);
                  
                  // Send notification for edit
                  await _sendNotification(
                    'hobby',
                    'Hobby Time Updated',
                    'You have updated ${activityController.text} at ${timeController.text}',
                  );
                } catch (e) {
                  print('Error updating hobby: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating hobby: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Edit appointment dialog
  void _editAppointment(Appointment appointment) {
    TextEditingController dateController = TextEditingController(text: appointment.date);
    TextEditingController timeController = TextEditingController(text: appointment.time);
    TextEditingController titleController = TextEditingController(text: appointment.title);
    TextEditingController locationController = TextEditingController(text: appointment.location);
    bool isConfirmed = appointment.isConfirmed;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Text('Confirmed:'),
                        const SizedBox(width: 10),
                        Switch(
                          value: isConfirmed,
                          activeColor: const Color(0xFF8FA2E6),
                          onChanged: (value) {
                            setState(() {
                              isConfirmed = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    this.setState(() {
                      appointment.date = dateController.text;
                      appointment.time = timeController.text;
                      appointment.title = titleController.text;
                      appointment.location = locationController.text;
                      appointment.isConfirmed = isConfirmed;
                    });
                    
                    // Save changes to Firestore
                    try {
                      await _saveAppointment(appointment);
                      
                      // Send notification for edit
                      await _sendNotification(
                        'appointment',
                        'Appointment Updated',
                        'You have updated ${titleController.text} on ${dateController.text}',
                      );
                    } catch (e) {
                      print('Error updating appointment: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating appointment: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Meal Plan data class
class MealPlan {
  String time;
  String mealType;
  String description;
  bool isCompleted;
  String? id; // Document ID for Firestore

  MealPlan({
    required this.time,
    required this.mealType,
    required this.description,
    required this.isCompleted,
    this.id,
  });
}

// Hobby Time data class
class HobbyTime {
  String time;
  String activity;
  String duration;
  bool isCompleted;
  String? id; // Document ID for Firestore

  HobbyTime({
    required this.time,
    required this.activity,
    required this.duration,
    required this.isCompleted,
    this.id,
  });
}

// Appointment data class
class Appointment {
  String date;
  String time;
  String title;
  String location;
  bool isConfirmed;
  String? id; // Document ID for Firestore

  Appointment({
    required this.date,
    required this.time,
    required this.title,
    required this.location,
    required this.isConfirmed,
    this.id,
  });
}