import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String name;
  final String type; // 'meal', 'appointment', 'hobby', 'exercise', etc.
  final String category; // For meals: 'breakfast', 'lunch', 'dinner', etc.
  final String time;
  final String duration;
  final String notes;
  final Map<String, dynamic> additionalDetails; // For type-specific details
  bool isCompleted;
  
  Activity({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.time,
    this.duration = '',
    this.notes = '',
    this.additionalDetails = const {},
    this.isCompleted = false,
  });

  // Factory method to create from Firestore data
  factory Activity.fromFirestore(String id, Map<String, dynamic> data) {
    return Activity(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'other',
      category: data['category'] ?? '',
      time: data['time'] ?? '',
      duration: data['duration'] ?? '',
      notes: data['notes'] ?? '',
      additionalDetails: Map<String, dynamic>.from(data['additionalDetails'] ?? {}),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'category': category,
      'time': time,
      'duration': duration,
      'notes': notes,
      'additionalDetails': additionalDetails,
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

