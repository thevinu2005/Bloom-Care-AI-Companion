import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';


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
  bool _isAnalyzing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  final _audioRecorder = AudioRecorder();
  String? _recordedFilePath;
  Map<String, dynamic>? _analysisResult;

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

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    _requestPermissions();
  }

  void _resetState() {
  setState(() {
    _showChart = false;
    _showAvatar = true;
    _isRecording = false;
    _recordedFilePath = null;
    _analysisResult = null;
    _isAnalyzing = false;
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
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio'),
          ),
        );
      }
    }
  }

  Future<void> _startRecordingProcess() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_recording.m4a';
        
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        
        setState(() {
          _isRecording = true;
          _showAvatar = false; // Only hide avatar when recording starts successfully
          _showChart = false;
          _analysisResult = null;
          _recordedFilePath = path;
        });
        
        _animationController.forward();
      } else {
        if (mounted) {
          // Keep avatar visible during permission error
          setState(() {
            _isRecording = false;
            _showAvatar = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission not granted'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Keep avatar visible during error
        setState(() {
          _isRecording = false;
          _showAvatar = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      try {
        await _audioRecorder.stop();
        
        setState(() {
          _isRecording = false;
          _isAnalyzing = true;
          _showAvatar = false; // Keep avatar hidden during analysis
        });
        
        _animationController.stop();
        _animationController.reset();

        if (_recordedFilePath != null) {
          await _uploadAndAnalyzeAudio(_recordedFilePath!);
        }

      } catch (e) {
        setState(() {
          _isRecording = false;
          _isAnalyzing = false;
          _showAvatar = true; // Show avatar on error
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error stopping recording: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _uploadAndAnalyzeAudio(String path) async {
    try {
      final uri = Uri.parse('YOUR_BACKEND_URL/analyze-mood');
      final request = http.MultipartRequest('POST', uri);
      
      final file = await http.MultipartFile.fromPath(
        'audio',
        path,
        filename: 'audio_recording.m4a',
      );
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _showChart = true;
            _showAvatar = false; // Keep avatar hidden when showing chart
            _analysisResult = result;
          });
        }
      } else {
        throw Exception('Failed to upload audio: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _showAvatar = true; // Show avatar on error
          _showChart = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update the build method to ensure avatar visibility is properly handled
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B84DC),
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20),
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
            
            // Header Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello Imsarie',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_showChart && !_isAnalyzing)
                    const Text(
                      'How may I Assist you today?',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),

            // Avatar or Chart Section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showAvatar) // Only show avatar when _showAvatar is true
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
                  if (_showChart && _analysisResult != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: _analysisResult?['positive_score'] ?? 75,
                              title: 'Good\n${_analysisResult?['positive_score']}%',
                              radius: 100,
                              titleStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.red,
                              value: _analysisResult?['negative_score'] ?? 25,
                              title: 'Bad\n${_analysisResult?['negative_score']}%',
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
                ],
              ),
            ),

            // Recording Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
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
                            if (_showChart) {
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
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
      ),
    );
  }
}