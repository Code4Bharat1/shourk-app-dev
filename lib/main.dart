import 'package:flutter/material.dart';
import 'package:shourk_application/login.dart';
import 'package:shourk_application/user/home/home_screen.dart';
import 'register_page.dart'; // Make sure this matches your filename
import 'login.dart';
import 'expert/sessions/book_session.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Register Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
