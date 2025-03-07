import 'package:flutter/material.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> controllers = List.generate(
    5,
    (index) => TextEditingController(),
  );

  final List<String> questions = [
    "How would you rate your overall mood today?",
    "Have you been feeling stressed lately?",
    "How is your sleep quality?",
    "Are you able to concentrate on tasks?",
    "How would you rate your energy levels?",
  ];

  int _currentQuestionIndex = 0; // Tracks which question is displayed

  void _nextQuestion() {
    if (_formKey.currentState!.validate()) {
      if (_currentQuestionIndex < questions.length - 1) {
        setState(() {
          _currentQuestionIndex++; // Move to next question
        });
      }
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--; // Move back to previous question
      });
    }
  }

  void _submitAnswers() {
    if (_formKey.currentState!.validate()) {
      // Show success message when all questions are answered
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Submission Successful"),
          content: const Text("Thank you for your responses!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/results');
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7986CB), // Purple background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_currentQuestionIndex + 1}. ${questions[_currentQuestionIndex]}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controllers[_currentQuestionIndex],
                decoration: InputDecoration(
                  hintText: 'Type here',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your answer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    ElevatedButton(
                      onPressed: _previousQuestion,
                      child: const Text('Back'),
                    ),
                  if (_currentQuestionIndex < questions.length - 1)
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      child: const Text('Next'),
                    ),
                  if (_currentQuestionIndex == questions.length - 1)
                    ElevatedButton(
                      onPressed: _submitAnswers,
                      child: const Text('Submit'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}


