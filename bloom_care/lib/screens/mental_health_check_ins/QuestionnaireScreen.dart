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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${index + 1}. ${questions[index]}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500, // Make text more visible
                        color: Colors.black, // Ensure visibility on white background
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controllers[index],
                      decoration: InputDecoration(
                        hintText: 'Type here',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Submit button does nothing yet
                },
                child: const Text('Submit'),
              ),
            ),
          ],
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
