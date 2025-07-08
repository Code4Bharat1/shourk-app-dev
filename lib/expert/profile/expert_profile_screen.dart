import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExpertProfilePage extends StatefulWidget {
  const ExpertProfilePage({super.key});

  @override
  State<ExpertProfilePage> createState() => _ExpertProfilePageState();
}

class _ExpertProfilePageState extends State<ExpertProfilePage> {
  bool isEditing = false;
  final TextEditingController firstNameController = TextEditingController(text: 'Ebadat');
  final TextEditingController lastNameController = TextEditingController(text: 'Khan');
  final TextEditingController mobileController = TextEditingController(text: '919321xxxxx');
  final TextEditingController emailController = TextEditingController(text: 'abc@gmail.com');
  final String baseUrl = "http://localhost:5070/api/expertauth";


  String selectedOption = 'Profile';

 void _saveProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('expertToken');

  if (token != null) {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    String expertId = decodedToken['_id'];

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/updateexpert/$expertId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'phone': mobileController.text.trim(),
          'email': emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        setState(() {
          isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: ${response.body}")),
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating profile.")),
      );
    }
  }
}

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      bool enabled = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildDrawerOption(String label, IconData icon, VoidCallback onTap) {
    final bool isSelected = selectedOption == label;
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.black,
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.black),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      onTap: () {
        setState(() {
          selectedOption = label;
        });
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigateTo(String route) {
    Navigator.pushNamed(context, route);
  }

  void _openSettingsMenu() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildDrawerOption("Profile", Icons.person, () {}),
              _buildDrawerOption("Payment Methods", Icons.payment, () => _navigateTo('/payment-methods')),
              _buildDrawerOption("Gift Card", Icons.card_giftcard, () => _navigateTo('/gift-card')),
              _buildDrawerOption("Contact Us", Icons.chat, () => _navigateTo('/contact-us')),
              _buildDrawerOption("Payment History", Icons.history, () => _navigateTo('/payment-history')),
              _buildDrawerOption("Deactivate account", Icons.delete, () => _navigateTo('/deactivate')),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(  
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Text("Shourk", style: TextStyle(color: Colors.black)),
            const Spacer(),
            const Icon(Icons.language, color: Colors.black),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("العربية",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.notifications_none, color: Colors.black),
            const SizedBox(width: 12),
            const CircleAvatar(child: Text('U'))
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hi, User", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              const Text("Profile",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.settings, size: 18),
                      SizedBox(width: 6),
                      Text("Settings", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: _openSettingsMenu,
                  )
                ],
              ),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(
                                "https://randomuser.me/api/portraits/men/46.jpg"),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${firstNameController.text} ${lastNameController.text}",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                const Text("India",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                isEditing = !isEditing;
                              });
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("Edit"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                          label: "First Name",
                          controller: firstNameController,
                          enabled: isEditing),
                      _buildTextField(
                          label: "Last Name",
                          controller: lastNameController,
                          enabled: isEditing),
                      _buildTextField(
                          label: "Mobile Number",
                          controller: mobileController,
                          enabled: isEditing),
                      _buildTextField(
                          label: "Email",
                          controller: emailController,
                          enabled: isEditing),
                      const SizedBox(height: 12),
                      if (isEditing)
                        ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text("Save"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: ExpertBottomNavbar(
        currentIndex: 2,
        // onTap: (index) {
        //   // TODO: Implement navigation
        // },
      ),
    );
  }

  
  @override
void initState() {
  super.initState();
  _loadExpertProfile();
}

Future<void> _loadExpertProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('expertToken');

  if (token != null) {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    String expertId = decodedToken['_id'];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$expertId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];

        setState(() {
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          mobileController.text = data['phone'] ?? '';
          emailController.text = data['email'] ?? '';
        });
      } else {
        print("Failed to load expert data: ${response.body}");
      }
    } catch (e) {
      print("Error fetching expert data: $e");
    }
  } else {
    print("Expert token not found.");
  }
}

}
