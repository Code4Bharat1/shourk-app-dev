// user_profile_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shourk_application/start_page.dart';
import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:shourk_application/user/profile/user_giftcard.dart';
import 'package:shourk_application/user/profile/user_payment_method.dart';
import 'package:shourk_application/user/profile/user_contactus.dart';
import 'package:shourk_application/user/profile/user_paymenthistory.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isEditing = false;
  bool isUploading = false;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final String baseUrl = "https://amd-api.code4bharat.com/api/userauth";
  String? userId;
  String? token;
  String? profileImageUrl;
  String successMessage = "";
  String selectedOption = 'Profile';
  bool isMobileNavOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserToken();
  }

  Future<void> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('userToken');

    if (token != null) {
      try {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
        setState(() {
          userId = decodedToken['_id'];
        });
        if (userId != null) {
          _loadUserProfile();
        }
      } catch (e) {
        print("Error parsing token: $e");
        setState(() => _isLoading = false);
      }
    } else {
      print("User token not found");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserProfile() async {
    if (userId == null || token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final userData = data['data'];
          setState(() {
            firstNameController.text = userData['firstName'] ?? '';
            lastNameController.text = userData['lastName'] ?? '';
            mobileController.text = userData['phone'] ?? '';
            emailController.text = userData['email'] ?? '';
            profileImageUrl = userData['photoFile'];
            _isLoading = false;
          });
        } else {
          print("Failed to load user data: ${data['message']}");
          setState(() => _isLoading = false);
        }
      } else {
        print("Failed to load user data: ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (userId == null || token == null) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/updateuser/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'phone': mobileController.text.trim(),
          'email': emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            isEditing = false;
            successMessage = "Changes Saved!";
          });
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              successMessage = "";
            });
          });
        } else {
          print("Failed to update profile: ${data['message']}");
        }
      } else {
        print("Failed to update profile: ${response.body}");
      }
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  Future<void> _uploadProfileImage() async {
    if (userId == null || token == null) return;

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
        'POST',
        Uri.parse('$baseUrl/uploadProfileImage/$userId'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
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
          profileImageUrl = jsonResponse['user']['photoFile'];
          successMessage = "Profile image updated successfully!";
        });
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            successMessage = "";
          });
        });
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

    Navigator.of(context).pop();

    switch (label) {
      case 'Payment Methods':
        Navigator.push(context, MaterialPageRoute(builder: (context) =>  PaymentDashboard()));
        break;
      case 'Gift Card':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const UserGiftCardSelectPage()));
        break;
      case 'Contact Us':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const UserContactUsScreen()));
        break;
      case 'Payment History':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPaymentHistoryPage()));
        break;
      case 'Sign Out':
        _handleSignOut();
        break;
    }
  }

  void _handleSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StartPage()),
    );
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
    final userName = '${firstNameController.text} ${lastNameController.text}'.trim();
    final displayName = userName.isNotEmpty ? userName : 'User';

    return Scaffold(
      key: _scaffoldKey,
      appBar: UserUpperNavbar(),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Hi, $displayName", 
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 4),
                                const Text("Profile",
                                    style: TextStyle(
                                        fontSize: 24, 
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey[300]!, width: 2),
                                    ),
                                    child: ClipOval(
                                      child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                                          ? Image.network(
                                              profileImageUrl!,
                                              fit: BoxFit.cover,
                                              width: 40,
                                              height: 40,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.person,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
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
                        
                        if (successMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, 
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  successMessage,
                                  style: const TextStyle(
                                      color: Colors.green, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: isEditing ? _uploadProfileImage : null,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white, width: 2),
                                            ),
                                            child: ClipOval(
                                              child: isUploading
                                                  ? const Center(
                                                      child: CircularProgressIndicator())
                                                  : (profileImageUrl != null &&
                                                          profileImageUrl!.isNotEmpty
                                                      ? Image.network(
                                                          profileImageUrl!,
                                                          fit: BoxFit.cover,
                                                          width: 100,
                                                          height: 100,
                                                        )
                                                      : Container(
                                                          color: Colors.grey[300],
                                                          child: const Icon(
                                                              Icons.person,
                                                              size: 40,
                                                              color: Colors.white),
                                                        )),
                                            ),
                                          ),
                                          if (isEditing && !isUploading)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(Icons.camera_alt,
                                                    color: Colors.white, size: 20),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
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
                                    ),
                                  )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                
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
                              _buildDrawerOption("Sign Out", Icons.logout, () {
                                _navigateToPage("Sign Out");
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
      bottomNavigationBar: UserBottomNavbar(
        currentIndex: 2,
      ),
    );
  }
}