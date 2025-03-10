import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'questionstart_page.dart';
import 'package:bloom_care/models/question.dart';
import 'results_page.dart';
import 'package:flutter/services.dart' show rootBundle;

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({Key? key}) : super(key: key);

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  List<int?> _answers = [];
  late PageController _pageController;
  late AnimationController _animationController;
  Animation<double>? _progressAnimation;
  bool _isLoading = true;
  List<Question> _questions = [];
  
  final List<Color> _gradientColors = [
    const Color(0xFF6448FE),
    const Color(0xFF5FC6FF),
    const Color(0xFFFFA3FD),
    const Color(0xFF6B84DC),
    const Color(0xFF7AFFA7),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Load and randomize questions
    _loadQuestions();
  }

  // Load questions from JSON file and randomize them
  Future<void> _loadQuestions() async {
  setState(() {
    _isLoading = true;
    _questions = []; // Initialize with empty list
    _answers = []; // Initialize with empty list
  });

  try {
    // Add a delay to make the loading animation visible
    await Future.delayed(const Duration(seconds: 2));
    
    // Load the JSON file from assets
    final String jsonString = await rootBundle.loadString('assest/data/questions.json');
    
    // Parse the JSON string
    final List<dynamic> jsonData = json.decode(jsonString);
    
    // Convert JSON to Question objects
    List<Question> allQuestions = jsonData.map((json) => Question.fromJson(json)).toList();
    
    // Get the current week number to use as a seed for randomization
    final DateTime now = DateTime.now();
    final int weekOfYear = _getWeekOfYear(now);
    final int year = now.year;
    
    // Create a deterministic random generator based on the week and year
    // This ensures the same questions appear for all users in the same week
    final random = math.Random(weekOfYear + (year * 100));
    
    // Shuffle the questions with our seeded random generator
    _customShuffle(allQuestions, random);
    
    // Group questions by category to ensure variety
    Map<String, List<Question>> questionsByCategory = {};
    
    for (var question in allQuestions) {
      if (!questionsByCategory.containsKey(question.category)) {
        questionsByCategory[question.category] = [];
      }
      questionsByCategory[question.category]!.add(question);
    }
    
    // Select questions from each category to ensure a balanced assessment
    List<Question> selectedQuestions = [];
    
    // Try to get at least one question from each category
    questionsByCategory.forEach((category, questions) {
      if (questions.isNotEmpty) {
        selectedQuestions.add(questions.first);
        questions.removeAt(0);
      }
    });
    
    // If we need more questions to reach our target count (e.g., 5)
    // Add more from the remaining pool, maintaining the weekly consistency
    List<Question> remainingQuestions = [];
    questionsByCategory.forEach((category, questions) {
      remainingQuestions.addAll(questions);
    });
    
    _customShuffle(remainingQuestions, random);
    
    // Add remaining questions until we reach our target count
    while (selectedQuestions.length < 5 && remainingQuestions.isNotEmpty) {
      selectedQuestions.add(remainingQuestions.first);
      remainingQuestions.removeAt(0);
    }
    
    // Final shuffle of the selected questions to randomize their order
    _customShuffle(selectedQuestions, random);
    
    setState(() {
      _questions = selectedQuestions;
      _answers = List.filled(selectedQuestions.length, null);
      _isLoading = false;
    });
    
    // Initialize progress animation
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1 / _questions.length,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  } catch (e) {
    print('Error loading questions: $e');
    setState(() {
      _isLoading = false;
      _questions = [];
      _answers = [];
    });
  }
}

  // Helper method to get the week number of the year
  int _getWeekOfYear(DateTime date) {
    // The first day of the year
    final firstDayOfYear = DateTime(date.year, 1, 1);
    // Days from the first day of the year
    final daysFromFirstDay = date.difference(firstDayOfYear).inDays;
    // Calculate the week number (0-indexed)
    return (daysFromFirstDay / 7).floor();
  }
  
  // Custom shuffle method that uses a provided random generator
  void _customShuffle(List<Question> list, math.Random random) {
    for (int i = list.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      // Swap elements
      Question temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
  if (_questions.isEmpty) return;
  
  if (_currentQuestionIndex < _questions.length - 1) {
    _animationController.reset();
    _progressAnimation = Tween<double>(
      begin: (_currentQuestionIndex + 1) / _questions.length,
      end: (_currentQuestionIndex + 2) / _questions.length,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    setState(() {
      _currentQuestionIndex++;
    });
    
    _pageController.animateToPage(
      _currentQuestionIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
  } else {
    // Calculate score and show results
    _calculateScore();
  }
}

  void _previousQuestion() {
    if (_questions.isEmpty || _currentQuestionIndex <= 0) return;
    if (_currentQuestionIndex > 0) {
      _animationController.reset();
      _progressAnimation = Tween<double>(
        begin: (_currentQuestionIndex - 1) / _questions.length,
        end: _currentQuestionIndex / _questions.length,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      setState(() {
        _currentQuestionIndex--;
      });
      
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      
      _animationController.forward();
    }
  }

  void _selectAnswer(int answer) {
    if (_questions.isEmpty || _currentQuestionIndex >= _answers.length) return;
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });
  }

  void _calculateScore() {
    int totalScore = 0;
    
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] != null) {
        // Check if the answer matches the correct answer
        if (_answers[i] == _questions[i].correctAnswer) {
          totalScore++;
        }
      }
    }
    
    // Navigate to results page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultsPage(
          score: totalScore,
          totalQuestions: _questions.length,
          questions: _questions,
          answers: _answers,
        ),
      ),
    );
  }

  void _returnToStartPage() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const QuizWelcomeScreen()),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _questions.isEmpty) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                    onPressed: _currentQuestionIndex > 0 ? _previousQuestion : () {
                      // Show exit confirmation
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text("Exit Check-in?"),
                          content: const Text("Your progress will not be saved."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _returnToStartPage();
                              },
                              child: const Text("Exit"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Text(
                    "Mental Health Check-in",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _gradientColors[_currentQuestionIndex % _gradientColors.length],
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the layout
                ],
              ),
            ),
            
            // Animated progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _progressAnimation ?? _animationController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // Background track
                          Container(
                            height: 10,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          // Animated fill
                          Container(
                            height: 10,
                            width: MediaQuery.of(context).size.width * 
                                  (_progressAnimation?.value ?? 0) * 0.87, // Adjust for padding
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _gradientColors[_currentQuestionIndex % _gradientColors.length],
                                  _gradientColors[(_currentQuestionIndex + 1) % _gradientColors.length],
                                ],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: _gradientColors[_currentQuestionIndex % _gradientColors.length].withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Question ${_currentQuestionIndex + 1}/${_questions.length}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: (_currentQuestionIndex + 1) / _questions.length * 100),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, double value, child) {
                          return Text(
                            "${value.toInt()}% Complete",
                            style: TextStyle(
                              color: _gradientColors[_currentQuestionIndex % _gradientColors.length],
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Questions PageView with animations
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swiping
                itemCount: _questions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentQuestionIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final answer = _answers[index];
                  
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<String>(question.id),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Emoji and question
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                builder: (context, double value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _gradientColors[index % _gradientColors.length].withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          question.emoji,
                                          style: const TextStyle(fontSize: 30),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 600),
                                  builder: (context, double value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Text(
                                        question.text,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Different question types with animations
                          Expanded(
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, double value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: question.type == "scale"
                                  ? _buildScaleQuestion(answer, index)
                                  : question.type == "yesNo"
                                      ? _buildYesNoQuestion(answer, index)
                                      : _buildMultipleChoiceQuestion(question.options, answer, index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Navigation button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedOpacity(
                opacity: _answers.isNotEmpty && _currentQuestionIndex < _answers.length && _answers[_currentQuestionIndex] != null ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: _answers.isNotEmpty && _currentQuestionIndex < _answers.length && _answers[_currentQuestionIndex] != null ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gradientColors[_currentQuestionIndex % _gradientColors.length],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: _answers[_currentQuestionIndex] != null ? 8 : 0,
                    shadowColor: _answers[_currentQuestionIndex] != null 
                        ? _gradientColors[_currentQuestionIndex % _gradientColors.length].withOpacity(0.5)
                        : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentQuestionIndex < _questions.length - 1 ? "Next" : "Submit",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
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

  // Loading screen with animation
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading indicator
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B84DC).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsating circle
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.8, end: 1.2),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, double scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6B84DC).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Rotating circle
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 2 * math.pi),
                            duration: const Duration(seconds: 2),
                            builder: (context, double angle, child) {
                              return Transform.rotate(
                                angle: angle,
                                child: CircularProgressIndicator(
                                  value: null,
                                  strokeWidth: 8,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFF6B84DC),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Emoji with bounce effect
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.elasticOut,
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: value,
                                child: const Text(
                                  "🧠",
                                  style: TextStyle(fontSize: 40),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Loading text with fade-in effect
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: const Text(
                    "Preparing your check-in...",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B84DC),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Animated dots with wave effect
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, double value, child) {
                      return Container(
                        width: 10,
                        height: 10 * math.sin((value * 2 * math.pi) + (index * 0.5)).abs(),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _gradientColors[index % _gradientColors.length],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleQuestion(int? currentAnswer, int questionIndex) {
    final color = _gradientColors[questionIndex % _gradientColors.length];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Poor", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
            Text("Excellent", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            5,
            (index) => TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutBack,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: GestureDetector(
                    onTap: () => _selectAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: currentAnswer == index ? color : Colors.grey[200],
                        shape: BoxShape.circle,
                        boxShadow: currentAnswer == index
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: currentAnswer == index ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Mood indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Text("😞", style: TextStyle(fontSize: 24)),
            Text("😕", style: TextStyle(fontSize: 24)),
            Text("😐", style: TextStyle(fontSize: 24)),
            Text("🙂", style: TextStyle(fontSize: 24)),
            Text("😄", style: TextStyle(fontSize: 24)),
          ],
        ),
      ],
    );
  }

  Widget _buildYesNoQuestion(int? currentAnswer, int questionIndex) {
    final color = _gradientColors[questionIndex % _gradientColors.length];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: _buildSelectionButton("Yes", 1, currentAnswer, color),
            );
          },
        ),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: _buildSelectionButton("No", 0, currentAnswer, color),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectionButton(String text, int value, int? currentAnswer, Color color) {
    final isSelected = currentAnswer == value;
    
    return GestureDetector(
      onTap: () => _selectAnswer(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceQuestion(List<String> options, int? currentAnswer, int questionIndex) {
    final color = _gradientColors[questionIndex % _gradientColors.length];
    
    return ListView.builder(
      itemCount: options.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(50 * (1 - value), 0),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GestureDetector(
                    onTap: () => _selectAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: currentAnswer == index ? color : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentAnswer == index ? Colors.transparent : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: currentAnswer == index
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: currentAnswer == index ? Colors.white : Colors.grey[200],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: currentAnswer == index ? Colors.white : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: currentAnswer == index
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              options[index],
                              style: TextStyle(
                                color: currentAnswer == index ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}