import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:shourk_application/expert/profile/available_session_lengths.dart';
import 'package:shourk_application/expert/profile/connect_calendar.dart';
import 'package:shourk_application/expert/profile/edit_examplequestions.dart';
import 'package:shourk_application/expert/profile/edit_whattoexpect.dart';
import 'package:shourk_application/expert/profile/enable_charity.dart';
import 'package:shourk_application/expert/profile/enable_freesession.dart';
import 'package:shourk_application/expert/profile/preferred_availability.dart';
import 'package:shourk_application/expert/profile/video_session_price.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/shared/models/expert_model.dart'; // Import your ExpertModel if needed

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
                        // Text(
                        //   expertData?['country'] ?? '',
                        //   style: const TextStyle(color: Colors.grey),
                        // ),
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
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader("Settings"),
                  _buildBlackButtonTile(context, "Edit Profile", onTap: () {
                    Navigator.push(
                      context,
                     MaterialPageRoute(
  builder: (_) => EditProfileScreen(
    expert: ExpertModel.fromJson(expertData!),
  ),
),



                    );
                  }),
                  _settingsTile(context, "Enable Charity", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EnableCharityScreen()),
                    );
                  }),
                  _settingsTile(context, "Enable First Session Free", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EnableFreeSessionScreen()),
                    );
                  }),
                  _settingsTile(context, "Edit what to Expect", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditWhatToExpectScreen()),
                    );
                  }),
                  _settingsTile(context, "Edit example questions", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditExampleQuestionsScreen()),
                    );
                  }),
                  const SizedBox(height: 24),
                  _sectionHeader("Availability"),
                  _settingsTile(context, "Set my preferred availability", onTap:(){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PreferredAvailabilityScreen()),
                    );
                  }),
                  _settingsTile(context, "Connect my calendar", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ConnectCalendarPage()), // Replace with actual calendar connection screen
                    );
                  }),
                  const SizedBox(height: 24),
                  _sectionHeader("Offerings"),
                  _settingsTile(context, "1:1 Video session prices", onTap:(){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VideoSessionPricePage()), // Replace with actual session prices screen
                    );
                  }),
                  _settingsTile(context, "Available session lengths", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AvailableSessionLengthsPage()), // Replace with actual session lengths screen
                    );
                  }),
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
