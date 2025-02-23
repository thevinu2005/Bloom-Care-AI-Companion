import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'YOUR_BACKEND_URL'; // Replace with your backend URL

  static Future<Map<String, dynamic>> uploadAudio(String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze-mood');
      final request = http.MultipartRequest('POST', uri);
      
      
      final file = await http.MultipartFile.fromPath(
        'audio',
        filePath,
        filename: 'audio_recording.wav',
      );
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to upload audio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading audio: $e');
    }
      
      
  }
}