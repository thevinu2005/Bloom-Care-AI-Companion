import 'package:flutter/material.dart';

class BottomNav_for_caregivers extends StatelessWidget {
  final int currentIndex;

  const BottomNav_for_caregivers({
    Key? key,
    required this.currentIndex,
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
          _buildNavItem(context, 0, 'assest/icons/home_icon.png', '/home'),
          _buildNavItem(context, 1, 'assest/icons/notification_icon.png', '/caregivernotification'),
          _buildNavItem(context, 2, 'assest/icons/profile_icon.png', '/profile_caregiver'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String iconPath, String routeName) {
    final isSelected = currentIndex == index;
    return GestureDetector(
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
    );
  }
}