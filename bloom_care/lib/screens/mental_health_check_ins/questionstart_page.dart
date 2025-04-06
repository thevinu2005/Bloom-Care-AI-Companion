import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'full_question_page.dart';

class QuizWelcomeScreen extends StatefulWidget {
  final bool? justCompleted;
  final String? score;
  final int? totalQuestions;
  
  const QuizWelcomeScreen({
    Key? key, 
    this.justCompleted,
    this.score,
    this.totalQuestions,
  }) : super(key: key);

  @override
  State<QuizWelcomeScreen> createState() => _QuizWelcomeScreenState();
}

class _QuizWelcomeScreenState extends State<QuizWelcomeScreen> {
  bool _isCompleted = false;
  DateTime? _nextRefreshDate;
  bool _isLoading = true;
  Map<String, dynamic>? _elderData;
  String? _caregiverId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCompletionStatus();
    
    // If we just completed the quiz, mark it as completed
    if (widget.justCompleted == true) {
      _markAsCompleted();
    }
  }

  // Load the user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _elderData = userDoc.data();
          _caregiverId = _elderData?['assignedCaregiver'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Load the completion status from shared preferences
  Future<void> _loadCompletionStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCompletionTimestamp = prefs.getInt('last_completion_timestamp');
      
      if (lastCompletionTimestamp != null) {
        final lastCompletionDate = DateTime.fromMillisecondsSinceEpoch(lastCompletionTimestamp);
        final now = DateTime.now();
        
        // Calculate next refresh date (7 days from last completion)
        final nextRefresh = lastCompletionDate.add(const Duration(days: 7));
        
        // Check if the next refresh date is in the future
        if (nextRefresh.isAfter(now)) {
          setState(() {
            _isCompleted = true;
            _nextRefreshDate = nextRefresh;
          });
        } else {
          // Reset if the refresh date has passed
          setState(() {
            _isCompleted = false;
            _nextRefreshDate = null;
          });
        }
      } else {
        setState(() {
          _isCompleted = false;
          _nextRefreshDate = null;
        });
      }
    } catch (e) {
      print('Error loading completion status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mark the quiz as completed and set the next refresh date
  Future<void> _markAsCompleted() async {
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      
      // Save the current timestamp
      await prefs.setInt('last_completion_timestamp', now.millisecondsSinceEpoch);
      
      // Calculate next refresh date (7 days from now)
      final nextRefresh = now.add(const Duration(days: 7));
      
      setState(() {
        _isCompleted = true;
        _nextRefreshDate = nextRefresh;
      });

      // If we have a score from the completed quiz, save it to Firestore
      if (widget.score != null && widget.totalQuestions != null) {
        await _saveCheckInResults(widget.score!, widget.totalQuestions!);
      }
    } catch (e) {
      print('Error marking as completed: $e');
    }
  }

  // Save check-in results to Firestore and notify caregiver
  Future<void> _saveCheckInResults(String score, int totalQuestions) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final elderName = _elderData?['name'] ?? 'Elder';
      
      // Save results to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('checkIns')
          .add({
        'score': score,
        'totalQuestions': totalQuestions,
        'timestamp': FieldValue.serverTimestamp(),
        'percentage': (int.parse(score) / totalQuestions * 100).toStringAsFixed(0),
      });

      // If there's an assigned caregiver, notify them about the results
      if (_caregiverId != null && _caregiverId!.isNotEmpty) {
        // Get the caregiver's document to check if they exist
        final caregiverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_caregiverId)
            .get();

        if (caregiverDoc.exists) {
          // Create a notification for the caregiver
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_caregiverId)
              .collection('notifications')
              .add({
            'type': 'mental_health',
            'elderName': elderName,
            'elderId': user.uid,
            'activityType': 'mental_health',
            'title': 'Mental Health Check-in',
            'message': '$elderName completed their weekly mental health check-in with a score of $score/$totalQuestions',
            'color': const Color(0xFFE2D9F3).value,
            'textColor': const Color(0xFF6A359C).value,
            'icon': 'psychology',
            'iconColor': const Color(0xFF6B84DC).value,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'priority': 'high',
            'score': score,
            'totalQuestions': totalQuestions,
          });
          
          print('Caregiver notification sent about mental health check-in');
        }
      }
    } catch (e) {
      print('Error saving check-in results: $e');
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    // Calculate next refresh date (7 days from now) for display if not completed
    final now = DateTime.now();
    final displayRefreshDate = _nextRefreshDate ?? now.add(const Duration(days: 7));
    final refreshDate = _formatDate(displayRefreshDate);

    // Calculate remaining days if completed
    String remainingDaysText = "";
    if (_isCompleted && _nextRefreshDate != null) {
      final difference = _nextRefreshDate!.difference(now).inDays;
      remainingDaysText = difference > 0 
          ? "$difference days remaining" 
          : "Available tomorrow";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF6B84DC),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
        child: Column(
          children: [
            // Back button row
            Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/');
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              const SizedBox(height: 30),
              
              // Elder profile card
              if (_elderData != null)
                _buildElderProfileCard(),
                
              const SizedBox(height: 20),
              
              // Quiz title with trophy
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mental Health Check-ins',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Main image with confetti decoration
              Stack(
                alignment: Alignment.center,
                children: [
                  // Confetti elements
                  Positioned(
                    top: 0,
                    left: 20,
                    child: _buildConfetti(Colors.yellow, 10, 40),
                  ),
                  Positioned(
                    top: 30,
                    right: 40,
                    child: _buildConfetti(Colors.orange, 8, 35),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 50,
                    child: _buildConfetti(Colors.green, 12, 45),
                  ),
                  // Main image
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(0, 238, 238, 238),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assest/images/check-ins.png', 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if image is not found
                          return Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.psychology,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Main heading
              const Text(
                'Track Your Mental Wellbeing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle text
              const Text(
                'Focus on the benefits of regular mental health check-ins and how they can help you stay on top of your mental health.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Next refresh date with status
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: _isCompleted 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: _isCompleted
                      ? Border.all(color: Colors.white, width: 1)
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isCompleted ? Icons.check_circle : Icons.refresh,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isCompleted
                              ? "Completed for this week"
                              : "Next refresh: $refreshDate",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_isCompleted && remainingDaysText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Next check-in available in $remainingDaysText",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Use a smaller spacer to prevent overflow
              const SizedBox(height: 20),
              
              // Button section
              Column(
                mainAxisSize: MainAxisSize.min, // Use minimum space needed
                children: [
                  // Get started button - disabled if completed
                  ElevatedButton(
                    onPressed: _isCompleted 
                        ? null // Disable the button if completed
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => QuestionnaireScreen(
                                  elderId: FirebaseAuth.instance.currentUser?.uid,
                                  elderName: _elderData?['name'],
                                  caregiverId: _caregiverId,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted ? Colors.grey.shade400 : Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400, // Grey when disabled
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _isCompleted 
                          ? 'Check-in closed until next week'
                          : 'Begin Weekly Check-in',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Reduced bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build elder profile card
  Widget _buildElderProfileCard() {
    final elderName = _elderData?['name'] ?? 'Elder';
    final elderEmail = _elderData?['email'] ?? 'No email';
    final elderAge = _elderData?['age'] ?? 'N/A';
    final profileImage = _elderData?['profileImage'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          // Profile image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: profileImage != null && profileImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(profileImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImage == null || profileImage.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          // Elder details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  elderName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  elderEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Age: $elderAge",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Caregiver status
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _caregiverId != null && _caregiverId!.isNotEmpty
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _caregiverId != null && _caregiverId!.isNotEmpty
                        ? Colors.green.withOpacity(0.7)
                        : Colors.red.withOpacity(0.7),
                    width: 1,
                  ),
                ),
                child: Text(
                  _caregiverId != null && _caregiverId!.isNotEmpty
                      ? "Caregiver"
                      : "No Caregiver",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to create confetti elements
  Widget _buildConfetti(Color color, double width, double height) {
    return Transform.rotate(
      angle: 0.3, // Random angle for variety
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

