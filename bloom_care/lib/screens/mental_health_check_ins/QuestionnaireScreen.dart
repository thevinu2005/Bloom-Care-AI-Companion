import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: QuestionnaireScreen()));
}

class QuestionnaireScreen extends StatefulWidget {
  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final Map<String, List<String>> questionsWithOptions = {
    "How would you rate your overall mood today?": ["Excellent", "Good", "Neutral", "Poor", "Very Poor"],
    "How often have you felt happy this week?": ["Always", "Often", "Sometimes", "Rarely", "Never"],
    "How well can you manage your stress?": ["Very Well", "Well", "Moderately", "Poorly", "Very Poorly"],
    "How would you rate your sleep quality?": ["Excellent", "Good", "Fair", "Poor", "Very Poor"],
    "How often do you engage in social activities?": ["Very Often", "Often", "Sometimes", "Rarely", "Never"],
    "How well can you concentrate on tasks?": ["Very Well", "Well", "Moderately", "Poorly", "Very Poorly"],
    "How would you rate your energy levels?": ["Very High", "High", "Moderate", "Low", "Very Low"],
    "How satisfied are you with yourself?": ["Very Satisfied", "Satisfied", "Neutral", "Dissatisfied", "Very Dissatisfied"],
    "How motivated are you in your work/study?": ["Very Motivated", "Motivated", "Neutral", "Unmotivated", "Very Unmotivated"],
    "How well do you handle challenges?": ["Very Well", "Well", "Moderately", "Poorly", "Very Poorly"],
  };

  late List<String> selectedQuestions;
  int currentQuestionIndex = 0;
  List<String?> answers = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    _selectRandomQuestions();
  }

  void _selectRandomQuestions() {
    final random = Random();
    selectedQuestions = (questionsWithOptions.keys.toList()..shuffle(random)).take(5).toList();
  }

  void _nextQuestion() {
    if (currentQuestionIndex < 4) {
      setState(() => currentQuestionIndex++);
    } else {
      _submitAnswers();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() => currentQuestionIndex--);
    }
  }

  void _submitAnswers() {
    print("Submitted answers: ${answers}");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Submission Successful"),
        content: Text("Your questionnaire has been submitted!"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String question = selectedQuestions[currentQuestionIndex];
    List<String> options = questionsWithOptions[question]!;

    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.blue.shade600], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            LinearProgressIndicator(value: (currentQuestionIndex + 1) / 5),
            SizedBox(height: 20),
            Text("Question ${currentQuestionIndex + 1}/5", style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 20),
            Text(question, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: answers[currentQuestionIndex],
              hint: Text("Select your answer", style: TextStyle(color: Colors.white)),
              dropdownColor: Colors.white,
              onChanged: (value) => setState(() => answers[currentQuestionIndex] = value),
              items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentQuestionIndex > 0)
                  ElevatedButton(onPressed: _previousQuestion, child: Text("Back")),
                ElevatedButton(onPressed: answers[currentQuestionIndex] != null ? _nextQuestion : null, child: Text(currentQuestionIndex == 4 ? "Submit" : "Next")),
              ],
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}