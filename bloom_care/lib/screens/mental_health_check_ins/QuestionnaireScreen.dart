import 'package:flutter/material.dart';
import 'dart:math';

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

class CustomQuestionnairePage extends StatefulWidget {
  const CustomQuestionnairePage({super.key});

  @override
  State<CustomQuestionnairePage> createState() => _CustomQuestionnairePageState();
}

class _CustomQuestionnairePageState extends State<CustomQuestionnairePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  int _currentQuestionIndex = 0;
  final List<QuestionnaireModel> _questions = [
    QuestionnaireModel(
      question: "How often do you exercise?",
      options: ["Daily", "2-3 times a week", "Once a week", "Rarely"],
    ),
    QuestionnaireModel(
      question: "What is your preferred workout type?",
      options: ["Cardio", "Strength training", "Yoga", "Team sports"],
    ),
    QuestionnaireModel(
      question: "How would you rate your current fitness level?",
      options: ["Beginner", "Intermediate", "Advanced", "Professional"],
    ),
    QuestionnaireModel(
      question: "What are your fitness goals?",
      options: ["Lose weight", "Build muscle", "Improve endurance", "Overall health"],
    ),
    QuestionnaireModel(
      question: "How much time can you dedicate to exercise daily?",
      options: ["Less than 30 minutes", "30-60 minutes", "1-2 hours", "More than 2 hours"],
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
    int answeredQuestions = 0;
    for (var question in _questions) {
      if (question.selectedOption != null) {
        answeredQuestions++;
      }
    }
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
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Fitness Questionnaire',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
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
                          border: Border.all(
                            color: isSelected ? Colors.deepPurple : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _questions[_currentQuestionIndex].options[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontSize: 16,
                          ),
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
                  ElevatedButton(
                    onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                  ElevatedButton(
                    onPressed: _questions[_currentQuestionIndex].selectedOption != null
                        ? _nextQuestion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Finish',
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
}

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

