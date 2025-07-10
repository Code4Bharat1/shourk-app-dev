import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class EnableCharityScreen extends StatefulWidget {
  const EnableCharityScreen({super.key});

  @override
  State<EnableCharityScreen> createState() => _EnableCharityScreenState();
}

class _EnableCharityScreenState extends State<EnableCharityScreen> {
  final TextEditingController _charityNameController = TextEditingController();
  final TextEditingController _charityPercentageController = TextEditingController();
  bool _isCharityEnabled = false;
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
          _isCharityEnabled = data['charityEnabled'] ?? false;
          _charityNameController.text = data['charityName'] ?? '';
          _charityPercentageController.text = data['charityPercentage']?.toString() ?? '';
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

  Future<void> _saveCharitySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');

      if (token == null) return;

      final decodedToken = JwtDecoder.decode(token);
      final expertId = decodedToken['_id'];

      final response = await http.put(
        Uri.parse('$baseUrl/update-charity'),
        headers: {
          'Authorization': 'Bearer $token',
          'expertid': expertId,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'charityEnabled': _isCharityEnabled,
          'charityPercentage': int.tryParse(_charityPercentageController.text.trim()) ?? 0,
          'charityName': _charityNameController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Charity settings updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update charity settings: ${response.body}')),
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Enable Charity", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  // Enable Charity Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Enable Charity",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Switch(
                        value: _isCharityEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isCharityEnabled = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Charity Name Field
                  const Text(
                    "Name of Charity",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _charityNameController,
                    enabled: _isCharityEnabled,
                    decoration: InputDecoration(
                      hintText: "Charity",
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
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      filled: true,
                      fillColor: _isCharityEnabled ? Colors.white : Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Charity Percentage Field
                  const Text(
                    "What % of proceeds would you like to donate?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _charityPercentageController,
                    enabled: _isCharityEnabled,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "50%",
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
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      filled: true,
                      fillColor: _isCharityEnabled ? Colors.white : Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 200), // Spacer to push button to bottom
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: _saveCharitySettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
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
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _charityNameController.dispose();
    _charityPercentageController.dispose();
    super.dispose();
  }
}