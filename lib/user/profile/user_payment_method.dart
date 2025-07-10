import 'package:flutter/material.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import '../navbar/user_bottom_navbar.dart';

class PaymentDashboard extends StatefulWidget {
  @override
  _PaymentDashboardState createState() => _PaymentDashboardState();
}

class _PaymentDashboardState extends State<PaymentDashboard> {
  final TextEditingController _amountController = TextEditingController();
  bool _showWithdrawalHistory = false;
  String _selectedPaymentMethod = 'Visa / Mastercard';
  bool _showPaymentDropdown = false;

  // Settings menu state - matching the UserProfilePage structure
  String selectedOption = 'Payment Dashboard';
  bool isMobileNavOpen = false;

  // Settings Menu Drawer - using the same pattern as UserProfilePage
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

  // Navigate to the corresponding page
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

  // Drawer option widget - exactly matching UserProfilePage
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

  @override
  void initState() {
    super.initState();
    selectedOption = 'Payment Methods'; // Set this to match the active page
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UserUpperNavbar(),
      body: Stack(
        children: [
          // Main content in a single ScrollView
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with proper spacing
                const Text(
                  "Hi, user",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Profile",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
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
                
                // Main title
                Text(
                  'Payment Dashboard',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Manage your wallet, payments and\nwithdrawals',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),

                // Wallet Balance Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE3F2FD), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF4285F4),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Your Wallet Balance',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '0',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'SAR',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showWithdrawalHistory = !_showWithdrawalHistory;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              color: Colors.grey[600],
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              _showWithdrawalHistory ? 'Hide History' : 'View History',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Add Money to Wallet Section
                Text(
                  'Add Money to Wallet',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 24),

                // Payment Method
                Text(
                  'Payment Method',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showPaymentDropdown = !_showPaymentDropdown;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedPaymentMethod,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.credit_card,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Icon(
                          _showPaymentDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // Payment Method Dropdown
                if (_showPaymentDropdown) ...[
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = 'Visa / Mastercard';
                              _showPaymentDropdown = false;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Text(
                                  'Visa / Mastercard',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.credit_card,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[300]),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = 'Mada';
                              _showPaymentDropdown = false;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Text(
                                  'Mada',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.payment,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 8),

                Text(
                  _selectedPaymentMethod == 'Mada'
                      ? 'Mada cards accepted'
                      : 'International cards accepted (Visa, Mastercard)',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 24),

                // Amount Section
                Text(
                  'Amount (Minimum 10 SAR)',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      suffixText: 'SAR',
                      suffixStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Add Money Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Add money functionality')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Money',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Info Message
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE3F2FD), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF4285F4),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Funds will be available immediately after successful payment. You can use your wallet balance for all services on the platform.',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Withdrawal History Section
                if (_showWithdrawalHistory) ...[
                  SizedBox(height: 32),
                  Text(
                    'Withdrawal History',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.refresh, color: Colors.grey[400], size: 32),
                        SizedBox(height: 16),
                        Icon(Icons.warning_amber_outlined, color: Colors.grey[400], size: 32),
                        SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You haven\'t made any withdrawal requests yet.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Add bottom padding to ensure content doesn't get cut off
                SizedBox(height: 20),
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
      bottomNavigationBar: UserBottomNavbar(),
    );
  }
}