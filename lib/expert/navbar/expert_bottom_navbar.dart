import 'package:flutter/material.dart';

class ExpertBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;  // Added parameter

  const ExpertBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,  // Added parameter
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,  // Now using the passed callback
      selectedItemColor: Colors.yellow[800],
      unselectedItemColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search Experts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_call),
          label: 'Video Call',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_user_outlined),
          label: 'Expert',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      ],
    );
  }
}