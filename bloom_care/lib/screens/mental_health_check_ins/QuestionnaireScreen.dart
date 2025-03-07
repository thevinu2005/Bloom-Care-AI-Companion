import 'package:flutter/material.dart';
import 'dart:math';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({Key? key}) : super(key: key);

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  int currentQuestionIndex = 0;
  bool showSubmitButton = false;
  List<String> selectedQuestions = [];
  List<String?> answers = List.generate(5, (index) => null);

  // Add this map to replace the existing questionsWithOptions in your code

final Map<String, List<String>> questionsWithOptions = {
  // Mood & Emotions
  "How would you rate your overall mood today?": [
    "Excellent", "Good", "Neutral", "Poor", "Very Poor"
  ],
  "How often have you felt happy this week?": [
    "Always", "Often", "Sometimes", "Rarely", "Never"
  ],
  "Have you experienced sudden mood changes lately?": [
    "Never", "Rarely", "Sometimes", "Often", "Very Often"
  ],
  "How often have you felt overwhelmed by your emotions?": [
    "Never", "Rarely", "Sometimes", "Often", "Very Often"
  ],
  "How would you rate your emotional stability this week?": [
    "Very Stable", "Stable", "Moderate", "Unstable", "Very Unstable"
  ],

  // Anxiety & Stress
  "How would you rate your stress levels?": [
    "Very Low", "Low", "Moderate", "High", "Very High"
  ],
  "How often do you feel anxious?": [
    "Never", "Rarely", "Sometimes", "Often", "Always"
  ],
  "How well can you manage your stress?": [
    "Very Well", "Well", "Moderately", "Poorly", "Very Poorly"
  ],
  "Do you experience physical symptoms of anxiety?": [
    "Never", "Rarely", "Sometimes", "Often", "Always"
  ],
  "How often do you feel restless?": [
    "Never", "Rarely", "Sometimes", "Often", "Always"
  ],

  // Sleep Patterns
  "How would you rate your sleep quality?": [
    "Excellent", "Good", "Fair", "Poor", "Very Poor"
  ],
  "How often do you have trouble falling asleep?": [
    "Never", "Rarely", "Sometimes", "Often", "Always"
  ],
  "Do you wake up feeling refreshed?": [
    "Always", "Often", "Sometimes", "Rarely", "Never"
  ],
  "How regular is your sleep schedule?": [
    "Very Regular", "Regular", "Moderate", "Irregular", "Very Irregular"
  ],
  "Do you experience disrupted sleep?": [
    "Never", "Rarely", "Sometimes", "Often", "Always"
  ],

  // Social Interactions
  "How satisfied are you with your social relationships?": [
    "Very Satisfied", "Satisfied", "Neutral", "Dissatisfied", "Very Dissatisfied"
  ],
  "How connected do you feel to others?": [
    "Very Connected", "Connected", "Somewhat", "Disconnected", "Very Disconnected"
  ],
  "How comfortable are you in social situations?": [
    "Very Comfortable", "Comfortable", "Neutral", "Uncomfortable", "Very Uncomfortable"
  ],
  "How often do you engage in social activities?": [
    "Very Often", "Often", "Sometimes", "Rarely", "Never"
  ],
  "Do you feel understood by others?": [
    "Always", "Often", "Sometimes", "Rarely", "Never"
  ],

  // Daily Functioning
  "How well can you concentrate on tasks?": [
    "Very Well", "Well", "Moderately", "Poorly", "Very Poorly"
  ],
  "How would you rate your productivity levels?": [
    "Excellent", "Good", "Fair", "Poor", "Very Poor"
  ],
  "How often do you feel motivated?": [
    "Always", "Often", "Sometimes", "Rarely", "Never"
  ],
  "How well can you handle daily responsibilities?": [
    "Very Well", "Well", "Moderately", "Poorly", "Very Poorly"
  ],
  "How organized do you feel in your daily life?": [
    "Very Organized", "Organized", "Somewhat", "Disorganized", "Very Disorganized"
  ],

  // Physical Health
  "How would you rate your energy levels?": [
    "Very High", "High", "Moderate", "Low", "Very Low"
  ],
  "How is your appetite?": [
    "Very Good", "Good", "Normal", "Poor", "Very Poor"
  ],
  "How often do you exercise?": [
    "Very Often", "Often", "Sometimes", "Rarely", "Never"
  ],
  "How would you rate your physical health?": [
    "Excellent", "Good", "Fair", "Poor", "Very Poor"
  ],
  "Do you experience physical discomfort?": [
    "Never", "Rarely", "Sometimes", "Often", "Always"
  ],

  // Self-perception
  "How satisfied are you with yourself?": [
    "Very Satisfied", "Satisfied", "Neutral", "Dissatisfied", "Very Dissatisfied"
  ],
  "How confident do you feel?": [
    "Very Confident", "Confident", "Moderate", "Unconfident", "Very Unconfident"
  ],
  "How optimistic do you feel about the future?": [
    "Very Optimistic", "Optimistic", "Neutral", "Pessimistic", "Very Pessimistic"
  ],
  "How well do you handle criticism?": [
    "Very Well", "Well", "Moderately", "Poorly", "Very Poorly"
  ],
  "How worthy do you feel?": [
    "Very Worthy", "Worthy", "Neutral", "Unworthy", "Very Unworthy"
  ],

  // Work/Study Life
  "How satisfied are you with your work/study?": [
    "Very Satisfied", "Satisfied", "Neutral", "Dissatisfied", "Very Dissatisfied"
  ],
  "How stressed are you about work/study?": [
    "Not at All", "Slightly", "Moderately", "Very", "Extremely"
  ],
  "How well can you balance work and personal life?": [
    "Very Well", "Well", "Moderately", "Poorly", "Very Poorly"
  ],
  "How motivated are you in your work/study?": [
    "Very Motivated", "Motivated", "Neutral", "Unmotivated", "Very Unmotivated"
  ],
  "How supported do you feel at work/study?": [
    "Very Supported", "Supported", "Neutral", "Unsupported", "Very Unsupported"
  ],

  // Coping & Resilience
  "How well do you handle challenges?": [
    "Very Well", "Well", "Moderately", "Poorly", "Very Poorly"
  ],
  "How resilient do you feel to stress?": [
    "Very Resilient", "Resilient", "Moderate", "Low Resilience", "Very Low Resilience"
  ],
  "How effectively can you solve problems?": [
    "Very Effectively", "Effectively", "Moderately", "Ineffectively", "Very Ineffectively"
  ],
  "How well do you adapt to change?": [
    "Very Well", "Well", "Moderately", "Poorly", "Very Poorly"
  ],
  "How well can you regulate your emotions?": [
    "Very Well", "Well", "Moderately", "Poorly", "Very Poorly"
  ],

  // Personal Growth
  "How much personal growth do you feel?": [
    "Significant", "Moderate", "Some", "Little", "None"
  ],
  "How often do you learn new things?": [
    "Very Often", "Often", "Sometimes", "Rarely", "Never"
  ],
  "How meaningful do you find your life?": [
    "Very Meaningful", "Meaningful", "Neutral", "Less Meaningful", "Not Meaningful"
  ],
  "How well do you know yourself?": [
    "Very Well", "Well", "Moderately", "Poorly", "Very Poorly"
  ],
  "How satisfied are you with your personal progress?": [
    "Very Satisfied", "Satisfied", "Neutral", "Dissatisfied", "Very Dissatisfied"
  ]
};

  @override
  void initState() {
    super.initState();
    int weekNumber = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays ~/ 7;
    final random = Random(weekNumber);
    List<String> shuffled = List.from(questionsWithOptions.keys.toList())..shuffle(random);
    selectedQuestions = shuffled.take(5).toList();
  }

  void nextQuestion() {
    if (currentQuestionIndex < 4) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      setState(() {
        showSubmitButton = true;
      });
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        showSubmitButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7B8EE7),
              Color(0xFF5B73CE),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (currentQuestionIndex + 1) / 5,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 20),
                  // Question counter with navigation
                  Row(
                    children: [
                      if (currentQuestionIndex > 0)
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: previousQuestion,
                        ),
                      Text(
                        "Question ${currentQuestionIndex + 1}/5",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Current question
                  Text(
                    selectedQuestions[currentQuestionIndex],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Dropdown field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButtonFormField<String>(
                      value: answers[currentQuestionIndex],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Select your answer',
                      ),
                      items: questionsWithOptions[selectedQuestions[currentQuestionIndex]]!
                          .map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          answers[currentQuestionIndex] = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an answer';
                        }
                        return null;
                      },
                    ),
                  ),
                  const Spacer(),
                  // Next/Submit button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (showSubmitButton) {
                            Navigator.pushNamed(
                              context,
                              '/results',
                              arguments: {
                                'questions': selectedQuestions,
                                'answers': answers,
                              },
                            );
                          } else {
                            nextQuestion();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        showSubmitButton ? 'Submit' : 'Next',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF5B73CE),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}