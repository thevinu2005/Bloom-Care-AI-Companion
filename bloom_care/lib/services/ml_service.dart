// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'emotion_response.dart';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8001';
    } else if (Platform.isIOS) {
      return 'http://localhost:8001';
    }
    return 'http://127.0.0.1:8001';
  }

  static const int maxRetries = 3;
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration requestTimeout = Duration(seconds: 30);

  static Future<EmotionResponse> uploadAudio(String filePath, {int retryCount = 0}) async {
    if (!await testConnection()) {
      return EmotionResponse(
        status: 'error',
        error: 'Cannot connect to server. Please check if it\'s running.'
      );
    }

    try {
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

    final uri = Uri.parse('$baseUrl/analyze-mood');
    final request = http.MultipartRequest('POST', uri);
    
    try {
      final multipartFile = await http.MultipartFile.fromPath(
        'audio_file',
        filePath,
        filename: 'audio_recording.wav',
      );
      request.files.add(multipartFile);

      print('📤 Uploading audio to ${uri.toString()}');

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
      return EmotionResponse(
        status: 'error',
        error: _formatConnectionError(e)
      );
    } on TimeoutException {
      return EmotionResponse(
        status: 'error',
        error: 'The server took too long to respond. Please try again.'
      );
    } catch (e) {
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
      print('🔍 Testing connection to $baseUrl/health');
      
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(
        connectionTimeout,
        onTimeout: () {
          print('❌ Connection test timed out');
          return http.Response('Timeout', 408);
        },
      );

      final isSuccess = response.statusCode == 200;
      print(isSuccess ? '✅ Connection successful' : '❌ Connection failed');
      
      return isSuccess;
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