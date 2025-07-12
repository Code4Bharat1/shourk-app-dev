import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';

class EnableFreeSessionScreen extends StatefulWidget {
  const EnableFreeSessionScreen({super.key});

  @override
  State<EnableFreeSessionScreen> createState() => _EnableFreeSessionScreenState();
}

class _EnableFreeSessionScreenState extends State<EnableFreeSessionScreen> {
  bool _isFreeSessionEnabled = false;
  bool _isLoading = true;

  final String baseUrl = "http://localhost:5070/api/expertauth"; // Define baseUrl

  @override
  void initState() {
    super.initState();
    _fetchExpertProfile();
  }

  Future<void> _fetchExpertProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found. Please login again.')),
        );
        Navigator.pop(context);
        return;
      }

      final decodedToken = JwtDecoder.decode(token);
      final expertId = decodedToken['_id'];

      final response = await http.get(
        Uri.parse('$baseUrl/$expertId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _isFreeSessionEnabled = data['freeSessionEnabled'] ?? false;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch profile.')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEligibility(String userId, String expertId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check-eligibility/$userId/$expertId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle eligibility check response if needed
        print('Eligibility check result: $data');
      } else {
        print('Failed to check eligibility: ${response.body}');
      }
    } catch (e) {
      print('Error checking eligibility: $e');
    }
  }

  Future<void> _saveFreeSessionSettings() async {
    try {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');

      if (token == null) return;

      final response = await http.put(
        Uri.parse('$baseUrl/update-free-session'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'freeSessionEnabled': _isFreeSessionEnabled,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Free session settings updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update free session settings: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Enable Free Session for New Users",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Enable Free Session Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Enable Free Session for New Users",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isFreeSessionEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isFreeSessionEnabled = value;
                          });
                        },
                        activeColor: Colors.black,
                        activeTrackColor: Colors.grey.shade300,
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade200,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Description Text
                  Text(
                    "When enabled, new users who have never booked a session with you will get their first session completely free.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    "The system will automatically check if the user has had any previous sessions with you before applying the free session benefit.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveFreeSessionSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
                bottomNavigationBar: ExpertBottomNavbar(
        currentIndex: 3,
        // onTap: (index) {
        //   // TODO: Implement navigation
        // },
      ),
    );
  }
}