import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'package:bloom_care/screens/emergancy/emergancy_page_1.dart';
import 'dart:async';

class EmotionCheck extends StatefulWidget {
  const EmotionCheck({super.key});

  @override
  State<EmotionCheck> createState() => _EmotionCheckState();
}

class _EmotionCheckState extends State<EmotionCheck> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showChart = false;
  bool _showAvatar = true;
  bool _isRecording = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Make the animation repeat in both directions
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startRecordingProcess() {
    setState(() {
      _isRecording = true;
      _showAvatar = false;
      _showChart = false;
    });

    // Start the pulsing animation
    _animationController.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _showChart = true;
        });
        // Stop the pulsing animation
        _animationController.stop();
        _animationController.reset();
      }
    });
  }

  void _resetState() {
    setState(() {
      _showChart = false;
      _showAvatar = true;
      _isRecording = false;
    });
    _animationController.stop();
    _animationController.reset();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      // Navigate to EmergencyServicesScreen when Emergency tab is tapped
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmergencyServicesScreen()),
      );
    }
    // Add navigation logic for other tabs if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B84DC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Back button
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Greeting Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      const TextSpan(text: 'Hello '),
                      const TextSpan(
                        text: 'Imsarie',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                      if (_showChart) const TextSpan(text: ',\nyou are in a good mood!'),
                    ],
                  ),
                ),
              ),
            ),
            // Subtitle or Chart
            if (!_showChart)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'How may I Assist you today?',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            if (_showAvatar) ...[
              const SizedBox(height: 60),
              // Avatar
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assest/images/grandma.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            if (_showChart)
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                color: Colors.green,
                                value: 75,
                                title: 'Good\n75%',
                                radius: 100,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.red,
                                value: 25,
                                title: 'Bad\n25%',
                                radius: 100,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isRecording)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'Analyzing your mood...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            // Microphone Button with Animation
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _scaleAnimation.value : 1.0,
                  child: GestureDetector(
                    onTap: () {
                      if (_showChart) {
                        _resetState();
                      } else if (!_isRecording) {
                        _startRecordingProcess();
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? const Color(0xFFFFC0CB).withOpacity(0.7)
                            : const Color(0xFFFFC0CB),
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bottom Navigation Bar
            BottomNav(
              currentIndex: _currentIndex,
              onTap: _onNavItemTapped, // Use the new _onNavItemTapped method
            ),
          ],
        ),
      ),
    );
  }
}