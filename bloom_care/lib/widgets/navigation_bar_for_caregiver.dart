import 'package:flutter/material.dart';

class CaregiverNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CaregiverNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: const Color(0xFF4B7BFF),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assest/icons/home_icon.png',
              width: 24,
              height: 24,
              color: currentIndex == 0 ? const Color(0xFF4B7BFF) : Colors.grey,
            ),
            activeIcon: Image.asset(
              'assest/icons/home_icon.png',
              width: 24,
              height: 24,
              color: const Color(0xFF4B7BFF),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assest/icons/notification_icon.png',
              width: 24,
              height: 24,
              color: currentIndex == 3 ? const Color(0xFF4B7BFF) : Colors.grey,
            ),
            activeIcon: Image.asset(
              'assest/icons/notification_icon.png',
              width: 24,
              height: 24,
              color: const Color(0xFF4B7BFF),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assest/icons/profile_icon.png',
              width: 24,
              height: 24,
              color: currentIndex == 4 ? const Color(0xFF4B7BFF) : Colors.grey,
            ),
            activeIcon: Image.asset(
              'assest/icons/profile_icon.png',
              width: 24,
              height: 24,
              color: const Color(0xFF4B7BFF),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}

