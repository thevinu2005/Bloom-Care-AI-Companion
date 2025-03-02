import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'emotion_response.dart';

class ApiService {
  // Updated baseUrl getter with proper Android emulator IP
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Use 10.0.2.2 for Android emulator to access host machine
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // Use localhost for iOS simulator
      return 'http://localhost:8000';
    }
    // Use localhost for web or desktop
    return 'http://127.0.0.1:8000';
  }

  static const int maxRetries = 3;
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration requestTimeout = Duration(seconds: 30);

  static Future<EmotionResponse> uploadAudio(String filePath, {int retryCount = 0}) async {
    // First check server status
    if (!await testConnection()) {
      print('❌ Server connection failed');
      return EmotionResponse(
        status: 'error',
        error: 'Cannot connect to server. Please check if it\'s running.'
      );
    }

    try {
      print('✅ Server connection successful, attempting upload');
      return await _attemptUpload(filePath);
    } catch (e) {
      if (retryCount < maxRetries) {
        print('🔄 Retry attempt ${retryCount + 1} of $maxRetries');
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return uploadAudio(filePath, retryCount: retryCount + 1);
      }
      return EmotionResponse(
        status: 'error',
        error: 'Failed after $maxRetries attempts: $e'
      );
    }
  }

  static Future<EmotionResponse> _attemptUpload(String filePath) async {
    final validationResult = await _validateAudioFile(filePath);
    if (validationResult != null) {
      return EmotionResponse(
        status: 'error',
        error: validationResult
      );
    }

    final uri = Uri.parse('$baseUrl/analyze-audio');
    final request = http.MultipartRequest('POST', uri);
    
    try {
      final file = File(filePath);
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: 'audio_recording.wav'
      );
      
      request.files.add(multipartFile);

      print('📤 Uploading audio to ${uri.toString()}');
      print('File size: ${await file.length()} bytes');

      final streamedResponse = await request.send().timeout(
        requestTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Request timed out after ${requestTimeout.inSeconds} seconds'
          );
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response received - Status: ${response.statusCode}');
      await _logResponse(response);

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['status'] == 'success' && jsonResponse['result'] != null) {
            return EmotionResponse.fromJson(jsonResponse);
          } else {
            return EmotionResponse(
              status: 'error',
              error: jsonResponse['error'] ?? 'Invalid response format'
            );
          }
        } catch (e) {
          print('❌ JSON parsing error: $e');
          print('Raw response: ${response.body}');
          return EmotionResponse(
            status: 'error',
            error: 'Invalid response format from server'
          );
        }
      } else {
        return _handleErrorResponse(response);
      }
    } on SocketException catch (e) {
      print('❌ Socket error: ${e.message}');
      return EmotionResponse(
        status: 'error',
        error: _formatConnectionError(e)
      );
    } on TimeoutException {
      print('❌ Request timed out');
      return EmotionResponse(
        status: 'error',
        error: 'The server took too long to respond. Please try again.'
      );
    } catch (e) {
      print('❌ Unexpected error: $e');
      return EmotionResponse(
        status: 'error',
        error: 'An unexpected error occurred: $e'
      );
    }
  }

  static Future<String?> _validateAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return 'Audio file not found: $filePath';
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        return 'Audio file is empty';
      }

      if (fileSize > 10 * 1024 * 1024) {
        return 'Audio file too large (max 10MB)';
      }

      if (!filePath.toLowerCase().endsWith('.wav')) {
        return 'Invalid file format. Only WAV files are supported';
      }

      return null;
    } catch (e) {
      return 'Error validating audio file: $e';
    }
  }

  static Future<bool> testConnection() async {
    try {
      print('🔍 Testing connection to $baseUrl');
      
      // First try root endpoint
      final rootUri = Uri.parse('$baseUrl');
      try {
        final rootResponse = await http.get(rootUri).timeout(connectionTimeout);
        if (rootResponse.statusCode == 200) {
          print('✅ Root endpoint accessible');
          return true;
        }
      } catch (e) {
        print('⚠️ Root endpoint not accessible: $e');
      }
      
      // Try health endpoint
      final healthUri = Uri.parse('$baseUrl/health');
      try {
        final response = await http.get(healthUri).timeout(connectionTimeout);
        final isSuccess = response.statusCode == 200;
        print(isSuccess ? '✅ Health check successful' : '❌ Health check failed');
        return isSuccess;
      } catch (e) {
        print('❌ Health check failed: $e');
        return false;
      }
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  static String _formatConnectionError(SocketException e) {
    final platform = Platform.isAndroid ? 'Android Emulator' : 
                    Platform.isIOS ? 'iOS Simulator' : 
                    'this device';
    
    return '''Unable to connect to the server. Please check:
1. The server is running (python main.py)
2. The server is accessible from $platform
3. You're using the correct address ($baseUrl)
4. Your device has internet access
5. No firewall is blocking the connection

Technical details: ${e.message}''';
  }

  static EmotionResponse _handleErrorResponse(http.Response response) {
    String message;
    
    try {
      final body = json.decode(response.body);
      message = body['error'] ?? body['detail'] ?? 'Unknown server error';
    } catch (e) {
      message = response.body.isNotEmpty ? response.body : 'Empty response from server';
    }

    return EmotionResponse(
      status: 'error',
      error: 'Server error (${response.statusCode}): $message'
    );
  }

  static Future<void> _logResponse(http.Response response) async {
    print('📊 Response Details:');
    print('Status Code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    
    try {
      if (response.body.isNotEmpty) {
        final jsonBody = json.decode(response.body);
        print('Body: ${json.encode(jsonBody)}');
      } else {
        print('Body: Empty response');
      }
    } catch (e) {
      print('Failed to parse response body: $e');
      print('Raw body: ${response.body}');
    }
  }
}

