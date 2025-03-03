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
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF8FA2E6), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Color(0xFF8FA2E6)),
                          SizedBox(width: 5),
                          Text(
                            'Add Meal',
                            style: TextStyle(
                              color: Color(0xFF8FA2E6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Hobby Time Section
                _buildSectionHeader('Hobby Time', Icons.sports_esports),
                const SizedBox(height: 15),
                ...hobbyTimes.map((hobby) => _buildHobbyItem(hobby)).toList(),

                // Add hobby time button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    onTap: () {
                      // Add functionality to add new hobby time
                      setState(() {
                        hobbyTimes.add(HobbyTime(
                          time: "Time",
                          activity: "Activity",
                          duration: "Duration",
                          isCompleted: false,
                        ));
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF8FA2E6), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Color(0xFF8FA2E6)),
                          SizedBox(width: 5),
                          Text(
                            'Add Hobby Time',
                            style: TextStyle(
                              color: Color(0xFF8FA2E6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Upcoming Appointments Section
                _buildSectionHeader('Upcoming Appointments', Icons.event),
                const SizedBox(height: 15),
                ...appointments.map((appointment) => _buildAppointmentItem(appointment)).toList(),

                // Add appointment button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    onTap: () {
                      // Add functionality to add new appointment
                      setState(() {
                        appointments.add(Appointment(
                          date: "Date",
                          time: "Time",
                          title: "Appointment Title",
                          location: "Location",
                          isConfirmed: false,
                        ));
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF8FA2E6), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Color(0xFF8FA2E6)),
                          SizedBox(width: 5),
                          Text(
                            'Add Appointment',
                            style: TextStyle(
                              color: Color(0xFF8FA2E6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format current date
  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // Section header widget
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8FA2E6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D77D6),
          ),
        ),
      ],
    );
  }

  // Meal item widget
  Widget _buildMealItem(MealPlan meal) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          mealPlans.remove(meal);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal plan deleted'),
            backgroundColor: Color(0xFF8FA2E6),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E0FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant,
              color: Color(0xFF8FA2E6),
            ),
          ),
          title: Text(
            meal.mealType,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D77D6),
            ),
          ),
          subtitle: Text(
            '${meal.time} - ${meal.description}',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: meal.isCompleted,
                activeColor: const Color(0xFF8FA2E6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (bool? value) {
                  setState(() {
                    meal.isCompleted = value ?? false;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[300]),
                onPressed: () {
                  _showDeleteConfirmationDialog(
                    context,
                    'Delete Meal',
                    'Are you sure you want to delete this meal plan?',
                        () {
                      setState(() {
                        mealPlans.remove(meal);
                      });
                    },
                  );
                },
              ),
            ],
          ),
          onTap: () {
            // Open edit dialog or screen
            _editMealPlan(meal);
          },
        ),
      ),
    );
  }

  // Hobby item widget
  Widget _buildHobbyItem(HobbyTime hobby) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          hobbyTimes.remove(hobby);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hobby time deleted'),
            backgroundColor: Color(0xFF8FA2E6),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E0FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sports_esports,
              color: Color(0xFF8FA2E6),
            ),
          ),
          title: Text(
            hobby.activity,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D77D6),
            ),
          ),
          subtitle: Text(
            '${hobby.time} - ${hobby.duration}',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: hobby.isCompleted,
                activeColor: const Color(0xFF8FA2E6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (bool? value) {
                  setState(() {
                    hobby.isCompleted = value ?? false;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[300]),
                onPressed: () {
                  _showDeleteConfirmationDialog(
                    context,
                    'Delete Hobby',
                    'Are you sure you want to delete this hobby time?',
                        () {
                      setState(() {
                        hobbyTimes.remove(hobby);
                      });
                    },
                  );
                },
              ),
            ],
          ),
          onTap: () {
            // Open edit dialog or screen
            _editHobbyTime(hobby);
          },
        ),
      ),
    );
  }

  // Appointment item widget
  Widget _buildAppointmentItem(Appointment appointment) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          appointments.remove(appointment);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment deleted'),
            backgroundColor: Color(0xFF8FA2E6),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E0FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event,
              color: Color(0xFF8FA2E6),
            ),
          ),
          title: Text(
            appointment.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D77D6),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${appointment.date} at ${appointment.time}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                appointment.location,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: appointment.isConfirmed
                      ? const Color(0xFFD7E0FA)
                      : Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  appointment.isConfirmed ? 'Confirmed' : 'Pending',
                  style: TextStyle(
                    color: appointment.isConfirmed
                        ? const Color(0xFF5D77D6)
                        : Colors.amber[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[300]),
                onPressed: () {
                  _showDeleteConfirmationDialog(
                    context,
                    'Delete Appointment',
                    'Are you sure you want to delete this appointment?',
                        () {
                      setState(() {
                        appointments.remove(appointment);
                      });
                    },
                  );
                },
              ),
            ],
          ),
          onTap: () {
            // Open edit dialog or screen
            _editAppointment(appointment);
          },
        ),
      ),
    );
  }
