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
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _buildDailyActivitiesContent(),
      bottomNavigationBar: const BottomNav(currentIndex: 0), // Added BottomNav with currentIndex 0
    );
  }

  // Daily activities content
  Widget _buildDailyActivitiesContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with curved bottom
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF8FA2E6),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Today, ${_getFormattedDate()}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // Meal Planning Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Meal Plan', Icons.restaurant),
                const SizedBox(height: 15),
                ...mealPlans.map((meal) => _buildMealItem(meal)).toList(),

                // Add meal button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    onTap: () {
                      // Add functionality to add new meal
                      setState(() {
                        mealPlans.add(MealPlan(
                          time: "Time",
                          mealType: "Meal Type",
                          description: "Description",
                          isCompleted: false,
                        ));
                      });
                    },
