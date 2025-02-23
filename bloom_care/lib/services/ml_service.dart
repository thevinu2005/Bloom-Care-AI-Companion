import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'YOUR_BACKEND_URL'; // Replace with your backend URL

  static Future<Map<String, dynamic>> uploadAudio(String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze-mood');
      final request = http.MultipartRequest('POST', uri);
      
      
    
      request.files.add(file);

      
      
  }
}