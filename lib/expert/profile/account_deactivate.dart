import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shourk_application/expert/profile/expert_profile_screen.dart';
import 'package:shourk_application/expert/profile/contact_us_screen.dart';
import 'package:shourk_application/expert/profile/account_deactivate.dart';
import 'package:shourk_application/expert/profile/payment_option.dart';
import 'package:shourk_application/expert/profile/giftcard_selection_option.dart';

// Reuse the same SettingsDrawer from PaymentHistoryPage
class SettingsDrawer extends StatelessWidget {
  final String currentPage;
  final Function(String) onSelectOption;
  final Function onClose;

  const SettingsDrawer({
    super.key,
    required this.currentPage,
    required this.onSelectOption,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const drawerOptions = [
      {"label": "Profile", "icon": Icons.person},
      {"label": "Payment Methods", "icon": Icons.payment},
      {"label": "Gift Card", "icon": Icons.card_giftcard},
      {"label": "Contact Us", "icon": Icons.chat},
      {"label": "Payment History", "icon": Icons.history},
      {"label": "Deactivate account", "icon": Icons.delete},
    ];

    return Container(
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
                onPressed: () => onClose(),
              )
            ],
          ),
          Expanded(
            child: ListView(
              children: drawerOptions.map((option) {
                final isSelected = currentPage == option['label'];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    selected: isSelected,
                    selectedColor: Colors.white,
                    leading: Icon(
                      option['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    title: Text(
                      option['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    onTap: () => onSelectOption(option['label'] as String),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class DeactivateAccountScreen extends StatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  State<DeactivateAccountScreen> createState() => _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends State<DeactivateAccountScreen> {
  // Drawer state variables
  bool isMobileNavOpen = false;
  String currentPage = 'Deactivate account';
  
  // User data
  String? expertId;
  String? profileImageUrl;
  String firstName = '';
  String lastName = '';
  String currentLanguage = 'English';
  final String baseUrl = "https://amd-api.code4bharat.com/api/expertauth";

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
          firstName = data['firstName'] ?? '';
          lastName = data['lastName'] ?? '';
          profileImageUrl = data['photoFile'];
        });
      } else {
        print("Failed to load expert data: ${response.body}");
      }
    } catch (e) {
      print("Error fetching expert data: $e");
    }
  }

  void _openSettingsMenu() {
    setState(() => isMobileNavOpen = true);
  }

  void _closeMobileNav() {
    setState(() => isMobileNavOpen = false);
  }

  void _handleSelectOption(String option) {
    if (option == currentPage) {
      _closeMobileNav();
      return;
    }
    
    switch (option) {
      case 'Profile':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ExpertProfilePage()),
        );
        break;
      case 'Payment Methods':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentMethodPage()),
        );
        break;
      case 'Gift Card':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GiftCardSelectPage()),
        );
        break;
      case 'Contact Us':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ContactUsScreen()),
        );
        break;
      case 'Payment History':
        // Handle payment history navigation
        _closeMobileNav();
        break;
      case 'Deactivate account':
        // Already on this page
        _closeMobileNav();
        break;
    }
  }

  void _toggleLanguage() {
    setState(() {
      currentLanguage = currentLanguage == 'English' ? 'Arabic' : 'English';
      // Add logic to change app's language
    });
  }

  void _navigateToProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ExpertProfilePage()),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Deactivate Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to deactivate your account? This action will immediately deactivate your account and cancel any scheduled sessions.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deactivateAccount(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _deactivateAccount(BuildContext context) {
    // Simulate account deactivation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deactivated successfully'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildWarningPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = '$firstName $lastName'.trim();
    final displayName = userName.isNotEmpty ? userName : 'Expert';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const ExpertUpperNavbar(),
      body: Stack(
        children: [
          Column(
            children: [
              // Profile header section - SAME AS PAYMENT HISTORY
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Greeting and page title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hi, $displayName", 
                            style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 4),
                        const Text("Profile",  // Changed to "Profile" per design
                            style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    
                    // Language button and profile photo
                    Row(
                      children: [
                        // Language toggle button
                        ElevatedButton(
                          onPressed: _toggleLanguage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          child: Text(currentLanguage),
                        ),
                        const SizedBox(width: 12),
                        
                        // Profile image container
                        GestureDetector(
                          onTap: _navigateToProfile,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                                  ? Image.network(
                                      profileImageUrl!,
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.person,
                                            size: 24,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.person,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // Settings header row - ADDED SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 8),
                        Text("Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: _openSettingsMenu,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // Deactivate Account Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deactivate Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Warning Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Warning Header
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.orange[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Important Information',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Warning Points
                            _buildWarningPoint('Your account will be deactivated immediately.'),
                            const SizedBox(height: 12),
                            _buildWarningPoint('You can reactivate your account within 1 month by simply logging in again.'),
                            const SizedBox(height: 12),
                            _buildWarningPoint('After 1 month, your account may be permanently deleted.'),
                            const SizedBox(height: 12),
                            _buildWarningPoint('Any scheduled sessions will be cancelled.'),
                            const SizedBox(height: 30),
                            
                            // Deactivate Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _showDeactivateDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Deactivate Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Drawer overlay
          if (isMobileNavOpen)
            GestureDetector(
              onTap: _closeMobileNav,
              child: Container(
                color: Colors.black54,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          
          // Settings drawer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            right: isMobileNavOpen ? 0 : -MediaQuery.of(context).size.width * 0.7,
            top: 0,
            bottom: 0,
            child: SettingsDrawer(
              currentPage: currentPage,
              onSelectOption: _handleSelectOption,
              onClose: _closeMobileNav,
            ),
          ),
        ],
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: const ExpertBottomNavbar(
        currentIndex: 2
      ),
    );
  }
}