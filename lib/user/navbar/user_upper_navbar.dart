import 'package:flutter/material.dart';
import 'package:shourk_application/user/profile/user_giftcard.dart';
import 'package:shourk_application/expert/navbar/expert_serach_screen.dart';
import 'package:shourk_application/user/profile/user_profile_screen.dart';

class UserUpperNavbar extends StatelessWidget implements PreferredSizeWidget {
  const UserUpperNavbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFCFAF6),
      elevation: 0,
      titleSpacing: 0,    
      title: Row(
        children: [
          const Text(
            'Shourk',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 21,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpertSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGiftCardSelectPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
