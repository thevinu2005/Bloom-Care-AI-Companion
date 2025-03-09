import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bloom_care/screens/caregiver/medication_page.dart';
import 'package:bloom_care/screens/caregiver/elder_activities_feed.dart';
import 'package:bloom_care/widgets/navigation_bar_for_caregiver.dart';

class ElderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> elder;

  const ElderDetailsPage({Key? key, required this.elder}) : super(key: key);

  @override
  _ElderDetailsPageState createState() => _ElderDetailsPageState();
}

class _ElderDetailsPageState extends State<ElderDetailsPage> {
  late Map<String, dynamic> _elder;
  bool _isLoading = false;
  List<Map<String, dynamic>> _medications = [];
  Map<String, double>? _emotionData;
  String _currentEmotion = '';
  bool _isLoadingEmotions = true;
  String _lastEmotionUpdate = '';

  // New lists for daily activities
  List<Map<String, dynamic>> _mealPlans = [];
  List<Map<String, dynamic>> _hobbyTimes = [];
  List<Map<String, dynamic>> _appointments = [];

  // Add a new list for general activities
  List<Map<String, dynamic>> _generalActivities = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _elder = widget.elder;
    _loadElderDetails();
    _loadElderEmotions(); // Load emotion data from database
  }

// Add this method to the _ElderDetailsPageState class to load emotion data
Future<void> _loadElderEmotions() async {
  setState(() {
    _isLoadingEmotions = true;
  });

  try {
    print('Loading emotions for elder ID: ${_elder['id']}');
    
    // Get the most recent emotion record
    final emotionsSnapshot = await _firestore
        .collection('users')
        .doc(_elder['id'])
        .collection('emotions')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
        
    if (emotionsSnapshot.docs.isNotEmpty) {
      final emotionDoc = emotionsSnapshot.docs.first;
      final data = emotionDoc.data();
      
      // Extract emotion data
      final emotion = data['emotion'] as String;
      Map<String, double> probabilities = {};
      
      // Convert probabilities to proper double values
      if (data['probabilities'] != null) {
        final rawProbabilities = data['probabilities'] as Map<String, dynamic>;
        rawProbabilities.forEach((key, value) {
          // Convert to double and ensure it's a valid probability
          double probability = (value is double) ? value : 
                             (value is int) ? value.toDouble() : 0.0;
          probability = probability.clamp(0.0, 1.0); // Ensure value is between 0 and 1
          probabilities[key] = probability;
        });
      }
      
      final formattedTime = data['formattedTime'] as String? ?? 
          DateFormat('MMM d, h:mm a').format(
            (data['timestamp'] as Timestamp).toDate()
          );
      
      setState(() {
        _currentEmotion = emotion;
        _emotionData = probabilities;
        _lastEmotionUpdate = formattedTime;
        _isLoadingEmotions = false;
      });
      
      print('Loaded emotion data: $_currentEmotion');
      print('Probabilities: $_emotionData');
    } else {
      print('No emotion data found for elder');
      setState(() {
        _isLoadingEmotions = false;
      });
    }
  } catch (e) {
    print('Error loading elder emotions: $e');
    setState(() {
      _isLoadingEmotions = false;
    });
  }
}

