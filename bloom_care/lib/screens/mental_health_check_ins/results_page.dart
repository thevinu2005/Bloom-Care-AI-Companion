import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'questionstart_page.dart';
import 'package:bloom_care/models/question.dart';
import 'package:bloom_care/services/notification_service.dart';

class ResultsPage extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final List<Question> questions;
  final List<int?> answers;
  final String? elderId;
  final String? elderName;
  final String? caregiverId;

  const ResultsPage({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.questions,
    required this.answers,
    this.elderId,
    this.elderName,
    this.caregiverId,
  }) : super(key: key);

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final NotificationService _notificationService = NotificationService();
  bool _resultsSaved = false;

  @override
  void initState() {
    super.initState();
    _saveResults();
  }

  Future<void> _saveResults() async {
    if (_resultsSaved) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final percentage = (widget.score / widget.totalQuestions) * 100;
      final elderName = widget.elderName ?? 'Elder';
      
      // Save results to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.elderId ?? user.uid)
          .collection('checkIns')
          .add({
        'score': widget.score,
        'totalQuestions': widget.totalQuestions,
        'timestamp': FieldValue.serverTimestamp(),
        'percentage': percentage.toStringAsFixed(0),
      });

      // Notify caregiver if available
      if (widget.caregiverId != null && widget.caregiverId!.isNotEmpty) {
        // Get mental health status based on score
        String mentalHealthStatus = percentage >= 80 
            ? "excellent" 
            : percentage >= 60 
                ? "good" 
                : "needs attention";

        // Send notification to caregiver
        await _notificationService.notifyCaregiverAboutElderActivity(
          activityType: 'mental_health',
          activityName: 'Weekly Check-in',
          activityDetails: 'Score: ${widget.score}/${widget.totalQuestions} (${percentage.toStringAsFixed(0)}%) - Mental health status: $mentalHealthStatus',
        );
      }

      setState(() {
        _resultsSaved = true;
      });
    } catch (e) {
      print('Error saving results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.totalQuestions) * 100;
    final Color resultColor = percentage >= 80 
        ? Colors.green 
        : percentage >= 60 
            ? Colors.orange 
            : Colors.red;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    resultColor.withOpacity(0.7),
                    resultColor.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.elderName != null ? "${widget.elderName}'s Check-in Results" : "Check-in Results",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 1),
                    builder: (context, double value, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Progress circle
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: value * percentage / 100,
                              strokeWidth: 12,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          // Score text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${(percentage * value).toInt()}%",
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "${widget.score}/${widget.totalQuestions}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    percentage >= 80 
                        ? "Excellent! Your mental health knowledge is strong!" 
                        : percentage >= 60 
                            ? "Good job! You have solid mental health awareness." 
                            : "Keep learning about mental health practices!",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Question review list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.questions[index];
                  final userAnswer = widget.answers[index];
                  final correctAnswer = question.correctAnswer;
                  final isCorrect = userAnswer == correctAnswer;
                  
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 500 + (index * 100)),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isCorrect ? Icons.check : Icons.close,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        title: Text(
                          "Question ${index + 1}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          question.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                _buildAnswerRow(
                                  "Your Answer:",
                                  _getAnswerText(question, userAnswer),
                                  isCorrect ? Colors.green : Colors.red,
                                ),
                                const SizedBox(height: 8),
                                _buildAnswerRow(
                                  "Correct Answer:",
                                  _getAnswerText(question, correctAnswer),
                                  Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Return to home button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => QuizWelcomeScreen(
                        justCompleted: true,
                        score: widget.score.toString(),
                        totalQuestions: widget.totalQuestions,
                      )
                    ),
                    (route) => false, // Remove all previous routes
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B84DC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.home),
                    SizedBox(width: 8),
                    Text(
                      "Return to Home",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build answer rows in the results screen
  Widget _buildAnswerRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get text representation of an answer
  String _getAnswerText(Question question, dynamic answerValue) {
    if (answerValue == null) return "No answer";
    
    if (question.type == "multipleChoice" && question.options.isNotEmpty) {
      return question.options[answerValue as int];
    } else if (question.type == "yesNo") {
      return answerValue == 1 ? "Yes" : "No";
    } else if (question.type == "scale") {
      return "${answerValue + 1} out of 5";
    }
    
    return answerValue.toString();
  }
}

