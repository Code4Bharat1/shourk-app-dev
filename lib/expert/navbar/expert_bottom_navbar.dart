import 'package:flutter/material.dart';
import 'package:shourk_application/expert/home/expert_home_screen.dart';

// Import your pages
import 'package:shourk_application/expert/profile/expert_profile_screen.dart';
import 'package:shourk_application/expert/navbar/expert_dashboard.dart';
import 'package:shourk_application/expert/navbar/video_call.dart';
import 'package:shourk_application/expert/navbar/expert_main.dart';


class ExpertBottomNavbar extends StatefulWidget {
  final int currentIndex;

  const ExpertBottomNavbar({
    super.key,
    required this.currentIndex,
  });

  @override
  State<ExpertBottomNavbar> createState() => _ExpertBottomNavbarState();
}

class _ExpertBottomNavbarState extends State<ExpertBottomNavbar> {
  void _navigateToPage(int index) {
    Widget? destination;

    switch (index) {
      case 0:
        destination = const VideoCallScreen();
        break;
      case 1:
        destination = const ExpertProfilePage();
        break;
      case 2:
        destination = const ExpertHomeScreen(); // Or ExpertMainScreen
        break;
      case 3:
        destination = const ExpertDashboardPage();
        break;
    }

    if (destination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: _navigateToPage,
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
