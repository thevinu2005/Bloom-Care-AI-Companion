import 'package:flutter/material.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HobbiesPage extends StatefulWidget {
  const HobbiesPage({super.key});

  @override
  State<HobbiesPage> createState() => _HobbiesPageState();
}

class _HobbiesPageState extends State<HobbiesPage> {
  String activeTab = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> hobbies = [];
  List<String> userFavorites = [];
  String userName = 'User';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data including hobbies and favorites
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user profile data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data()!;
      
      // Get user's name
      final name = userData['name'] as String? ?? 'User';
      
      // Get user's hobbies from profile
      final userHobbies = List<String>.from(userData['hobbies'] ?? []);
      
      // Get user's favorites from profile
      final favorites = List<String>.from(userData['favorites'] ?? []);

      // Get user's hobby activity data
      final hobbiesCollection = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('hobbies')
          .get();

      final List<Map<String, dynamic>> hobbyList = [];

      // If user has hobby activity data, use it
      if (hobbiesCollection.docs.isNotEmpty) {
        for (var doc in hobbiesCollection.docs) {
          hobbyList.add({
            'id': doc.id,
            'name': doc.data()['name'] ?? 'Unknown',
            'frequency': doc.data()['frequency'] ?? 1,
            'lastDone': doc.data()['lastDone'] ?? DateTime.now().toString().substring(0, 10),
            'mood': doc.data()['mood'] ?? 'Relaxed',
            'category': doc.data()['category'] ?? 'Indoor',
            'activityCount': doc.data()['activityCount'] ?? 0,
          });
        }
      } else {
        // Convert user hobbies to hobby activity data with default values
        for (int i = 0; i < userHobbies.length; i++) {
          // Determine category based on hobby name
          String category = 'Indoor';
          if (['Walking', 'Gardening', 'Hiking', 'Cycling'].contains(userHobbies[i])) {
            category = 'Outdoor';
          } else if (['Painting', 'Crafts', 'Music', 'Writing'].contains(userHobbies[i])) {
            category = 'Creative';
          }

          // Determine mood based on hobby
          String mood = 'Relaxed';
          if (['Walking', 'Hiking', 'Cycling'].contains(userHobbies[i])) {
            mood = 'Energized';
          } else if (['Painting', 'Crafts', 'Music'].contains(userHobbies[i])) {
            mood = 'Creative';
          } else if (['Chess', 'Reading', 'Puzzles'].contains(userHobbies[i])) {
            mood = 'Focused';
          }

          hobbyList.add({
            'id': i.toString(),
            'name': userHobbies[i],
            'frequency': 2, // Default frequency
            'lastDone': DateTime.now().subtract(const Duration(days: 7)).toString().substring(0, 10),
            'mood': mood,
            'category': category,
            'activityCount': 0,
          });
        }
      }

