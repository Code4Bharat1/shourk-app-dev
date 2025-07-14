import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../navbar/user_upper_navbar.dart';
import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';

class UserGiftCardSelectPage extends StatefulWidget {
  const UserGiftCardSelectPage({super.key});

  @override
  State<UserGiftCardSelectPage> createState() => _UserGiftCardSelectPageState();
}

class _UserGiftCardSelectPageState extends State<UserGiftCardSelectPage> {
  String? selectedAmount;
  final List<String> predefinedAmounts = ['200', '500', '750', '1000'];
  final TextEditingController customAmountController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  bool sendAnonymously = false;
  bool showCustomField = false;
  bool isSubmitting = false;
  String? token;

  // Settings menu state
  String selectedOption = 'Gift Card';
  bool isMobileNavOpen = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  void _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('userToken');
    });
  }

  bool get isContinueEnabled =>
      (selectedAmount != null || customAmountController.text.isNotEmpty) &&
      emailController.text.isNotEmpty;

  // Settings Menu Drawer
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

  void _navigateToPage(String label) {
    setState(() {
      selectedOption = label;
      isMobileNavOpen = false;
    });

    switch (label) {
      case 'Profile':
        Navigator.pushNamed(context, '/user-profile');
        break;
      case 'Payment Methods':
        Navigator.pushNamed(context, '/payment_method');
        break;
      case 'Gift Card':
        Navigator.pushNamed(context, '/user-giftcard');
        break;
      case 'Contact Us':
        Navigator.pushNamed(context, '/user-contactus');
        break;
      case 'Payment History':
        Navigator.pushNamed(context, '/user-paymenthistory');
        break;
      case 'Sign Out':
        Navigator.pushNamed(context, '/start');
        break;
    }
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
        title: Text(label,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
        onTap: onTap,
      ),
    );
  }

  Future<void> handlePurchaseAttempt() async {
    if (!isContinueEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid recipient email format')),
      );
      return;
    }

    // Determine amount
    double amount;
    if (selectedAmount != null) {
      amount = double.parse(selectedAmount!);
    } else {
      amount = double.tryParse(customAmountController.text) ?? 0;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid gift card amount')),
      );
      return;
    }

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please log in again')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final url = Uri.parse('https://amd-api.code4bharat.com/api/giftcard/purchase');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final payload = {
        'amount': amount,
        'recipientEmail': emailController.text.trim(),
        if (phoneController.text.trim().isNotEmpty)
          'recipientPhone': phoneController.text.trim(),
        if (messageController.text.trim().isNotEmpty)
          'recipientMessage': messageController.text.trim(),
        'sendAnonymously': sendAnonymously,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['paymentUrl'] != null) {
          if (await canLaunchUrl(Uri.parse(responseData['paymentUrl']))) {
            await launchUrl(
              Uri.parse(responseData['paymentUrl']),
              mode: LaunchMode.externalApplication,
            );
          } else {
            throw 'Could not launch payment URL';
          }
        } else {
          throw responseData['message'] ?? 'Payment URL not found';
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 
            (errorData['errors']?.map((e) => e['msg']).join(', ') ?? 
            'Failed to initiate gift card purchase');
        throw errorMessage;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final chipPadding = isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    
    final displayName = "User"; // Placeholder for user name

    return Scaffold(
      appBar: UserUpperNavbar(),
      bottomNavigationBar: const UserBottomNavbar(currentIndex: 2),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with proper spacing
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
                          onTap: () => Navigator.pushNamed(context, '/user-profile'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                            ),
                            child: ClipOval(
                              child: Container(
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
                
                // Settings row
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
                const SizedBox(height: 16),

                // Gift Card Content
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
                const SizedBox(height: 16),
                
                // Added Send Anonymously checkbox
                Row(
                  children: [
                    Checkbox(
                      value: sendAnonymously,
                      onChanged: (value) {
                        setState(() {
                          sendAnonymously = value ?? false;
                        });
                      },
                      activeColor: Colors.black,
                      checkColor: Colors.white,
                    ),
                    const Text('Send Anonymously'),
                    const SizedBox(width: 8),
                    const Icon(Icons.person_off, size: 20),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : handlePurchaseAttempt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Processing...',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Proceed to Payment',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
                        _buildDrawerOption("Sign Out", Icons.delete, () {
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