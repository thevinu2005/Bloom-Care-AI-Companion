// lib/services/emotion_response.dart
class EmotionResponse {
  final String status;
  final String? error;
  final EmotionResult? result;

  EmotionResponse({
    required this.status,
    this.error,
    this.result,
  });

  factory EmotionResponse.fromJson(Map<String, dynamic> json) {
    try {
      if (json['status'] == 'error') {
        return EmotionResponse(
          status: 'error',
          error: json['error']?.toString(),
        );
      }

      return EmotionResponse(
        status: json['status'],
        result: json['result'] != null 
            ? EmotionResult.fromJson(json['result'])
            : null,
      );
    } catch (e) {
      print('Error parsing EmotionResponse: $e');
      return EmotionResponse(
        status: 'error',
        error: 'Failed to parse response: $e',
      );
    }
  }

  bool get isSuccess => status == 'success' && result != null;
}

class EmotionResult {
  final String predictedEmotion;
  final Map<String, double> probabilities;

  EmotionResult({
    required this.predictedEmotion,
    required this.probabilities,
  });

  factory EmotionResult.fromJson(Map<String, dynamic> json) {
    try {
      final probMap = (json['probabilities'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );

      return EmotionResult(
        predictedEmotion: json['predicted_emotion'],
        probabilities: probMap,
      );
    } catch (e) {
      print('Error parsing EmotionResult: $e');
      throw FormatException('Invalid emotion result format: $e');
    }
  }
}