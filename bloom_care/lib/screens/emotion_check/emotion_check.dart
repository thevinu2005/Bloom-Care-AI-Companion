import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'package:bloom_care/services/ml_service.dart';
import 'package:bloom_care/services/emotion_response.dart';
import 'package:bloom_care/screens/home/elders_home.dart';
import 'package:bloom_care/widgets/emotion_resourses_widget.dart';
import 'package:intl/intl.dart';

class EmotionCheck extends StatefulWidget {
  final String? elderId; // Optional: If provided, save emotion for this elder (for caregivers)

  const EmotionCheck({super.key, this.elderId});

  @override
  State<EmotionCheck> createState() => _EmotionCheckState();
}

class _EmotionCheckState extends State<EmotionCheck> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showResults = false;
  bool _showAvatar = true;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _isLoadingUser = true;
  String? _userName;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  final _audioRecorder = AudioRecorder();
  String? _recordedFilePath;
  EmotionResponse? _analysisResult;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _requestPermissions();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // If elderId is provided, load that elder's data instead
        final String userId = widget.elderId ?? user.uid;
        
        final userData = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (userData.exists) {
          setState(() {
            _userName = userData.data()?['name'] ?? 'User';
            _isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _userName = 'User';
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _saveEmotionData(String emotion, Map<String, double> probabilities) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Determine which user ID to use (current user or elder)
        final String userId = widget.elderId ?? user.uid;
        
        print('Saving emotion data for user: $userId');
        print('Emotion: $emotion');
        print('Probabilities: $probabilities');
        
        // Format current timestamp for display
        final now = DateTime.now();
        final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
        
        // Save to emotions subcollection
        await _firestore.collection('users').doc(userId).collection('emotions').add({
          'emotion': emotion,
          'probabilities': probabilities,
          'timestamp': FieldValue.serverTimestamp(),
          'formattedTime': formattedTime,
          'userId': userId,  // Add user ID for easier querying
        });
        
        // Also update the user's mood in their profile
        await _firestore.collection('users').doc(userId).update({
          'mood': emotion,
          'lastMoodUpdate': FieldValue.serverTimestamp(),
        });
        
        print('Emotion data saved successfully for user: $userId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emotion recorded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Error: No user logged in');
        throw Exception('No user logged in');
      }
    } catch (e) {
      print('Error saving emotion data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving emotion data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupAnimation() {
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

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
  }

  void _resetState() {
    setState(() {
      _showResults = false;
      _showAvatar = true;
      _isRecording = false;
      _isAnalyzing = false;
      _recordedFilePath = null;
      _analysisResult = null;
    });
    _animationController.stop();
    _animationController.reset();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
  
  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startRecordingProcess() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/audio_recording.wav';
      
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      
      setState(() {
        _isRecording = true;
        _showAvatar = false;
        _showResults = false;
        _analysisResult = null;
        _recordedFilePath = path;
      });
      
      _animationController.forward();
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isRecording = false;
        _showAvatar = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
        _showAvatar = false;
      });
      
      _animationController.stop();
      _animationController.reset();

      if (_recordedFilePath != null) {
        await _analyzeAudio(_recordedFilePath!);
      }

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _isAnalyzing = false;
        _showAvatar = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping recording: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzeAudio(String path) async {
    if (!mounted) return;

    try {
      setState(() {
        _isAnalyzing = true;
        _showAvatar = false;
        _showResults = false;
        _analysisResult = null;
      });

      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Audio file not found');
      }

      final response = await ApiService.uploadAudio(path);
      
      if (!mounted) return;

      if (response.status == 'error') {
        throw Exception(response.error ?? 'Analysis failed');
      }

      // Before saving emotion data
      print('Analysis complete, attempting to save emotion data...');

      // Save emotion data to Firebase
      if (response.result != null) {
        await _saveEmotionData(
          response.result!.predictedEmotion,
          response.result!.probabilities,
        );
      }

      setState(() {
        _isAnalyzing = false;
        _showResults = true;
        _showAvatar = false;
        _analysisResult = response;
      });

    } catch (e) {
      if (!mounted) return;

      print('Analysis error: $e');
      setState(() {
        _isAnalyzing = false;
        _showAvatar = true;
        _showResults = false;
        _analysisResult = null;
      });

      _showErrorSnackBar(e.toString(), path);
    }
  }

  Widget _buildEmotionResults() {
    if (_analysisResult?.result == null) {
      return const SizedBox.shrink();
    }
    
    final result = _analysisResult!.result!;
    final sortedEmotions = result.probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFF7C77B9),
      const Color(0xFF8BBABB),
      const Color(0xFFBE9FE1),
      const Color(0xFFEDB1F1),
      const Color(0xFFFFCBC1),
      const Color(0xFFC4D7B2),
      const Color(0xFFA0BFE0),
      const Color(0xFFFFB4B4),
    ];

    final isNeutralEmotion = result.predictedEmotion.toLowerCase() == 'neutral';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Detected Emotion: ${result.predictedEmotion.toUpperCase()}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(
                      sortedEmotions.length,
                      (index) {
                        final emotion = sortedEmotions[index];
                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: emotion.value,
                          title: '${(emotion.value * 100).toInt()}%',
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(
              sortedEmotions.length,
              (index) {
                final emotion = sortedEmotions[index];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      emotion.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          if (!isNeutralEmotion)
            EmotionResourcesWidget(emotion: result.predictedEmotion.toLowerCase()),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String errorMessage, String audioPath) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis Error',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () => _analyzeAudio(audioPath),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Send notification about emotion update
  Future<void> _sendEmotionNotification() async {
    try {
      if (widget.elderId == null) return;
      
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Get caregiver's name
      final caregiverDoc = await _firestore.collection('users').doc(user.uid).get();
      final caregiverName = caregiverDoc.data()?['name'] ?? 'Your caregiver';
      
      // Get elder's name
      final elderDoc = await _firestore.collection('users').doc(widget.elderId).get();
      final elderName = elderDoc.data()?['name'] ?? 'Elder';
      
      // Create notification for the elder
      await _firestore
          .collection('users')
          .doc(widget.elderId)
          .collection('notifications')
          .add({
        'type': 'emotion',
        'title': 'Emotion Update',
        'message': '$caregiverName has recorded your mood as ${_analysisResult?.result?.predictedEmotion ?? "unknown"}',
        'color': Colors.blue.value,
        'textColor': Colors.white.value,
        'icon': 'mood',
        'iconColor': Colors.white.value,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      print('Emotion notification sent to elder: $elderName');
    } catch (e) {
      print('Error sending emotion notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B84DC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,  // Don't apply bottom padding since we handle it manually
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const BloomCareHomePage()),
                    );
                  },
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingUser)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Text(
                      'Hello ${_userName ?? "User"}',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!_showResults && !_isAnalyzing)
                    const Text(
                      'Lets check your Emotion status',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    if (_showAvatar)
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
                    if (_isAnalyzing)
                      Column(
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
                    if (_showResults)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildEmotionResults(),
                      ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRecording) ...[
                    GestureDetector(
                      onTap: _stopRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.7),
                        ),
                        child: const Icon(
                          Icons.stop,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRecording ? _scaleAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: () {
                            if (_showResults) {
                              _resetState();
                            } else if (!_isRecording) {
                              _startRecordingProcess();
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: -1),
    );
  }
}

