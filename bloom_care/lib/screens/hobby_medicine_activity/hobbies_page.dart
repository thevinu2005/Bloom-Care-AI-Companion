import 'package:flutter/material.dart';
import 'bottom_nav.dart';

class HobbiesPage extends StatefulWidget {
  const HobbiesPage({super.key});

  @override
  State<HobbiesPage> createState() => _HobbiesPageState();
}

class _HobbiesPageState extends State<HobbiesPage> {
  String activeTab = 'all';

  // Sample hobby data
  final List<Map<String, dynamic>> hobbies = [
    {
      'id': 1,
      'name': 'Reading',
      'frequency': 3,
      'lastDone': '2025-02-28',
      'mood': 'Relaxed',
      'category': 'Indoor',
      'activityCount': 0
    },
    {
      'id': 2,
      'name': 'Walking',
      'frequency': 5,
      'lastDone': '2025-03-01',
      'mood': 'Energized',
      'category': 'Outdoor',
      'activityCount': 0
    },
    {
      'id': 3,
      'name': 'Painting',
      'frequency': 1,
      'lastDone': '2025-02-20',
      'mood': 'Creative',
      'category': 'Creative',
      'activityCount': 0
    }
  ];

  // Calculate activity score based on frequency and activity count
  int getActivityScore() {
    if (hobbies.isEmpty) return 0;

    // Calculate total possible points based on frequency
    double frequencyPoints = hobbies.fold(0, (sum, hobby) => sum + hobby['frequency']);

    // Calculate actual points from logged activities
    double activityPoints = hobbies.fold(0, (sum, hobby) => sum + (hobby['activityCount'] ?? 0));

    // Calculate score out of 100
    // Score increases as users log more activities relative to their frequency goals
    int score = ((activityPoints / (frequencyPoints * 2)) * 100).round();

    // Cap at 100
    return score > 100 ? 100 : score;
  }

  // Get recommended hobby based on low activity count relative to frequency
  String getRecommendation() {
    if (hobbies.isEmpty) return "Try something new!";

    // Find hobbies with fewest activities logged relative to their frequency
    final sortedHobbies = List.from(hobbies);
    sortedHobbies.sort((a, b) {
      double aRatio = (a['activityCount'] ?? 0) / a['frequency'];
      double bRatio = (b['activityCount'] ?? 0) / b['frequency'];
      return aRatio.compareTo(bRatio);
    });

    return sortedHobbies.first['name'];
  }

  // Add new hobby to the list
  void addNewHobby(Map<String, dynamic> hobby) {
    setState(() {
      // Generate a new ID (one more than the highest existing ID)
      final newId = hobbies.isEmpty ? 1 : hobbies.map((h) => h['id']).reduce((a, b) => a > b ? a : b) + 1;
      hobby['id'] = newId;
      hobby['activityCount'] = 0; // Initialize activity count
      hobbies.add(hobby);
    });
  }

  // Log an activity for a hobby
  void logActivity(Map<String, dynamic> hobby) {
    setState(() {
      // Update last done date to today
      hobby['lastDone'] = DateTime.now().toString().substring(0, 10);

      // Increment activity count
      hobby['activityCount'] = (hobby['activityCount'] ?? 0) + 1;
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${hobby['name']} logged for today!'),
        backgroundColor: const Color(0xFF6B84DC),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    // Filter hobbies based on active tab
    final filteredHobbies = activeTab == 'all'
        ? hobbies
        : hobbies.where((hobby) => hobby['category'].toLowerCase() == activeTab.toLowerCase()).toList();

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
      ),
      body: Column(
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
