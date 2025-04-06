class Question {
  final String id;
  final String text;
  final String type;
  final List<String> options;
  final String emoji;
  final String category;
  final dynamic correctAnswer; // Can be int, String, or List<int> depending on question type

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.options = const [],
    required this.emoji,
    required this.category,
    required this.correctAnswer,
  });

  // Factory constructor to create a Question from JSON
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      type: json['type'] as String,
      options: json['options'] != null 
          ? List<String>.from(json['options']) 
          : [],
      emoji: json['emoji'] as String,
      category: json['category'] as String,
      correctAnswer: json['correctAnswer'],
    );
  }

  // Method to convert Question to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'options': options,
      'emoji': emoji,
      'category': category,
      'correctAnswer': correctAnswer,
    };
  }
}

