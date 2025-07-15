import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shourk_application/expert/expert_register.dart';
import 'package:shourk_application/expert/home/expert_home_screen.dart';
import '../user/user_register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shourk_application/user/home/home_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({Key? key}) : super(key: key);

  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isPhoneMode = false;
  String _phoneNumber = '';

  // Updated base URL - replace with your actual backend URL
  // For testing on physical device, use your computer's IP address or ngrok
  final String baseUrl = "http://localhost:5070/api/userauth"; // Updated to match your video call page

  void _toggleInputMode() {
    setState(() {
      _isPhoneMode = !_isPhoneMode;
      _emailController.clear();
      _phoneNumber = '';
      _otpController.clear();
    });
  }

  void _sendOtp() async {
    String contactInfo = _isPhoneMode ? _phoneNumber : _emailController.text;

    if (contactInfo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter ${_isPhoneMode ? 'phone number' : 'email'}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/request-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          _isPhoneMode ? 'phone' : 'email': contactInfo,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to $contactInfo'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: ${errorData['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: Please check your connection'),
          backgroundColor: Colors.red,
        ),
      );
      print('Send OTP Error: $e');
    }
  }

  void _proceed() async {
    String contactInfo = _isPhoneMode ? _phoneNumber : _emailController.text;
    String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          _isPhoneMode ? 'phone' : 'email': contactInfo,
          'otp': otp,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if user exists
        if (responseData['data']['isNewUser'] == true) {
          // New user - navigate to registration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserRegister()),
          );
        } else {
          // Existing user - save token and go to home
          final token = responseData['data']['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userToken', token);

          // Also save refresh token if available
          if (responseData['data']['refreshToken'] != null) {
            await prefs.setString('userRefreshToken', responseData['data']['refreshToken']);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid OTP: ${errorData['message'] ?? 'Please try again'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: Please check your connection'),
          backgroundColor: Colors.red,
        ),
      );
      print('Proceed Error: $e');
    }
  }

  // Add refresh token functionality
  Future<void> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('userRefreshToken');
    
    if (refreshToken == null) {
      print("No refresh token found");
      Navigator.pushReplacementNamed(context, '/userlogin');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newToken = responseData['data']['token'];
        
        await prefs.setString('userToken', newToken);
        print("Token refreshed successfully");
        
        // Update the token in your current context if needed
        // You might want to call setState here if needed
        
      } else {
        print("Token refresh failed: ${response.statusCode}");
        await prefs.remove('userToken');
        await prefs.remove('userRefreshToken');
        Navigator.pushReplacementNamed(context, '/userlogin');
      }
    } catch (e) {
      print("Token refresh error: $e");
      await prefs.remove('userToken');
      await prefs.remove('userRefreshToken');
      Navigator.pushReplacementNamed(context, '/userlogin');
    }
  }

  // Check if user is already logged in
  Future<void> _checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    
    if (token != null) {
      try {
        // Check if token is expired
        if (JwtDecoder.isExpired(token)) {
          await _refreshToken();
        } else {
          // Token is valid, navigate to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        print("Error checking existing login: $e");
        // Clear invalid token
        await prefs.remove('userToken');
        await prefs.remove('userRefreshToken');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SHOURK',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'Login to Your Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Email or Phone Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPhoneMode ? 'Phone Number' : 'Email',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isPhoneMode)
                    IntlPhoneField(
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        _phoneNumber = phone.completeNumber;
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _toggleInputMode,
                child: Text(
                  _isPhoneMode ? 'Use email instead' : 'Use phone number instead',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Send OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'OTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter OTP',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Proceed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/user-register');
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: "Register here",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}