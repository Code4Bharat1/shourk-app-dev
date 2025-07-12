import 'package:flutter/material.dart';
import './expert_serach_screen.dart'; // Add this import
import '../profile/giftcard_selection_option.dart';       // Adjust path accordingly
import '../profile/expert_profile_screen.dart'; // Adjust path accordingly

class ExpertUpperNavbar extends StatelessWidget implements PreferredSizeWidget {
  const ExpertUpperNavbar({Key? key}) : super(key: key);

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
                MaterialPageRoute(builder: (context) => const GiftCardSelectPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpertProfilePage()),
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
