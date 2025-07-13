import 'package:flutter/material.dart';
import 'package:shourk_application/user/home/home_screen.dart'; // Update with actual paths
// import 'package:shourk_application/user/video_call/user_video_call.dart';
import 'package:shourk_application/user/profile/user_profile_screen.dart';

class UserBottomNavbar extends StatefulWidget {
  final int currentIndex;

  const UserBottomNavbar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<UserBottomNavbar> createState() => _UserBottomNavbarState();
}

class _UserBottomNavbarState extends State<UserBottomNavbar> {
  Future<void> _navigateToPage(int index) async {
    // Prevent re-navigation to current page
    if (index == widget.currentIndex) return;

    Widget destination;
    
    switch (index) {
      case 0:
        destination = const HomeScreen(); // Update with your actual home screen
        break;
      // case 1:
      //   destination = const UserVideoCallPage(); // Update with your actual video call screen
      //   break;
      case 2:
        destination = const UserProfileScreen(); // Update with your actual profile screen
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: _navigateToPage,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_call),
          label: 'Video Call',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}