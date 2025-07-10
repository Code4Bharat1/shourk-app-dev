import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/profile/expert_profile_screen.dart';
import 'package:shourk_application/expert/profile/contact_us_screen.dart';
import 'package:shourk_application/expert/profile/payment_history.dart';
import 'package:shourk_application/expert/profile/account_deactivate.dart';
import 'package:shourk_application/expert/profile/payment_option.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Settings Drawer Widget (Reusable)
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

class GiftCardSelectPage extends StatefulWidget {
  const GiftCardSelectPage({super.key});

  @override
  State<GiftCardSelectPage> createState() => _GiftCardSelectPageState();
}

class _GiftCardSelectPageState extends State<GiftCardSelectPage> {
  String? selectedAmount;
  final List<String> predefinedAmounts = ['200', '500', '750', '1000'];
  final TextEditingController customAmountController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool showCustomField = false;
  
  // Drawer state variables
  bool isMobileNavOpen = false;
  String currentPage = 'Gift Card';
  
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
        // Already on this page
        _closeMobileNav();
        break;
      case 'Contact Us':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ContactUsScreen()),
        );
        break;
      case 'Payment History':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentHistoryPage()),
        );
        break;
      case 'Deactivate account':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DeactivateAccountScreen()),
        );
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

  bool get isContinueEnabled =>
      selectedAmount != null && emailController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final chipPadding = isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    final userName = '$firstName $lastName'.trim();
    final displayName = userName.isNotEmpty ? userName : 'Expert';

    return Scaffold(
      appBar: const ExpertUpperNavbar(),
      bottomNavigationBar: const ExpertBottomNavbar(currentIndex: 2),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Greeting and page title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hi, $displayName", 
                            style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 4),
                        const Text("Gift Card",
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
                const SizedBox(height: 20),
                
                // Settings header row
                Row(
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
                const SizedBox(height: 20),

                // Header Section
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Send a Gift Card',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gift a thoughtful session to a friend, family members or colleague.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(height: 1),
                const SizedBox(height: 24),

                const Text('Choose Amount',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Select a predefined amount or enter a custom value.',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isSmallScreen ? 2 : 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.0,
                  children: predefinedAmounts.map((amount) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAmount = amount;
                          showCustomField = false;
                          customAmountController.clear();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedAmount == amount && !showCustomField
                              ? Colors.blue[50]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedAmount == amount && !showCustomField
                                ? Colors.blue
                                : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'SAR $amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: selectedAmount == amount && !showCustomField
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            showCustomField = !showCustomField;
                            if (!showCustomField) {
                              customAmountController.clear();
                              selectedAmount = null;
                            }
                          });
                        },
                        child: Container(
                          padding: chipPadding,
                          decoration: BoxDecoration(
                            color: showCustomField ? Colors.blue[50] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: showCustomField ? Colors.blue : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Custom Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: showCustomField ? Colors.blue : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showCustomField) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: customAmountController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              selectedAmount = value.isNotEmpty ? value : null;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter amount',
                            prefixText: 'SAR ',
                            prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),

                const Text('Recipient Email*',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'recipient@example.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Recipient Phone Number (Optional)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+1 (555) 123-4567',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Personalised Message (Optional)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Write a short message to the recipient',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your message here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isContinueEnabled
                        ? () => Navigator.pushNamed(context, '/gift-card-form')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Proceed to Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
    );
  }

  @override
  void dispose() {
    customAmountController.dispose();
    emailController.dispose();
    phoneController.dispose();
    messageController.dispose();
    super.dispose();
  }
}