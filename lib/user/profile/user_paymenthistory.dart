import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../navbar/user_bottom_navbar.dart';
import '../navbar/user_upper_navbar.dart';

class UserPaymentHistoryPage extends StatefulWidget {
  const UserPaymentHistoryPage({super.key});

  @override
  State<UserPaymentHistoryPage> createState() => _UserPaymentHistoryPageState();
}

class _UserPaymentHistoryPageState extends State<UserPaymentHistoryPage> {
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
  ];

  // Settings menu state - matching the previous pages
  String selectedOption = 'Payment History';
  bool isMobileNavOpen = false;

  double get totalAmount {
    return transactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }

  // Settings Menu Drawer - using the same pattern as previous pages
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
      case 'Sign Out':
        Navigator.pushNamed(context, '/start');
        break;
    }
  }

  // Drawer option widget - exactly matching previous pages
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
  Widget build(BuildContext context) {
    final displayName = "User"; // Placeholder for user name
    
    return Scaffold(
      appBar: UserUpperNavbar(),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // User info section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    
                    // Settings section added
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.settings, size: 18),
                          const SizedBox(width: 6),
                          const Text("Settings", style: TextStyle(fontSize: 16)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: _openSettingsMenu,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(thickness: 1),
                  ],
                ),
              ),
              
              // URL section
              _buildUrlSection(),
              
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
          
          // Mobile Navigation Drawer - exactly matching previous pages
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
      bottomNavigationBar: UserBottomNavbar(currentIndex: 2),
    );
  }

  Widget _buildUrlSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'shourk.com/expertpanel/expertpanelpr...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {},
            child: const Text('Download', style: TextStyle(fontSize: 14)),
          ),
          const Text('|', style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () {},
            child: const Text('Node.js', style: TextStyle(fontSize: 14)),
          ),
        ],
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