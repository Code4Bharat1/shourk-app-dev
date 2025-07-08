import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'edit_profile_screen.dart'; // <-- Import your EditProfileScreen here

class ProfileSettingsScreen extends StatefulWidget {
  final String expertId;
  const ProfileSettingsScreen({Key? key, required this.expertId}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  Map<String, dynamic>? expertData;
  String bookingLink = '';
  bool copied = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExpertData();
  }

  Future<void> fetchExpertData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');

      if (token != null) {
        final decodedToken = JwtDecoder.decode(token);
        final expertId = decodedToken['_id'];
        final url = Uri.parse('http://localhost:5070/api/expertauth/$expertId');

        final response = await http.get(url, headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        });

        if (response.statusCode == 200) {
          final data = json.decode(response.body)['data'];
          setState(() {
            expertData = data;
            bookingLink = "https://www.shourk.com/expertaboutme/$expertId";
            isLoading = false;
          });
        } else {
          print("Failed to load expert data: ${response.body}");
        }
      }
    } catch (e) {
      print("Error fetching expert data: $e");
    }
  }

  Future<void> copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: bookingLink));
    setState(() => copied = true);
    Future.delayed(const Duration(seconds: 2), () => setState(() => copied = false));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking link copied!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shourk"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: expertData?['photoFile'] != null
                              ? NetworkImage(expertData!['photoFile'])
                              : const NetworkImage("https://via.placeholder.com/150"),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${expertData?['firstName'] ?? ''} ${expertData?['lastName'] ?? ''}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          expertData?['areaOfExpertise'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          expertData?['country'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Marketing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Share your booking link:"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(bookingLink, style: const TextStyle(fontSize: 14)),
                        ),
                      ),
                      IconButton(
                        icon: Icon(copied ? Icons.check_circle : Icons.copy, color: copied ? Colors.green : Colors.grey),
                        onPressed: copyToClipboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Your booking link is ready! Share this link with clients so they can book consultations with you.",
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Verification Checkmark", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    "To be considered for verification:\n\n"
                    "• Add your booking link to at least two social media bios.\n"
                    "• Complete 10+ paid bookings.\n"
                    "• Generate at least \$1,000 on the platform.\n"
                    "• Maintain a rating above 4.8.",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader("Settings"),
                  _buildBlackButtonTile(context, "Edit Profile", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  }),
                  _settingsTile(context, "Enable Charity"),
                  _settingsTile(context, "Enable Free Session for New Users"),
                  _settingsTile(context, "Edit what to Expect"),
                  _settingsTile(context, "Edit example questions"),
                  const SizedBox(height: 24),
                  _sectionHeader("Availability"),
                  _settingsTile(context, "Set my preferred availability"),
                  _settingsTile(context, "Connect my calendar"),
                  const SizedBox(height: 24),
                  _sectionHeader("Offerings"),
                  _settingsTile(context, "1:1 Video session prices"),
                  _settingsTile(context, "Available session lengths"),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _settingsTile(BuildContext context, String title, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildBlackButtonTile(BuildContext context, String title, {VoidCallback? onTap}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        onTap: onTap ?? () {},
      ),
    );
  }
}
