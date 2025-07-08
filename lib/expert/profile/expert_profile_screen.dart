import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'dart:convert';
import 'dart:io';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import './payment_option.dart';
import './giftcard_selection_option.dart';
import 'package:shourk_application/expert/profile/contact_us_screen.dart';
import 'package:shourk_application/expert/profile/payment_history.dart';
import 'package:shourk_application/expert/profile/account_deactivate.dart';

// Placeholder pages for navigation options (you'll need to create actual implementations)
class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: const Center(child: Text('Payment Methods Page')),
    );
  }
}

class CodeEntryPage extends StatelessWidget {
  const CodeEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Do you have code?')),
      body: const Center(child: Text('Code Entry Page')),
    );
  }
}

class GiftCardPage extends StatelessWidget {
  const GiftCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gift Card')),
      body: const Center(child: Text('Gift Card Page')),
    );
  }
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: const Center(child: Text('Contact Us Page')),
    );
  }
}

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: const Center(child: Text('Payment History Page')),
    );
  }
}

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give us Feedback')),
      body: const Center(child: Text('Feedback Page')),
    );
  }
}

class DeactivateAccountPage extends StatelessWidget {
  const DeactivateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deactivate account')),
      body: const Center(child: Text('Deactivate Account Page')),
    );
  }
}

class ExpertProfilePage extends StatefulWidget {
  const ExpertProfilePage({super.key});

  @override
  State<ExpertProfilePage> createState() => _ExpertProfilePageState();
}

class _ExpertProfilePageState extends State<ExpertProfilePage> {
  bool isEditing = false;
  bool isUploading = false;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final String baseUrl = "https://amd-api.code4bharat.com/api/expertauth";
  String? expertId;
  String? profileImageUrl;
  String successMessage = "";
  String selectedOption = 'Profile';
  bool isMobileNavOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getExpertId();
  }

  Future<void> _getExpertId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('expertToken');

    if (token != null) {
      try {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        setState(() {
          expertId = decodedToken['_id'];
        });
        if (expertId != null) {
          _loadExpertProfile();
        }
      } catch (e) {
        print("Error parsing token: $e");
      }
    } else {
      print("Expert token not found");
    }
  }

  Future<void> _loadExpertProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$expertId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          mobileController.text = data['phone'] ?? '';
          emailController.text = data['email'] ?? '';
          profileImageUrl = data['photoFile'];
        });
      } else {
        print("Failed to load expert data: ${response.body}");
      }
    } catch (e) {
      print("Error fetching expert data: $e");
    }
  }

  Future<void> _saveProfile() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/updateexpert/$expertId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'phone': mobileController.text.trim(),
          'email': emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isEditing = false;
          successMessage = "Changes Saved!";
        });
        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            successMessage = "";
          });
        });
      } else {
        print("Failed to update profile: ${response.body}");
      }
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileSize = await file.length();

    // Check file size (5MB limit)
    if (fileSize > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File size should be less than 5MB")),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/updateexpert/$expertId'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'photoFile',
          file.path,
        ),
      );

      var response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = json.decode(responseString);

      if (response.statusCode == 200 && jsonResponse['success']) {
        setState(() {
          profileImageUrl = jsonResponse['data']['photoFile'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: ${jsonResponse['message']}")),
        );
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error uploading profile picture")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
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
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        selected: isSelected,
        selectedColor: Colors.white,
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.black),
        title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
        onTap: onTap,
      ),
    );
  }

  void _navigateToPage(String label) {
    setState(() {
      selectedOption = label;
      isMobileNavOpen = false;
    });

    // Close drawer immediately
    Navigator.of(context).pop();

    // Navigate to the corresponding page
    switch (label) {
      case 'Payment Methods':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodPage()));
        break;
        break;
      case 'Gift Card':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const GiftCardSelectPage()));
        break;
      case 'Contact Us':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
        break;
      case 'Payment History':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentHistoryPage()));
        break;
      case 'Deactivate account':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DeactivateAccountScreen()));
        break;
      // 'Profile' stays on current page
    }
  }

  void _openSettingsMenu() {
    setState(() {
      isMobileNavOpen = true;
    });
  }

  void _closeMobileNav() {
    setState(() {
      isMobileNavOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
      body: Stack(
        children: [
          SingleChildScrollView(
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
                  
                  // Success Message
                  if (successMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            successMessage,
                            style: const TextStyle(color: Colors.green, fontSize: 16),
                          ),
                        ],
                      ),
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
                              // Profile Picture with Upload
                              GestureDetector(
                                onTap: isEditing ? _uploadProfileImage : null,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: ClipOval(
                                        child: isUploading
                                            ? const Center(child: CircularProgressIndicator())
                                            : (profileImageUrl != null && profileImageUrl!.isNotEmpty
                                                ? Image.network(
                                                    profileImageUrl!,
                                                    fit: BoxFit.cover,
                                                    width: 100,
                                                    height: 100,
                                                  )
                                                : Container(
                                                    color: Colors.grey[300],
                                                    child: const Icon(Icons.person, size: 40, color: Colors.white),
                                                  )),
                                      ),
                                    ),
                                    if (isEditing && !isUploading)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                        ),
                                      ),
                                  ],
                                ),
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
                                    successMessage = "";
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
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),)
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // Mobile Navigation Drawer
          if (isMobileNavOpen)
            GestureDetector(
              onTap: _closeMobileNav,
              child: Container(
                color: Colors.black54,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            right: isMobileNavOpen ? 0 : -MediaQuery.of(context).size.width * 0.7,
            top: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              color: Colors.white,
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    title: const Text("Settings"),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _closeMobileNav,
                      )
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildDrawerOption("Profile", Icons.person, () {
                          _navigateToPage("Profile");
                        }),
                        _buildDrawerOption("Payment Methods", Icons.payment, () {
                          _navigateToPage("Payment Methods");
                        }),
                        _buildDrawerOption("Gift Card", Icons.card_giftcard, () {
                          _navigateToPage("Gift Card");
                        }),
                        _buildDrawerOption("Contact Us", Icons.chat, () {
                          _navigateToPage("Contact Us");
                        }),
                        _buildDrawerOption("Payment History", Icons.history, () {
                          _navigateToPage("Payment History");
                        }),
                        _buildDrawerOption("Deactivate account", Icons.delete, () {
                          _navigateToPage("Deactivate account");
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ExpertBottomNavbar(
        currentIndex: 2,
      ),
    );
  }
}