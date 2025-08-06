import 'package:flutter/material.dart';
import 'package:shourk_application/expert/home/expert_home_screen.dart';
// import 'package:shourk_application/expert/profile/edit_profile_screen.dart';
import 'package:shourk_application/expert/profile/expert_profile_screen.dart';
import 'package:shourk_application/expert/navbar/expert_dashboard.dart';
import 'package:shourk_application/expert/navbar/video_call.dart';
// import 'package:shourk_application/expert/navbar/expert_main.dart';
import 'package:shourk_application/expert/profile/expert_profile_settings.dart';

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> _navigateToPage(int index) async {
    Widget? destination;

    // Retrieve expertId if needed
    String? expertId;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('expertToken');
    if (token != null) {
      try {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        expertId = decodedToken['_id'];
      } catch (e) {
        print("Error decoding token: $e");
      }
    }

    switch (index) {
      case 0:
        destination = ExpertHomeScreen();
        break;
      case 1:
        destination = VideoCallPage();
        break;
      case 2:
        destination = const ExpertProfilePage();
        break;
      case 3:
        destination = ProfileSettingsScreen(expertId: expertId ?? '');

        break;
      case 4:
        destination =  DashboardScreen(); // Assuming this is the Expert page
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
      onTap: (index) {
        if (index == 5) {
          _showLogoutConfirmation(context);
        } else {
          _navigateToPage(index);
        }
      },
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
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'Logout',
        ),
      ],
    );
  }

// Add this helper method for logout confirmation
void _showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);  // Close the dialog first
            // Call your logout function here if needed
            // await AuthService().logout();
            
            // Navigate to /start route and remove all previous routes
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/start',
              (route) => false,  // This removes all previous routes
            );
          },
          child: const Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
}
