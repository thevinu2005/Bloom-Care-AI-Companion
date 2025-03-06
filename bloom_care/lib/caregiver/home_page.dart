import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'bottom_nav.dart';
import 'patient_details_page.dart';
import 'caregiver_profile_page.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({Key? key}) : super(key: key);

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  final String caregiverName = "Sarah";

  // Made patients list mutable to allow adding new patients
  List<Map<String, dynamic>> patients = [
    {
      "name": "John Smith",
      "age": 72,
      "condition": "Post-Surgery Recovery",
      "gender": "Male",
      "dateOfBirth": "1951-05-15",
      "image": "assets/patient1.png",
    },
    {
      "name": "Mary Johnson",
      "age": 65,
      "condition": "Chronic Pain",
      "gender": "Female",
      "dateOfBirth": "1958-09-22",
      "image": "assets/patient2.png",
    },
    {
      "name": "Robert Davis",
      "age": 78,
      "condition": "Diabetes Management",
      "gender": "Male",
      "dateOfBirth": "1945-11-10",
      "image": "assets/patient3.png",
    },
  ];

  final List<Map<String, dynamic>> upcomingTasks = [
    {
      "title": "Medication Reminder",
      "patient": "John Smith",
      "time": "10:30 AM",
      "isUrgent": true,
    },
    {
      "title": "Physical Therapy",
      "patient": "Mary Johnson",
      "time": "1:15 PM",
      "isUrgent": false,
    },
    {
      "title": "Vital Signs Check",
      "patient": "Robert Davis",
      "time": "3:00 PM",
      "isUrgent": false,
    },
  ];