// Add this method to build the emotion chart
Widget _buildEmotionChart() {
  if (_emotionData == null || _emotionData!.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'No emotion data available',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // Sort emotions by value
  final sortedEmotions = _emotionData!.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // Define emotion colors
  final emotionColors = {
    'happy': const Color(0xFFB5E6B3),
    'neutral': const Color(0xFFE6E6E6),
    'sad': const Color(0xFFB3C7E6),
    'fear': const Color(0xFFE6B3B3),
    'surprise': const Color(0xFFE6D5B3),
    'angry': const Color(0xFFE6B3D4),
    'calm': const Color(0xFFB3E6E6),
    'disgust': const Color(0xFFD5E6B3),
  };

  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Mood and Last Updated
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text(
                'Current Mood: ${_currentEmotion.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B6EC7),
                ),
              ),
              Text(
                'Last Updated: $_lastEmotionUpdate',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart and Legend
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: sortedEmotions.map((emotion) {
                        final color = emotionColors[emotion.key.toLowerCase()] ?? 
                                    Colors.grey[300]!;
                        return PieChartSectionData(
                          color: color,
                          value: emotion.value * 100,
                          title: '${(emotion.value * 100).toInt()}%',
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                          showTitle: emotion.value >= 0.1, // Only show labels for values >= 10%
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Legend
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: sortedEmotions.map((emotion) {
                          final color = emotionColors[emotion.key.toLowerCase()] ?? 
                                      Colors.grey[300]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    emotion.key,
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // Improved method to load elder details with better activity fetching
  // Update the _loadElderDetails method to also load activities
  Future<void> _loadElderDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Loading elder details for ID: ${_elder['id']}');
      
      // Load medications
      final medicationsSnapshot = await _firestore
          .collection('users')
          .doc(_elder['id'])
          .collection('medicines')
          .limit(5)
          .get();
          
      final meds = medicationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown medication',
          'dosage': data['dosage'] ?? '',
          'schedule': data['schedule'] ?? [],
          'instructions': data['instructions'] ?? '',
        };
      }).toList();
      
      print('Loaded ${meds.length} medications');
      
      // Update the collections we're querying in _loadElderDetails
      // Add these sections after loading medications

      // Load activities from multiple collections
      print('Loading activities for elder ID: ${_elder['id']}');

      // Try to load meal plans from multiple possible collections
      try {
        final mealCollections = ['meal_plans', 'meals', 'meal'];
        bool foundMeals = false;
        
        for (final collection in mealCollections) {
          if (foundMeals) break;
          
          final mealSnapshot = await _firestore
              .collection('users')
              .doc(_elder['id'])
              .collection(collection)
              .orderBy('time', descending: false)
              .limit(3)
              .get();
              
          if (mealSnapshot.docs.isNotEmpty) {
            print('Found ${mealSnapshot.docs.length} meals in $collection collection');
            final meals = mealSnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'time': data['time'] ?? '',
                'mealType': data['mealType'] ?? data['type'] ?? 'Meal',
                'description': data['description'] ?? data['name'] ?? '',
                'isCompleted': data['isCompleted'] ?? false,
              };
            }).toList();
            
            setState(() {
              _mealPlans = meals;
            });
            
            foundMeals = true;
          }
        }
      } catch (e) {
        print('Error loading meal plans: $e');
      }

      // Try to load hobbies from multiple possible collections
      try {
        final hobbyCollections = ['hobby_times', 'hobbies', 'hobby'];
        bool foundHobbies = false;
        
        for (final collection in hobbyCollections) {
          if (foundHobbies) break;
          
          final hobbySnapshot = await _firestore
              .collection('users')
              .doc(_elder['id'])
              .collection(collection)
              .limit(3)
              .get();
              
          if (hobbySnapshot.docs.isNotEmpty) {
            print('Found ${hobbySnapshot.docs.length} hobbies in $collection collection');
            final hobbies = hobbySnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'time': data['time'] ?? '',
                'activity': data['activity'] ?? data['name'] ?? 'Hobby',
                'duration': data['duration'] ?? '30 minutes',
                'isCompleted': data['isCompleted'] ?? false,
              };
            }).toList();
            
            setState(() {
              _hobbyTimes = hobbies;
            });
            
            foundHobbies = true;
          }
        }
      } catch (e) {
        print('Error loading hobbies: $e');
      }

      // Try to load appointments from multiple possible collections
      try {
        final appointmentCollections = ['appointments', 'appointment', 'events'];
        bool foundAppointments = false;
        
        for (final collection in appointmentCollections) {
          if (foundAppointments) break;
          
          final appointmentSnapshot = await _firestore
              .collection('users')
              .doc(_elder['id'])
              .collection(collection)
              .limit(3)
              .get();
              
          if (appointmentSnapshot.docs.isNotEmpty) {
            print('Found ${appointmentSnapshot.docs.length} appointments in $collection collection');
            final appointments = appointmentSnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'date': data['date'] ?? DateFormat('MMM dd, yyyy').format(DateTime.now()),
                'time': data['time'] ?? '',
                'title': data['title'] ?? data['name'] ?? 'Appointment',
                'location': data['location'] ?? '',
                'isConfirmed': data['isConfirmed'] ?? true,
              };
            }).toList();
            
            setState(() {
              _appointments = appointments;
            });
            
            foundAppointments = true;
          }
        }
      } catch (e) {
        print('Error loading appointments: $e');
      }
      
      // Add this to the _loadElderDetails method
      // Try to load general activities
      try {
        final activitySnapshot = await _firestore
            .collection('users')
            .doc(_elder['id'])
            .collection('activities')
            .limit(5)
            .get();
            
        if (activitySnapshot.docs.isNotEmpty) {
          print('Found ${activitySnapshot.docs.length} general activities');
          final activities = activitySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Activity',
              'category': data['category'] ?? 'Other',
              'time': data['time'] ?? '',
              'duration': data['duration'] ?? '',
              'notes': data['notes'] ?? '',
              'isCompleted': data['isCompleted'] ?? false,
            };
          }).toList();
          
          setState(() {
            _generalActivities = activities;
          });
          
          // If we have general activities but no specific ones, use them
          if (_mealPlans.isEmpty && _hobbyTimes.isEmpty && _appointments.isEmpty) {
            // Convert general activities to specific types based on category
            for (final activity in activities) {
              final category = activity['category'].toString().toLowerCase();
              
              if (category.contains('meal') || category.contains('food') || category.contains('eat')) {
                _mealPlans.add({
                  'id': activity['id'],
                  'time': activity['time'],
                  'mealType': activity['name'],
                  'description': activity['notes'],
                  'isCompleted': activity['isCompleted'],
                });
              } else if (category.contains('hobby') || category.contains('leisure')) {
                _hobbyTimes.add({
                  'id': activity['id'],
                  'time': activity['time'],
                  'activity': activity['name'],
                  'duration': activity['duration'],
                  'isCompleted': activity['isCompleted'],
                });
              } else if (category.contains('appointment') || category.contains('meeting')) {
                _appointments.add({
                  'id': activity['id'],
                  'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  'time': activity['time'],
                  'title': activity['name'],
                  'location': activity['notes'],
                  'isConfirmed': true,
                });
              }
            }
          }
        }
      } catch (e) {
        print('Error loading general activities: $e');
      }
      
      // If no data was loaded, add sample data
      if (_mealPlans.isEmpty) {
        _mealPlans.addAll([
          {
            'id': 'sample1',
            'time': '7:30 AM',
            'mealType': 'Breakfast',
            'description': 'Oatmeal with fruits',
            'isCompleted': false,
          },
          {
            'id': 'sample2',
            'time': '12:00 PM',
            'mealType': 'Lunch',
            'description': 'Grilled chicken salad',
            'isCompleted': false,
          },
        ]);
      }
      
      if (_hobbyTimes.isEmpty) {
        _hobbyTimes.addAll([
          {
            'id': 'sample1',
            'time': '9:00 AM',
            'activity': 'Reading',
            'duration': '30 minutes',
            'isCompleted': false,
          },
          {
            'id': 'sample2',
            'time': '3:00 PM',
            'activity': 'Walking',
            'duration': '45 minutes',
            'isCompleted': false,
          },
        ]);
      }
      
      if (_appointments.isEmpty) {
        _appointments.addAll([
          {
            'id': 'sample1',
            'date': DateFormat('MMM dd, yyyy').format(DateTime.now().add(const Duration(days: 2))),
            'time': '10:00 AM',
            'title': 'Doctor Appointment',
            'location': 'City Medical Center',
            'isConfirmed': true,
          },
        ]);
      }
      
      setState(() {
        _medications = meds;
        _isLoading = false;
      });
      
      print('Updated state with ${_medications.length} medications, ${_mealPlans.length} meals, ${_hobbyTimes.length} hobbies, and ${_appointments.length} appointments');
    } catch (e) {
      print('Error loading elder details: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this method to navigate to the activity feed
  void _viewAllActivities() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ElderActivityFeed(elderId: _elder['id']),
      ),
    );
  }

  // Add this method to navigate to the emotion check page
  

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (name.length > 1) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return name.toUpperCase();
    }
  }

  // Update the build method to add the activity feed section
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_elder['name']} - Details'),
        backgroundColor: const Color(0xFF8B9FE8),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadElderDetails();
              _loadElderEmotions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B9FE8),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFEEF1FF),
                          backgroundImage: _elder['profileImage'] != 'assets/default_avatar.png'
                              ? AssetImage(_elder['profileImage'])
                              : null,
                          child: _elder['profileImage'] == 'assets/default_avatar.png'
                              ? Text(
                                  _getInitials(_elder['name']),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B9FE8),
                                  ),
                                )
                              : null,
                        ),
                        // Mood indicator
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getMoodEmoji(_elder['mood']),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Current mood
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getMoodColor(_elder['mood']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Current mood: ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            _elder['mood'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getMoodColor(_elder['mood']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information Card
                  _buildDetailsCard(
                    title: 'Personal Information',
                    children: [
                      _buildDetailRow('Full Name', _elder['name']),
                      _buildDetailRow('Age', '${_elder['age']} years'),
                      _buildDetailRow('Phone', _elder['phone']),
                      _buildDetailRow('Address', _elder['address']),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Emotional State Card - NEW SECTION
                  _buildDetailsCard(
                    title: 'Emotional State',
                    children: [
                      _isLoadingEmotions
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _buildEmotionChart(),
                    ],
                    // Remove the actionText and onActionPressed parameters
                  ),

                  const SizedBox(height: 16),

                  // Medications Card
                  _buildDetailsCard(
                    title: 'Medications',
                    children: _medications.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  'No medications found',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ]
                        : _medications.map((med) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                med['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${med['dosage']} - ${med['instructions']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.medication,
                                color: Color(0xFF8B9FE8),
                              ),
                            );
                          }).toList(),
                    actionText: 'View All Medications',
                    onActionPressed: () {
                      print('Navigating to medications page for elder: ${_elder['name']} (ID: ${_elder['id']})');
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MedicinePage(elderId: _elder['id'])),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Daily Activities Card
                  _buildDetailsCard(
                    title: 'Daily Activities',
                    children: [
                      _buildActivityPreview(),
                    ],
                    actionText: 'Manage Activities',
                    onActionPressed: () {
                      print('Navigating to activities page for elder: ${_elder['name']} (ID: ${_elder['id']})');
                      
                      // Check if we have the ElderActivitiesPage component
                      try {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => ElderActivitiesPage(elderId: _elder['id'])),
                        );
                      } catch (e) {
                        // Fallback to DailyActivitiesPage if ElderActivitiesPage is not available
                        print('Falling back to DailyActivitiesPage: $e');
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => ElderActivityFeed(elderId: _elder['id'])),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildQuickActionsSection(context),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNav_for_caregivers(currentIndex: -1),
    );
  }

  // Update the Quick Actions section to include the Activity Feed
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MedicinePage(elderId: _elder['id'])),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.directions_walk,
                  label: 'Activities',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ElderActivitiesPage(elderId: _elder['id']),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add the missing _buildQuickActionButton method inside the _ElderDetailsPageState class
  // Add this method right after the _buildQuickActionsSection method
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
            size: 28,
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

  Widget _buildActivitySectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF8B9FE8),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5B6EC7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanItem(Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                meal['time'].substring(0, 2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B6EC7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['mealType'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: meal['isCompleted'] ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${meal['time']} - ${meal['description']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    decoration: meal['isCompleted'] ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          if (meal['isCompleted'])
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildHobbyTimeItem(Map<String, dynamic> hobby) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getHobbyIcon(hobby['activity']),
                color: const Color(0xFF5B6EC7),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hobby['activity'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: hobby['isCompleted'] ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${hobby['time']} - ${hobby['duration']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    decoration: hobby['isCompleted'] ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          if (hobby['isCompleted'])
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(Map<String, dynamic> appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.event,
                color: Color(0xFF5B6EC7),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${appointment['date']} at ${appointment['time']} - ${appointment['location']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: appointment['isConfirmed'] 
                  ? const Color(0xFFEEF1FF)
                  : Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              appointment['isConfirmed'] ? 'Confirmed' : 'Pending',
              style: TextStyle(
                fontSize: 10,
                color: appointment['isConfirmed'] 
                    ? const Color(0xFF5B6EC7)
                    : Colors.amber[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get icon for hobby
  IconData _getHobbyIcon(String activity) {
    switch (activity.toLowerCase()) {
      case 'reading':
        return Icons.book;
      case 'walking':
        return Icons.directions_walk;
      case 'painting':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      case 'gardening':
        return Icons.eco;
      default:
        return Icons.sports_esports;
    }
  }

  Widget _buildDetailsCard({
    required String title,
    required List<Widget> children,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B6EC7),
                  ),
                ),
              ),
              if (actionText != null && onActionPressed != null)
                TextButton(
                  onPressed: onActionPressed,
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      color: Color(0xFF8B9FE8),
                    ),
                  ),
                ),
            ],
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

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'relaxed':
      case 'calm':
        return Colors.blue;
      case 'tired':
      case 'sleepy':
        return Colors.orange;
      case 'stressed':
      case 'anxious':
      case 'sad':
        return Colors.red;
      case 'lonely':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'relaxed':
      case 'calm':
        return '😌';
      case 'tired':
      case 'sleepy':
        return '😴';
      case 'stressed':
      case 'anxious':
        return '😰';
      case 'sad':
        return '😢';
      case 'lonely':
        return '😔';
      default:
        return '😐';
    }
  }

  // Add this method to create a more direct activity display
  Widget _buildActivityPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meal Plans Section
        if (_mealPlans.isNotEmpty) ...[
          _buildActivitySectionHeader('Meal Plans', Icons.restaurant),
          ..._mealPlans.take(2).map((meal) => _buildMealPlanItem(meal)).toList(),
        ],
        
        const SizedBox(height: 12),
        
        // Hobby Times Section
        if (_hobbyTimes.isNotEmpty) ...[
          _buildActivitySectionHeader('Hobby Times', Icons.sports_esports),
          ..._hobbyTimes.take(2).map((hobby) => _buildHobbyTimeItem(hobby)).toList(),
        ],
        
        const SizedBox(height: 12),
        
        // Appointments Section
        if (_appointments.isNotEmpty) ...[
          _buildActivitySectionHeader('Appointments', Icons.event),
          ..._appointments.take(1).map((appointment) => _buildAppointmentItem(appointment)).toList(),
        ],
        
        // If no activities found
        if (_mealPlans.isEmpty && _hobbyTimes.isEmpty && _appointments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'No daily activities found',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Add this class definition if it doesn't exist
class ElderActivitiesPage extends StatelessWidget {
  final String elderId;
  
  const ElderActivitiesPage({Key? key, required this.elderId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElderActivityFeed(elderId: elderId);
  }
}

