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
