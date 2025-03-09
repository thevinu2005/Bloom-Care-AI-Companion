import 'package:flutter/material.dart';

class BottomNav_for_caregivers extends StatelessWidget {
  final int currentIndex;
  final int notificationCount; // Add parameter for notification count

  const BottomNav_for_caregivers({
    Key? key,
    required this.currentIndex,
    this.notificationCount = 0, // Default to 0 if not provided
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFECEAEA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, 0, 'assest/icons/home_icon.png', '/caregiverhome'),
          _buildNavItem(context, 1, 'assest/icons/notification_icon.png', '/caregivernotification'),
          _buildNavItem(context, 2, 'assest/icons/profile_icon.png', '/profile_caregiver'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String iconPath, String routeName) {
  final isSelected = currentIndex == index;
  
  // Debug print to verify notification count
  if (index == 1) {
    print('Notification count: $notificationCount');
  }
  
  return Stack(
    clipBehavior: Clip.none,
    children: [
      GestureDetector(
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, routeName);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFD3D1D1) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 24,
                height: 24,
                color: isSelected ? Colors.black87 : Colors.black54,
              ),
            ),
          ),
        ),
      ),
      
      // Notification badge - moved outside the GestureDetector for better visibility
      if (index == 1 && notificationCount > 0)
        Positioned(
          top: 10,
          right: 5,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            constraints: const BoxConstraints(
              minWidth: 22,
              minHeight: 22,
            ),
            child: Text(
              notificationCount > 99 ? '99+' : notificationCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  );
}
}

