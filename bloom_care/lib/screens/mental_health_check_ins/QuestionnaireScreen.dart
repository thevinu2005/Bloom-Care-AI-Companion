import 'package:flutter/material.dart';
import 'dart:math';
import 'package:bloom_care/screens/mental_health_check_ins/mental_health_check_ins.dart';

// Circular Progress Painter
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// Questionnaire Model
class QuestionnaireModel {
  final String question;
  final List<String> options;
  int? selectedOption;

  QuestionnaireModel({
    required this.question,
    required this.options,
    this.selectedOption,
  });
}

// Wellness Plan Model
class WellnessPlanItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  WellnessPlanItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Main Questionnaire Page
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  int _currentQuestionIndex = 0;
  bool _showResults = false;
  bool _showCompletionDialog = false;
  
  // Results data
  int _mentalHealthScore = 0;
  double _scorePercentage = 0.0;
  String _mentalHealthLevel = "Moderate";
  
  // Question breakdown
  List<Map<String, dynamic>> _questionBreakdown = [];
  
  // Wellness plan
  List<WellnessPlanItem> _wellnessPlan = [];
  
  final List<QuestionnaireModel> _questions = [
    QuestionnaireModel(
      question: "How often do you feel overwhelmed by your emotions?",
      options: ["Rarely", "Sometimes", "Often", "Almost always"],
    ),
    QuestionnaireModel(
      question: "How would you rate your sleep quality?",
      options: ["Excellent", "Good", "Fair", "Poor"],
    ),
    QuestionnaireModel(
      question: "How often do you engage in activities you enjoy?",
      options: ["Daily", "Several times a week", "Once a week", "Rarely"],
    ),
    QuestionnaireModel(
      question: "How would you describe your energy levels most days?",
      options: ["High energy", "Moderate energy", "Low energy", "Very low energy"],
    ),
    QuestionnaireModel(
      question: "How often do you practice mindfulness or relaxation techniques?",
      options: ["Daily", "Several times a week", "Occasionally", "Never"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _updateProgressAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateProgressAnimation() {
    int answeredQuestions = _questions.where((q) => q.selectedOption != null).length;
    double newProgress = answeredQuestions / _questions.length;

    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: newProgress,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward(from: 0);
  }

  void _selectOption(int optionIndex) {
    setState(() {
      _questions[_currentQuestionIndex].selectedOption = optionIndex;
      _updateProgressAnimation();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _calculateResults();
      _showCompletionDialogWidget();
    }
  }
  
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _calculateResults() {
    // Calculate a score based on answers
    int score = 0;
    _questionBreakdown = [];

    // Assign points based on emotional overwhelm (Q1)
    final emotionalOverwhelm = _questions[0].selectedOption ?? 0;
    final emotionalScore = 3 - emotionalOverwhelm; // Rarely (3pts) to Almost always (0pts)
    score += emotionalScore;
    _questionBreakdown.add({
      'question': _questions[0].question,
      'answer': _questions[0].options[emotionalOverwhelm],
      'score': emotionalScore,
      'maxScore': 3,
      'feedback': emotionalScore <= 1 
          ? 'Consider practicing emotional regulation techniques.'
          : 'Youre managing your emotions well.',
    });

    // Assign points based on sleep quality (Q2)
    final sleepQuality = _questions[1].selectedOption ?? 0;
    final sleepScore = 3 - sleepQuality; // Excellent (3pts) to Poor (0pts)
    score += sleepScore;
    _questionBreakdown.add({
      'question': _questions[1].question,
      'answer': _questions[1].options[sleepQuality],
      'score': sleepScore,
      'maxScore': 3,
      'feedback': sleepScore <= 1 
          ? 'Improving sleep habits could benefit your mental health.'
          : 'Your sleep quality is supporting your mental health.',
    });

    // Assign points based on enjoyable activities (Q3)
    final enjoyableActivities = _questions[2].selectedOption ?? 0;
    final activitiesScore = 3 - enjoyableActivities; // Daily (3pts) to Rarely (0pts)
    score += activitiesScore;
    _questionBreakdown.add({
      'question': _questions[2].question,
      'answer': _questions[2].options[enjoyableActivities],
      'score': activitiesScore,
      'maxScore': 3,
      'feedback': activitiesScore <= 1 
          ? 'Try to incorporate more activities you enjoy into your routine.'
          : 'Youre doing well at engaging in enjoyable activities.',
    });

    // Assign points based on energy levels (Q4)
    final energyLevels = _questions[3].selectedOption ?? 0;
    final energyScore = 3 - energyLevels; // High energy (3pts) to Very low energy (0pts)
    score += energyScore;
    _questionBreakdown.add({
      'question': _questions[3].question,
      'answer': _questions[3].options[energyLevels],
      'score': energyScore,
      'maxScore': 3,
      'feedback': energyScore <= 1 
          ? 'Consider factors that might be affecting your energy levels.'
          : 'Your energy levels are supporting your mental wellbeing.',
    });

    // Assign points based on mindfulness practice (Q5)
    final mindfulnessPractice = _questions[4].selectedOption ?? 0;
    final mindfulnessScore = 3 - mindfulnessPractice; // Daily (3pts) to Never (0pts)
    score += mindfulnessScore;
    _questionBreakdown.add({
      'question': _questions[4].question,
      'answer': _questions[4].options[mindfulnessPractice],
      'score': mindfulnessScore,
      'maxScore': 3,
      'feedback': mindfulnessScore <= 1 
          ? 'Incorporating mindfulness practices could improve your mental health.'
          : 'Your mindfulness practice is benefiting your mental health.',
    });

    // Calculate percentage
    final percentage = (score / 15) * 100;

    // Determine mental health level
    String mentalHealthLevelText = "Moderate";
    if (percentage >= 80) mentalHealthLevelText = "Excellent";
    else if (percentage >= 60) mentalHealthLevelText = "Good";
    else if (percentage <= 30) mentalHealthLevelText = "Needs Attention";

    // Generate wellness plan based on responses
    _generateWellnessPlan();

    setState(() {
      _mentalHealthScore = score;
      _scorePercentage = percentage;
      _mentalHealthLevel = mentalHealthLevelText;
    });
  }

  void _generateWellnessPlan() {
    List<WellnessPlanItem> plan = [];
    
    // Check emotional regulation (Q1)
    if ((_questions[0].selectedOption ?? 0) >= 2) { // Often or Almost always
      plan.add(WellnessPlanItem(
        title: "Emotional Regulation",
        description: "Practice deep breathing exercises for 5 minutes daily to help manage overwhelming emotions.",
        icon: Icons.favorite,
        color: const Color.fromARGB(255, 255, 255, 255),
      ));
    }
    
    // Check sleep quality (Q2)
    if ((_questions[1].selectedOption ?? 0) >= 2) { // Fair or Poor
      plan.add(WellnessPlanItem(
        title: "Sleep Improvement",
        description: "Establish a consistent sleep schedule and avoid screens 1 hour before bedtime.",
        icon: Icons.nightlight_round,
        color: const Color.fromARGB(255, 255, 255, 255),
      ));
    }
    
    // Check enjoyable activities (Q3)
    if ((_questions[2].selectedOption ?? 0) >= 2) { // Once a week or Rarely
      plan.add(WellnessPlanItem(
        title: "Enjoyable Activities",
        description: "Schedule at least 30 minutes daily for activities you enjoy to boost your mood.",
        icon: Icons.sports_esports,
        color: const Color.fromARGB(255, 255, 255, 255),
      ));
    }
    
    // Check energy levels (Q4)
    if ((_questions[3].selectedOption ?? 0) >= 2) { // Low or Very low energy
      plan.add(WellnessPlanItem(
        title: "Energy Boosting",
        description: "Incorporate light physical activity like walking for 15-20 minutes daily to increase energy levels.",
        icon: Icons.bolt,
        color: const Color.fromARGB(255, 255, 255, 255),
      ));
    }
    
    // Check mindfulness practice (Q5)
    if ((_questions[4].selectedOption ?? 0) >= 2) { // Occasionally or Never
      plan.add(WellnessPlanItem(
        title: "Mindfulness Practice",
        description: "Start with 5 minutes of mindfulness meditation daily using a guided app.",
        icon: Icons.spa,
        color: const Color.fromARGB(255, 255, 255, 255),
      ));
    }
    
    // Add a general wellness tip for everyone
    plan.add(WellnessPlanItem(
      title: "Social Connection",
      description: "Maintain regular contact with friends and family to support your mental wellbeing.",
      icon: Icons.people,
      color: const Color.fromARGB(255, 255, 255, 255),
    ));
    
    setState(() {
      _wellnessPlan = plan;
    });
  }

  void _showCompletionDialogWidget() {
    setState(() {
      _showCompletionDialog = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D30),
        title: const Text(
          "Survey Completed",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Thank you for completing the questionnaire! Your results are being processed...",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.deepPurple,
              strokeWidth: 4,
            ),
            const SizedBox(height: 20),
            const Text(
              "Please wait 5 seconds while we analyze your responses",
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pop();
      setState(() {
        _showCompletionDialog = false;
        _showResults = true;
      });
    });
  }

  Color _getMentalHealthLevelColor() {
    switch (_mentalHealthLevel) {
      case "Excellent":
        return Colors.green;
      case "Good":
        return Colors.blue;
      case "Moderate":
        return Colors.amber;
      case "Needs Attention":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildResultsScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        title: const Text('Your Results'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image with opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/background.jpg', // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mental Health Score Card
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Mental Health Score",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$_mentalHealthScore/15",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _scorePercentage / 100,
                          backgroundColor: Colors.grey[700],
                          color: const Color.fromARGB(255, 255, 255, 255),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Score Percentage",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            "${_scorePercentage.toInt()}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Mental Health Level: ",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _mentalHealthLevel,
                            style: TextStyle(
                              color: _getMentalHealthLevelColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Question Breakdown Section
                const Text(
                  "Question Breakdown",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Question breakdown cards
                ...List.generate(_questionBreakdown.length, (index) {
                  final item = _questionBreakdown[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Q${index + 1}: ${item['question']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Your answer: ${item['answer']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "Score: ${item['score']}/${item['maxScore']}",
                              style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                            ),
                            const Spacer(),
                            Container(
                              width: 100,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: Colors.grey[700],
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: item['score'] / item['maxScore'],
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['feedback'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 24),
                
                // Wellness Plan Section
                const Text(
                  "Your Wellness Plan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Wellness plan cards
                ..._wellnessPlan.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: item.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
                const SizedBox(height: 24),
                
                // Close button (replacing disclaimer)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 69, 68, 68),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      "Close",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsScreen();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mental Health Questionnaire'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Background image with opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assest/background.jpg', 
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Progress indicator
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          shape: BoxShape.circle,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(180, 180),
                            painter: CircularProgressPainter(
                              progress: _progressAnimation.value,
                              backgroundColor: Colors.grey[800]!,
                              progressColor: Colors.deepPurple,
                              strokeWidth: 12,
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Text(
                            "${(_progressAnimation.value * 100).toInt()}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Question
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _questions[_currentQuestionIndex].question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                // Options
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: _questions[_currentQuestionIndex].options.length,
                    itemBuilder: (context, index) {
                      final isSelected = _questions[_currentQuestionIndex].selectedOption == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: InkWell(
                          onTap: () => _selectOption(index),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.deepPurple : Colors.grey[850],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _questions[_currentQuestionIndex].options[index],
                              style: TextStyle(color: isSelected ? Colors.white : Colors.grey[300], fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      ElevatedButton(
                        onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          disabledBackgroundColor: Colors.grey[900],
                        ),
                        child: const Text("Back"),
                      ),
                      // Next button
                      ElevatedButton(
                        onPressed: _questions[_currentQuestionIndex].selectedOption != null ? _nextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          disabledBackgroundColor: Colors.grey[700],
                        ),
                        child: const Text("Next"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}