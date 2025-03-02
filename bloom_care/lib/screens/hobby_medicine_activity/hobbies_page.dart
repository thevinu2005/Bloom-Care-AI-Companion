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
                      const Text(
                        'Activity Balance',
                        style: TextStyle(
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
                          TextSpan(
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
                  SizedBox(
                    width: double.infinity,
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
