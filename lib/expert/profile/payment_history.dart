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

  // Payment history state
  List<Transaction> transactions = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

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
          await _loadExpertProfile();
          await _fetchPaymentHistory();
        }
      } catch (e) {
        print("Error parsing token: $e");
        setState(() {
          hasError = true;
          errorMessage = "Authentication error";
          isLoading = false;
        });
      }
    } else {
      print("Expert token not found");
      setState(() {
        hasError = true;
        errorMessage = "Please login again";
        isLoading = false;
      });
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

  Future<void> _fetchPaymentHistory() async {
    if (expertId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');

      final response = await http.get(
        Uri.parse('$baseUrl/getTransactionHistory/$expertId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];
        
        final List<Transaction> fetchedTransactions = data.map((item) {
          final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
          final date = DateTime.parse(item['createdAt']);
          
          return Transaction(
            id: item['_id'],
            amount: amount,
            service: 'Full consultation',
            date: date,
            paymentMethod: item['paymentMethod'] ?? 'TAP',
            status: item['status'] ?? 'PENDING',
          );
        }).toList();

        // Sort transactions by date (newest first)
        fetchedTransactions.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          transactions = fetchedTransactions;
          isLoading = false;
        });
      } else {
        print("Failed to load payment history: ${response.body}");
        setState(() {
          hasError = true;
          errorMessage = "Failed to load payment history";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching payment history: $e");
      setState(() {
        hasError = true;
        errorMessage = "Network error";
        isLoading = false;
      });
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

  void _retryPaymentHistory() {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    _fetchPaymentHistory();
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
              
              // Settings header row
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
              
              // Content area
              Expanded(
                child: _buildContentSection(),
              ),
              
              // Total section
              if (transactions.isNotEmpty) _buildTotalSection(),
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

  Widget _buildContentSection() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryPaymentHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No payments yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(transactions[index]);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    // Get short ID (last 6 characters)
    final shortId = transaction.id != null && transaction.id!.length > 6
        ? transaction.id!.substring(transaction.id!.length - 6)
        : transaction.id ?? '';

    // Determine status color
    Color statusColor;
    if (transaction.status == 'COMPLETED' || transaction.status == 'SUCCESS') {
      statusColor = Colors.green;
    } else if (transaction.status == 'PENDING') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID and Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Short ID
                Text(
                  shortId,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                
                // Amount
                Text(
                  'SAR ${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Service name
            Text(
              transaction.service,
              style: const TextStyle(
                fontSize: 16,
              ),
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
            
            const SizedBox(height: 8),
            
            // Payment method and status
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Payment method
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      transaction.paymentMethod,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Status
                Text(
                  transaction.status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
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
  final String paymentMethod;
  final String status;

  Transaction({
    this.id,
    required this.amount,
    required this.service,
    required this.date,
    required this.paymentMethod,
    required this.status,
  });
}