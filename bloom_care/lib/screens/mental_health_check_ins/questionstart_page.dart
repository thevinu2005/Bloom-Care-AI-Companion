import 'package:flutter/material.dart';
import 'full_question_page.dart'; // Updated import
import 'package:shared_preferences/shared_preferences.dart';

class QuizWelcomeScreen extends StatefulWidget {
  final bool? justCompleted; // Make justCompleted optional with ?
  
  const QuizWelcomeScreen({
    Key? key, 
    this.justCompleted,
  }) : super(key: key);

  @override
  State<QuizWelcomeScreen> createState() => _QuizWelcomeScreenState();
}

class _QuizWelcomeScreenState extends State<QuizWelcomeScreen> with SingleTickerProviderStateMixin {
  bool _isCompleted = false;
  DateTime? _nextRefreshDate;
  bool _isLoading = true;
  
  // Animation controller for the button
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
    
    // If we just completed the quiz, mark it as completed
    if (widget.justCompleted == true) {
      _markAsCompleted();
    }
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Create scale animation
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Create opacity animation
    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start the animation and make it repeat
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    } catch (e) {
      print('Error marking as completed: $e');
    }
  }

  // Reset the completion status to allow re-taking the quiz
  Future<void> _resetCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove the completion timestamp
      await prefs.remove('last_completion_timestamp');
      
      setState(() {
        _isCompleted = false;
        _nextRefreshDate = null;
      });
    } catch (e) {
      print('Error resetting completion status: $e');
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
        child: SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 90),
              // Quiz title with trophy
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'check-ins',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
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
                    height: 250,
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
                            height: 250,
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
              const SizedBox(height: 40),
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
                  // Animated button when not completed
                  _isCompleted 
                      ? ElevatedButton(
                          onPressed: null, // Disabled
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade400,
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Check-in closed until next week',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Opacity(
                                opacity: _opacityAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3 * _opacityAnimation.value),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Add a quick animation effect when pressed
                                      _animationController.stop();
                                      
                                      // Navigate to the questionnaire screen
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const QuestionnaireScreen()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Text(
                                      'let begin weekly check-in',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  
                  // Re-take option if completed
                  if (_isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0), // Reduced padding
                      child: TextButton.icon(
                        onPressed: () {
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Re-take Check-in?"),
                              content: const Text(
                                "Your previous check-in will be reset. This is typically recommended only once per week. Are you sure you want to continue?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _resetCompletionStatus();
                                  },
                                  child: const Text("Yes, Re-take"),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          "Re-take Check-in",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
     )
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