      setState(() {
        userName = name;
        hobbies = hobbyList;
        userFavorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading hobbies: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Calculate activity score based on frequency and activity count
  int getActivityScore() {
    if (hobbies.isEmpty) return 0;

    // Calculate total possible points based on frequency
    double frequencyPoints = hobbies.fold(0, (sum, hobby) => sum + (hobby['frequency'] as int));

    // Calculate actual points from logged activities
    double activityPoints = hobbies.fold(0, (sum, hobby) => sum + (hobby['activityCount'] as int));

    // Calculate score out of 100
    // Score increases as users log more activities relative to their frequency goals
    int score = ((activityPoints / (frequencyPoints * 2)) * 100).round();

    // Cap at 100
    return score > 100 ? 100 : score;
  }

  // Get recommended hobby based on low activity count relative to frequency
  String getRecommendation() {
    if (hobbies.isEmpty) {
      // If no hobbies, recommend from favorites
      if (userFavorites.isNotEmpty) {
        return userFavorites.first;
      }
      return "Try something new!";
    }

    // Find hobbies with fewest activities logged relative to their frequency
    final sortedHobbies = List.from(hobbies);
    sortedHobbies.sort((a, b) {
      double aRatio = (a['activityCount'] as int) / (a['frequency'] as int);
      double bRatio = (b['activityCount'] as int) / (b['frequency'] as int);
      return aRatio.compareTo(bRatio);
    });

    return sortedHobbies.first['name'] as String;
  }

  // Add new hobby to the list
  Future<void> addNewHobby(Map<String, dynamic> hobby) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Add to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('hobbies')
          .add(hobby);

      // Update local state
      setState(() {
        hobby['id'] = docRef.id;
        hobbies.add(hobby);
        _isLoading = false;
      });
    } catch (e) {
      print('Error adding hobby: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding hobby: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Log an activity for a hobby
Future<void> logActivity(Map<String, dynamic> hobby) async {
  final today = DateTime.now().toString().substring(0, 10);
  final newActivityCount = (hobby['activityCount'] as int) + 1;

  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // First check if the hobby exists in Firestore
    DocumentReference hobbyRef;
    if (hobby['id'] == null || hobby['id'] is int) {
      // This is a new hobby that hasn't been saved to Firestore yet
      hobbyRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('hobbies')
          .doc(); // Create new document with auto-generated ID

      // Create the hobby document first
      await hobbyRef.set({
        'name': hobby['name'],
        'frequency': hobby['frequency'],
        'lastDone': today,
        'mood': hobby['mood'],
        'category': hobby['category'],
        'activityCount': 1, // Start with 1 since this is the first activity
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update local state with new ID
      setState(() {
        hobby['id'] = hobbyRef.id;
        hobby['lastDone'] = today;
        hobby['activityCount'] = 1;
      });
    } else {
      // Existing hobby - update it
      hobbyRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('hobbies')
          .doc(hobby['id'].toString());

      // Verify the document exists before updating
      final docSnapshot = await hobbyRef.get();
      if (!docSnapshot.exists) {
        // If document doesn't exist, create it
        await hobbyRef.set({
          'name': hobby['name'],
          'frequency': hobby['frequency'],
          'lastDone': today,
          'mood': hobby['mood'],
          'category': hobby['category'],
          'activityCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing document
        await hobbyRef.update({
          'lastDone': today,
          'activityCount': newActivityCount,
        });
      }

      // Update local state
      setState(() {
        hobby['lastDone'] = today;
        hobby['activityCount'] = newActivityCount;
      });
    }

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${hobby['name']} logged for today!'),
          backgroundColor: const Color(0xFF6B84DC),
        ),
      );
    }
  } catch (e) {
    print('Error logging activity: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging activity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Add the setReminder function to create notifications
Future<void> setReminder(Map<String, dynamic> hobby) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Get the current time
    final now = DateTime.now();
    
    // Create a notification for tomorrow
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0); // 9:00 AM tomorrow
    
    // Determine icon and colors based on hobby category
    Color notificationColor;
    Color textColor;
    IconData icon;
    
    switch(hobby['category'].toString().toLowerCase()) {
      case 'outdoor':
        notificationColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        icon = Icons.directions_walk;
        break;
      case 'creative':
        notificationColor = const Color(0xFFE2D9F3);
        textColor = const Color(0xFF6A359C);
        icon = Icons.palette;
        break;
      default: // Indoor
        notificationColor = const Color(0xFFD1ECF1);
        textColor = const Color(0xFF0C5460);
        icon = Icons.home;
    }
    
    // Create notification data
    final notification = {
      'type': 'activity',
      'title': 'Hobby Reminder',
      'message': 'Time for ${hobby['name']}!\nThis activity helps you feel ${hobby['mood']}.',
      'color': notificationColor.value,
      'textColor': textColor.value,
      'icon': _getIconString(icon),
      'iconColor': const Color(0xFF6B84DC).value,
      'timestamp': Timestamp.fromDate(tomorrow),
      'formattedTime': '${tomorrow.hour}:${tomorrow.minute.toString().padLeft(2, '0')}',
      'frequency': 'daily',
      'isRead': false,
      'hobbyId': hobby['id'],
    };
    
    // Add notification to user's notifications collection
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .add(notification);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for ${hobby['name']} tomorrow at 9:00 AM'),
        backgroundColor: const Color(0xFF6B84DC),
      ),
    );
  } catch (e) {
    print('Error setting reminder: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error setting reminder: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Helper function to convert IconData to string for Firestore
String _getIconString(IconData icon) {
  if (icon == Icons.directions_walk) return 'directions_walk';
  if (icon == Icons.palette) return 'palette';
  if (icon == Icons.home) return 'home';
  if (icon == Icons.medical_services_outlined) return 'medical_services_outlined';
  if (icon == Icons.mood_bad) return 'mood_bad';
  return 'notifications';
}

  // Show add hobby dialog
  void _showAddHobbyDialog() {
    final nameController = TextEditingController();
    final frequencyController = TextEditingController();
    String selectedCategory = 'Indoor';
    String selectedMood = 'Relaxed';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add New Hobby',
                style: TextStyle(
                  color: Color(0xFF4A5578),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Hobby Name',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Color(0xFF6B84DC)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6B84DC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: frequencyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weekly Frequency',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Color(0xFF6B84DC)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6B84DC)),
                        ),
                        hintText: 'How many times per week?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category:',
                      style: TextStyle(
                        color: Color(0xFF6B84DC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedCategory = newValue!;
                        });
                      },
                      items: <String>['Indoor', 'Outdoor', 'Creative']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mood Effect:',
                      style: TextStyle(
                        color: Color(0xFF6B84DC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedMood,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedMood = newValue!;
                        });
                      },
                      items: <String>['Relaxed', 'Energized', 'Creative', 'Focused', 'Happy']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate input
                    if (nameController.text.isEmpty || frequencyController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Create new hobby
                    final hobby = {
                      'name': nameController.text,
                      'frequency': int.tryParse(frequencyController.text) ?? 1,
                      'lastDone': DateTime.now().toString().substring(0, 10), // Today's date
                      'mood': selectedMood,
                      'category': selectedCategory,
                      'activityCount': 0,
                    };

                    // Add hobby and close dialog
                    addNewHobby(hobby);
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameController.text} added to your hobbies!'),
                        backgroundColor: const Color(0xFF6B84DC),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8FA2E6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Hobby'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show favorites dialog
  void _showFavoritesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Your Favorites',
            style: TextStyle(
              color: Color(0xFF4A5578),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userFavorites.isEmpty)
                  const Text(
                    'You haven\'t added any favorites yet.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...userFavorites.map((favorite) => ListTile(
                        title: Text(favorite),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6B84DC)),
                          onPressed: () {
                            // Create new hobby from favorite
                            final hobby = {
                              'name': favorite,
                              'frequency': 2, // Default frequency
                              'lastDone': DateTime.now().toString().substring(0, 10),
                              'mood': 'Happy',
                              'category': 'Indoor',
                              'activityCount': 0,
                            };

                            // Add hobby
                            addNewHobby(hobby);
                            Navigator.pop(context);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$favorite added to your hobbies!'),
                                backgroundColor: const Color(0xFF6B84DC),
                              ),
                            );
                          },
                        ),
                      )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF6B84DC)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter hobbies based on active tab
    final filteredHobbies = activeTab == 'all'
        ? hobbies
        : hobbies.where((hobby) => (hobby['category'] as String).toLowerCase() == activeTab.toLowerCase()).toList();

    // Get current activity score
    final activityScore = getActivityScore();

    return Scaffold(
      backgroundColor: const Color(0xFFD7E0FA), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF8FA2E6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hobbies & Interests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: _showFavoritesDialog,
            tooltip: 'View your favorites',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with activity balance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8FA2E6),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hello, $userName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B84DC),
                              ),
                            ),
                            Text(
                              '$activityScore/100',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B84DC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: activityScore / 100,
                            backgroundColor: const Color(0xFFD7E0FA),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B84DC)),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECF1FD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7E0FA)),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14, color: Color(0xFF4A5578)),
                              children: [
                                const TextSpan(
                                  text: 'Suggestion: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(
                                  text: 'Try doing more ',
                                ),
                                TextSpan(
                                  text: getRecommendation(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(
                                  text: ' this week to improve your wellness balance.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Tabs
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryTab('all', 'All'),
                        _buildCategoryTab('indoor', 'Indoor'),
                        _buildCategoryTab('outdoor', 'Outdoor'),
                        _buildCategoryTab('creative', 'Creative'),
                      ],
                    ),
                  ),
                ),

                // Hobbies List
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Empty state when no hobbies match the filter
                        if (filteredHobbies.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hiking,
                                    size: 64,
                                    color: const Color(0xFF8FA2E6).withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No ${activeTab == 'all' ? '' : activeTab} hobbies yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF4A5578).withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add a new hobby to get started',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredHobbies.length,
                              itemBuilder: (context, index) {
                                final hobby = filteredHobbies[index];
                                return _buildHobbyCard(hobby);
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add New Hobby'),
                                onPressed: _showAddHobbyDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8FA2E6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.favorite),
                              label: const Text('From Favorites'),
                              onPressed: _showFavoritesDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B84DC),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const BottomNav(currentIndex: -1),
    );
  }

  Widget _buildCategoryTab(String tabId, String label) {
    final isActive = activeTab == tabId;
    return GestureDetector(
      onTap: () {
        setState(() {
          activeTab = tabId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8FA2E6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : const Color(0xFF6B84DC),
          ),
        ),
      ),
    );
  }

  Widget _buildHobbyCard(Map<String, dynamic> hobby) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hobby['name'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5578),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECF1FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hobby['category'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B84DC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHobbyDetail('Weekly frequency', '${hobby['frequency']}x'),
              _buildHobbyDetail('Last done', hobby['lastDone'] as String),
              _buildHobbyDetail('Mood effect', hobby['mood'] as String),
            ],
          ),
          const SizedBox(height: 12),
          // Display activity count
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Color(0xFF4A5578)),
                    children: [
                      const TextSpan(
                        text: 'Activities logged: ',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: '${hobby['activityCount']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B84DC),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Log activity'),
                onPressed: () => logActivity(hobby),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B84DC),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.notifications_none, size: 16),
                label: const Text('Set reminder'),
                onPressed: () => setReminder(hobby),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B84DC),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHobbyDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B84DC),
            ),
          ),
        ],
      ),
    );
  }
}

