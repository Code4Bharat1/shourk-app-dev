  import 'package:flutter/material.dart';
  import 'package:shourk_application/expert/layout/expert_scaffold.dart';
  import './payment_card.dart';
  import 'package:shourk_application/expert/profile/expert_profile_screen.dart';
  import 'package:shourk_application/expert/profile/contact_us_screen.dart';
  import 'package:shourk_application/expert/profile/payment_history.dart';
  import 'package:shourk_application/expert/profile/account_deactivate.dart';
  import 'package:shourk_application/expert/profile/giftcard_selection_option.dart';
  import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
  import 'package:jwt_decoder/jwt_decoder.dart';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';
  import 'dart:convert'; // ADDED THIS LINE

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

  class PaymentMethodPage extends StatefulWidget {
    const PaymentMethodPage({super.key});

    @override
    State<PaymentMethodPage> createState() => _PaymentMethodPageState();
  }

  class _PaymentMethodPageState extends State<PaymentMethodPage> {
    final TextEditingController _spendingAmountController = TextEditingController();
    final TextEditingController _withdrawAmountController = TextEditingController();
    final TextEditingController _accountHolderController = TextEditingController();
    final TextEditingController _accountNumberController = TextEditingController();
    final TextEditingController _ibanController = TextEditingController();
    final TextEditingController _bankNameController = TextEditingController();

    int withdrawStep = 0;
    String selectedMethod = 'Bank Transfer';
    double earningsBalance = 8540;
    double spendingBalance = 7500;
    
    // Drawer state variables
    bool isMobileNavOpen = false;
    String currentPage = 'Payment Methods';
    
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
          // Already on this page
          _closeMobileNav();
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

    void _showWithdrawDialog() {
      withdrawStep = 0;
      _withdrawAmountController.clear();
      _accountHolderController.clear();
      _accountNumberController.clear();
      _ibanController.clear();
      _bankNameController.clear();

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setModalState) {
            Widget content;

            switch (withdrawStep) {
              case 0:
                content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Withdrawal Amount", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _withdrawAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter amount',
                        suffixText: 'SAR',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text("Available: $earningsBalance SAR    Minimum: 10 SAR", style: TextStyle(color: Colors.grey)),
                  ],
                );
                break;
              case 1:
                content = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Withdrawal Method", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    RadioListTile(
                      value: 'Bank Transfer',
                      groupValue: selectedMethod,
                      onChanged: (val) {
                        setModalState(() => selectedMethod = val.toString());
                      },
                      title: const Text("Bank Transfer"),
                      subtitle: const Text("Transfer directly to your bank account. Processing time: 5–7 business days."),
                    ),
                  ],
                );
                break;
              case 2:
                content = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _textField("Account Holder Name", _accountHolderController),
                    _textField("Account Number", _accountNumberController),
                    _textField("IBAN / Routing Number", _ibanController),
                    _textField("Bank Name", _bankNameController),
                  ],
                );
                break;
              default:
                content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Confirm Withdrawal", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _confirmRow("Amount", "${_withdrawAmountController.text} SAR"),
                    _confirmRow("Method", selectedMethod),
                    _confirmRow("Account", _accountHolderController.text),
                    _confirmRow("Bank", _bankNameController.text),
                    _confirmRow("Account Number", "****${_accountNumberController.text.substring(_accountNumberController.text.length - 4)}"),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "This withdrawal amount qualifies for automatic approval. Funds should be processed within 5–7 business days.",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                );
            }

            return AlertDialog(
              title: const Text("Withdraw Funds"),
              content: SingleChildScrollView(child: content),
              actions: [
                if (withdrawStep > 0)
                  TextButton(
                    onPressed: () => setModalState(() => withdrawStep--),
                    child: const Text("Back"),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                if (withdrawStep < 3)
                  ElevatedButton(
                    onPressed: () => setModalState(() => withdrawStep++),
                    child: const Text("Continue"),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Withdrawal submitted successfully!")),
                      );
                    },
                    child: const Text("Submit Withdrawal"),
                  )
              ],
            );
          });
        },
      );
    }

    void _showWalletHistory() {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Earning Wallet History"),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (_, index) {
                return ListTile(
                  title: Text("6/30/2025, ${10 + index}:00 AM"),
                  subtitle: const Text("Quick - 15min"),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        ),
      );
    }

    Widget _textField(String label, TextEditingController controller) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }

    Widget _confirmRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Expanded(child: Text(value)),
          ],
        ),
      );
    }

    void _toggleLanguage() {
      setState(() {
        currentLanguage = currentLanguage == 'English' ? 'Arabic' : 'English';
        // Here you would add logic to change the app's language
      });
    }

    void _navigateToProfile() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ExpertProfilePage()),
      );
    }

    @override
    Widget build(BuildContext context) {
      final userName = '$firstName $lastName'.trim();
      final displayName = userName.isNotEmpty ? userName : 'User';

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
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // New header section with greeting and profile image
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hi, $displayName", 
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text("Payment Methods",
                              style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
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
                  const SizedBox(height: 16),
                  
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
                  
                  const Text("Manage your wallet, payments and withdrawals", 
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),

                  _walletCard(
                    title: "Earning Wallet Balance",
                    amount: earningsBalance,
                    showWithdraw: true,
                    onWithdraw: _showWithdrawDialog,
                    onHistory: _showWalletHistory,
                  ),
                  const SizedBox(height: 20),

                  _walletCard(
                    title: "Spending Wallet Balance",
                    amount: spendingBalance,
                    onHistory: _showWalletHistory,
                  ),

                  const SizedBox(height: 20),
                  const Text("Add Money to Spending Wallet", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text("Amount (Minimum 10 SAR)", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _spendingAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Enter amount",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text("SAR", style: TextStyle(fontSize: 16)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Add Money", style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      final amount = double.tryParse(_spendingAmountController.text.trim()) ?? 0;
                      if (amount >= 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Redirecting to payment page...")),
                        );
                        Future.delayed(const Duration(seconds: 1), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PaymentCardPage(amount: amount)),
                          );
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Minimum amount is 10 SAR")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    "Funds will be available immediately after successful payment. You can use your wallet balance for all services on the platform.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
        bottomNavigationBar: const ExpertBottomNavbar(currentIndex: 2),
      );
    }

    Widget _walletCard({
      required String title,
      required double amount,
      VoidCallback? onWithdraw,
      VoidCallback? onHistory,
      bool showWithdraw = false,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: showWithdraw ? Colors.green[50] : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text("$amount SAR", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                if (showWithdraw)
                  ElevatedButton(
                    onPressed: onWithdraw,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text("Withdraw", style: TextStyle(fontSize: 14)),
                  ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onHistory,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text("View History", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }