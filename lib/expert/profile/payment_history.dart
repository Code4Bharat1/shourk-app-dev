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

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final List<Transaction> transactions = [
    Transaction(
      id: 'bdda35',
      amount: 100.00,
      service: 'Full consultation',
      date: DateTime(2025, 7, 8, 11, 40),
      status: 'HYPERPAY PENDING',
      isCompleted: false,
    ),
    Transaction(
      id: '9920b9',
      amount: 100.00,
      service: 'Full consultation',
      date: DateTime(2025, 7, 8, 12, 2),
      status: 'HYPERPAY PENDING',
      isCompleted: false,
    ),
    Transaction(
      amount: 200.00,
      service: 'Full consultation',
      date: DateTime(2025, 6, 23, 14, 22),
      status: 'WALLET COMPLETED',
      isCompleted: true,
    ),
    Transaction(
      amount: 1000.00,
      service: 'Full consultation',
      date: DateTime(2025, 6, 23, 14, 7),
      status: 'HYPERPAY COMPLETED',
      isCompleted: true,
    ),
    Transaction(
      amount: 1000.00,
      service: 'Full consultation',
      date: DateTime(2025, 6, 23, 12, 41),
      status: 'HYPERPAY PENDING',
      isCompleted: false,
    ),
    // Add more transactions as needed
  ];

  // Drawer state variables
  bool isMobileNavOpen = false;
  String currentPage = 'Payment History';
  
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
        // Already on this page
        _closeMobileNav();
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

  double get totalAmount {
    return transactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }

  @override
  Widget build(BuildContext context) {
    final userName = '$firstName $lastName'.trim();
    final displayName = userName.isNotEmpty ? userName : 'Expert';

    return Scaffold(
      appBar: const ExpertUpperNavbar(),
      body: Stack(
        children: [
          Column(
            children: [
              // Profile header section
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
                        const Text("Payment History",
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
              
              // Settings header row - NEW SECTION ADDED
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
              
              // Transactions list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(transactions[index]);
                  },
                ),
              ),
              
              // Total section
              _buildTotalSection(),
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
      bottomNavigationBar: const ExpertBottomNavbar(
        currentIndex: 2, // Assuming this is the index for Payment History
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: transaction.isCompleted 
                  ? Colors.green[100] 
                  : Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: transaction.isCompleted
                ? const Icon(Icons.check, color: Colors.green, size: 24)
                : const SizedBox.shrink(),
            ),
            
            const SizedBox(width: 16),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID if exists
                  if (transaction.id != null) ...[
                    Text(
                      transaction.id!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Service type
                  Row(
                    children: [
                      if (!transaction.isCompleted)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (!transaction.isCompleted) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.service,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Amount
                  Row(
                    children: [
                      const Text(
                        'SAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction.amount.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Date and time
                  Text(
                    '${dateFormat.format(transaction.date)}  ${timeFormat.format(transaction.date)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Payment status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.status.split(' ')[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.status.split(' ')[1],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transaction.status.contains('COMPLETED')
                      ? Colors.green
                      : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${transactions.length} transactions',
            style: const TextStyle(fontSize: 16),
          ),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Total: SAR ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: totalAmount.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Transaction {
  final String? id;
  final double amount;
  final String service;
  final DateTime date;
  final String status;
  final bool isCompleted;

  Transaction({
    this.id,
    required this.amount,
    required this.service,
    required this.date,
    required this.status,
    required this.isCompleted,
  });
}