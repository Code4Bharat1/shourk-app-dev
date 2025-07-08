import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';

class ExpertScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;

  const ExpertScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ExpertUpperNavbar(), // ✅ Your custom top navbar
      body: body,
      bottomNavigationBar: ExpertBottomNavbar(currentIndex: currentIndex), // ✅ Bottom nav
    );
  }
}
