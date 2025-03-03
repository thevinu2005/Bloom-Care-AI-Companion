import 'package:flutter/material.dart';
import 'bottom_nav.dart'; // Import the BottomNav widget

class DailyActivitiesPage extends StatefulWidget {
  const DailyActivitiesPage({super.key});

  @override
  State<DailyActivitiesPage> createState() => _DailyActivitiesPageState();
}

class _DailyActivitiesPageState extends State<DailyActivitiesPage> {
  // Sample data for meals and hobby times
  List<MealPlan> mealPlans = [
    MealPlan(
      time: "7:30 AM",
      mealType: "Breakfast",
      description: "Oatmeal with fruits",
      isCompleted: false,
    ),
    MealPlan(
      time: "12:00 PM",
      mealType: "Lunch",
      description: "Grilled chicken salad",
      isCompleted: false,
    ),
    MealPlan(
      time: "6:30 PM",
      mealType: "Dinner",
      description: "Salmon with vegetables",
      isCompleted: false,
    ),
  ];

  List<HobbyTime> hobbyTimes = [
    HobbyTime(
      time: "9:00 AM",
      activity: "Reading",
      duration: "30 minutes",
      isCompleted: false,
    ),
    HobbyTime(
      time: "3:00 PM",
      activity: "Walking",
      duration: "45 minutes",
      isCompleted: false,
    ),
    HobbyTime(
      time: "8:00 PM",
      activity: "Painting",
      duration: "60 minutes",
      isCompleted: false,
    ),
  ];

  // Sample data for upcoming appointments
  List<Appointment> appointments = [
    Appointment(
      date: "Mar 15, 2023",
      time: "10:00 AM",
      title: "Doctor Checkup",
      location: "City Hospital",
      isConfirmed: true,
    ),
    Appointment(
      date: "Mar 18, 2023",
      time: "2:30 PM",
      title: "Physical Therapy",
      location: "Wellness Center",
      isConfirmed: true,
    ),
    Appointment(
      date: "Mar 22, 2023",
      time: "11:15 AM",
      title: "Dental Appointment",
      location: "Smile Dental Clinic",
      isConfirmed: false,
    ),
  ];

  // Save changes to local storage (this is a placeholder)
  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily activities saved successfully!'),
        backgroundColor: Color(0xFF8FA2E6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD7E0FA), // Light blue background
      appBar: AppBar(
        backgroundColor: Color(0xFF8FA2E6), // App bar color
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Daily Activities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
