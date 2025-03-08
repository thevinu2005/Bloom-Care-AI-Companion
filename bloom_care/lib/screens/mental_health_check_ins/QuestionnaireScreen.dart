import 'dart:math';
import 'package:flutter/material.dart';

class QuestionnaireScreen extends StatefulWidget {
  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int currentQuestionIndex = 0;
  List<String> selectedQuestions = [];
  List<String?> answers = List.filled(5, null);

  final Map<String, List<String>> questionsWithOptions = {
    "How would you rate your overall mood today?": ["Excellent", "Good", "Neutral", "Poor", "Very Poor"],
    "How often have you felt happy this week?": ["Always", "Often", "Sometimes", "Rarely", "Never"],
    "Have you experienced sudden mood changes lately?": ["Never", "Rarely", "Sometimes", "Often", "Very Often"],
    "How would you rate your sleep quality?": ["Excellent", "Good", "Fair", "Poor", "Very Poor"],
    "How often do you feel anxious?": ["Never", "Rarely", "Sometimes", "Often", "Always"],
  };

  @override
  void initState() {
    super.initState();
    selectRandomQuestions();
  }

  void selectRandomQuestions() {
    int weekNumber = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays ~/ 7;
    List<String> shuffledKeys = questionsWithOptions.keys.toList();
    shuffledKeys.shuffle(Random(weekNumber));
    setState(() {
      selectedQuestions = shuffledKeys.take(5).toList();
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < 4) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  void handleSubmit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Submission"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("All questions submitted successfully."),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 4), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission complete!")),
      );
    });
  }

  void handleAnswerChange(String? value) {
    setState(() {
      answers[currentQuestionIndex] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedQuestions.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String currentQuestion = selectedQuestions[currentQuestionIndex];
    List<String> currentOptions = List.of(questionsWithOptions[currentQuestion] ?? []);
    currentOptions.shuffle();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assest/images/pic2.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 155, 87, 168).withOpacity(0.7),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Question ${currentQuestionIndex + 1} of 5",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (currentQuestionIndex + 1) / 5,
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 140),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentQuestion,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: answers[currentQuestionIndex],
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          hint: Text("Select your answer"),
                          onChanged: handleAnswerChange,
                          items: currentOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentQuestionIndex > 0)
                        TextButton(
                          onPressed: previousQuestion,
                          child: Text("← Previous", style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      if (currentQuestionIndex < 4)
                        TextButton(
                          onPressed: answers[currentQuestionIndex] != null ? nextQuestion : null,
                          child: Text("Next →", style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  SizedBox(height: 200),
                  ElevatedButton(
                    onPressed: answers[currentQuestionIndex] != null
                        ? (currentQuestionIndex == 4 ? handleSubmit : nextQuestion)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 50),
                    ),
                    child: Text(currentQuestionIndex == 4 ? "Submit" : "Continue"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
