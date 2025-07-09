import 'package:flutter/material.dart';

class UserBottomNavbar extends StatefulWidget {
  const UserBottomNavbar({Key? key}) : super(key: key);

  @override
  State<UserBottomNavbar> createState() => _UserBottomNavbarState();
}

class _UserBottomNavbarState extends State<UserBottomNavbar> {
  int _currentIndex = 0;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigation logic based on index
    switch (index) {
      case 0:
        // Navigate to Search page
        Navigator.pushNamed(context, '/search');
        break;
      case 1:
        // Navigate to Video Call page
        Navigator.pushNamed(context, '/video_call');
        break;
      case 2:
        // Navigate to Profile page
        Navigator.pushNamed(context, '/user-profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTap,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.black,
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
