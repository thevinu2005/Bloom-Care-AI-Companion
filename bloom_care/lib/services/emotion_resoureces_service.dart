import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmotionResource {
  final String title;
  final String description;
  final String videoUrl;

  EmotionResource({
    required this.title,
    required this.description,
    required this.videoUrl,
  });
}

class EmotionResourcesService {
  static Map<String, List<EmotionResource>> emotionResources = {
    'sad': [
      EmotionResource(
        title: 'Overcoming Sadness',
        description: 'Learn techniques to manage feelings of sadness',
        videoUrl: 'https://www.youtube.com/watch?v=8Su5VtKeXU8',
      ),
      EmotionResource(
        title: 'Mindfulness for Sadness',
        description: 'A guided meditation to help process sad emotions',
        videoUrl: 'https://www.youtube.com/watch?v=1vx8iUvfyCY',
      ),
    ],
    'angry': [
      EmotionResource(
        title: 'Anger Management Techniques',
        description: 'Quick techniques to calm anger',
        videoUrl: 'https://www.youtube.com/watch?v=BsVq5R_F6RA',
      ),
      EmotionResource(
        title: 'Understanding Anger Triggers',
        description: 'Identify what makes you angry and how to respond',
        videoUrl: 'https://www.youtube.com/watch?v=7lE0wQBLEQc',
      ),
    ],
    'anxious': [
      EmotionResource(
        title: 'Anxiety Relief Breathing',
        description: 'Simple breathing exercises for anxiety',
        videoUrl: 'https://www.youtube.com/watch?v=odADwWzHR24',
      ),
      EmotionResource(
        title: 'Calming Anxiety Naturally',
        description: 'Natural approaches to reducing anxiety',
        videoUrl: 'https://www.youtube.com/watch?v=O-6f5wQXSu8',
      ),
    ],
    'fearful': [
      EmotionResource(
        title: 'Overcoming Fear',
        description: 'Techniques to face and overcome fears',
        videoUrl: 'https://www.youtube.com/watch?v=CmIpUqcjG3k',
      ),
      EmotionResource(
        title: 'Guided Relaxation for Fear',
        description: 'A calming exercise to reduce fear',
        videoUrl: 'https://www.youtube.com/watch?v=MR57rug8NsM',
      ),
    ],
    'disgust': [
      EmotionResource(
        title: 'Managing Feelings of Disgust',
        description: 'Understanding and processing disgust reactions',
        videoUrl: 'https://www.youtube.com/watch?v=5u528z5pR30',
      ),
    ],
    'surprise': [
      EmotionResource(
        title: 'Embracing Unexpected Changes',
        description: 'How to adapt to surprising situations',
        videoUrl: 'https://www.youtube.com/watch?v=S1F93McsI-0',
      ),
    ],
    'happy': [
      EmotionResource(
        title: 'Maintaining Happiness',
        description: 'Practices to sustain your positive mood',
        videoUrl: 'https://www.youtube.com/watch?v=GXoErccq0vw',
      ),
    ],
  };

  static List<EmotionResource> getResourcesForEmotion(String emotion) {
    return emotionResources[emotion.toLowerCase()] ?? 
           emotionResources['sad'] ?? 
           [];
  }

  static String getSupportMessage(String emotion) {
    switch(emotion.toLowerCase()) {
      case 'sad':
        return 'I notice you\'re feeling sad. Let\'s explore some resources that might help lift your spirits.';
      case 'angry':
        return 'It seems you\'re feeling angry. These videos might help you process and manage these feelings.';
      case 'anxious':
        return 'I can hear anxiety in your voice. These resources might help you feel more calm and centered.';
      case 'fearful':
        return 'It sounds like you might be experiencing fear. These videos could help you feel more secure.';
      case 'disgust':
        return 'I notice feelings of disgust in your voice. These resources might help you process these emotions.';
      case 'surprise':
        return 'You seem surprised. These resources might help you adapt to unexpected situations.';
      case 'happy':
        return 'It\'s great to hear you\'re feeling happy! Here are some resources to maintain your positive mood.';
      default:
        return 'I notice your emotions might be intense right now. These resources might help you feel better.';
    }
  }
}

