import 'package:flutter/material.dart';
import 'user/home/home_screen.dart'; // ← Correct import path

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shourk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      ),
      home: const HomeScreen(), // ← This must point to HomeScreen
    );
  }
}
