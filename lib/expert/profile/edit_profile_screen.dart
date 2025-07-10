import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
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
        Uri.parse('$baseUrl/$expertId'), // Correct endpoint
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _mobileController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch profile.')),
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

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');

      if (token == null) return;

      final decodedToken = JwtDecoder.decode(token);
      final expertId = decodedToken['_id'];

      final response = await http.put(
        Uri.parse('http://localhost:5070/api/expertauth/updateexpert/$expertId'), // Updated URL
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _mobileController.text.trim(),
          'email': _emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ExpertUpperNavbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(  
                children: [
                  _buildTextField("First Name", _firstNameController),
                  const SizedBox(height: 16),
                  _buildTextField("Last Name", _lastNameController),
                  const SizedBox(height: 16),
                  _buildTextField("Mobile Number", _mobileController),
                  const SizedBox(height: 16),
                  _buildTextField("Email", _emailController),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Save", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
