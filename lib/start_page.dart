import 'package:flutter/material.dart';
import 'package:shourk_application/expert/expert_login.dart'; // Import expert login
import 'package:shourk_application/expert/home/expert_home_screen.dart';
import 'package:shourk_application/user/user_login.dart'; // Import user login
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Enhanced 3D Logo/App Name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 3D Text Effect for SHOURK
                      Stack(
                        children: [
                          // Shadow layers for 3D effect
                          Transform.translate(
                            offset: const Offset(3, 3),
                            child: const Text(
                              'SHOURK',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(2, 2),
                            child: const Text(
                              'SHOURK',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(1, 1),
                            child: const Text(
                              'SHOURK',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFCBD5E1),
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          // Main text
                          const Text(
                            'SHOURK',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 3,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Enhanced Subtitle
                const Text(
                  'Choose Your Role',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Enhanced Inspirational Quote
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Text(
                    '"Every expert was once a beginner.\nEvery pro was once an amateur.\nEvery icon was once an unknown."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF64748B),
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Enhanced Expert Button with Selection State
                Container(
                  width: double.infinity,
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: selectedRole == 'expert' 
                        ? const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selectedRole == 'expert' ? null : Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    border: selectedRole == 'expert' 
                        ? null 
                        : Border.all(color: const Color(0xFF3B82F6), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: selectedRole == 'expert' 
                            ? const Color(0xFF3B82F6).withOpacity(0.3)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                   onPressed: () async {
  setState(() {
    selectedRole = 'expert';
  });

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('expertToken');

  if (token != null) {
    final response = await http.post(
      Uri.parse('https://amd-api.code4bharat.com/api/expertauth/refresh-token'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Token is valid, proceed
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ExpertHomeScreen()),
      );
    } else {
      // Token invalid, remove and redirect to login
      await prefs.remove('expertToken');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  } else {
    // No token, redirect to login
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
},

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: selectedRole == 'expert' 
                          ? Colors.white 
                          : const Color(0xFF3B82F6),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology_outlined, size: 26),
                        SizedBox(width: 16),
                        Text(
                          'I am an Expert',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Enhanced User Button with Selection State
                Container(
                  width: double.infinity,
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: selectedRole == 'user' 
                        ? const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selectedRole == 'user' ? null : Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    border: selectedRole == 'user' 
                        ? null 
                        : Border.all(color: const Color(0xFF3B82F6), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: selectedRole == 'user' 
                            ? const Color(0xFF3B82F6).withOpacity(0.3)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedRole = 'user';
                      });
                      // Navigate to User Login
                      Future.delayed(const Duration(milliseconds: 200), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserLogin()),
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: selectedRole == 'user' 
                          ? Colors.white 
                          : const Color(0xFF3B82F6),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, size: 26),
                        SizedBox(width: 16),
                        Text(
                          'I need consultation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Enhanced Footer text
                const Text(
                  'Welcome to Shourk Consultancy',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Example usage in main.dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shourk Consultancy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StartPage(),
    );
  }
}