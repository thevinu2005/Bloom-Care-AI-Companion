import 'package:flutter/material.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';

class EmergencyServicesScreen extends StatefulWidget {
  const EmergencyServicesScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyServicesScreen> createState() => _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends State<EmergencyServicesScreen> {
  int _currentIndex = 1; // Set to 1 for the Emergency tab

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index != 1) {
      // If not on the Emergency tab, pop this screen and return to previous
      Navigator.pop(context);
    }
    // Add navigation logic for other tabs if needed
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle the back button press
        Navigator.pop(context);
        return false; // Prevents default back button behavior
      },
      child: Scaffold(
        body: Container(
          color: Color(0xFFE85D5D), // Red background color matching the design
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Emergency Services',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Add a SizedBox to balance the layout
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Image.asset(
                        'assest/images/emergancy.png', // Make sure this asset exists
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: ElevatedButton(
                    onPressed: () {
                      // You might want to add some action here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFFE85D5D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Starting',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavItemTapped,
        ),
      ),
    );
  }
}