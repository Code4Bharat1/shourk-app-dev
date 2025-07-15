import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../navbar/user_bottom_navbar.dart';
import '../navbar/user_upper_navbar.dart';

// Reusable header widget
class ProfileHeader extends StatelessWidget {
  final String displayName;
  final String title;
  final String? profileImageUrl;
  final VoidCallback? onProfileTap;

  const ProfileHeader({
    required this.displayName,
    required this.title,
    this.profileImageUrl,
    this.onProfileTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hi, $displayName", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          children: [
            Text(displayName, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onProfileTap,
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
    );
  }
}

class UserPaymentHistoryPage extends StatefulWidget {
  const UserPaymentHistoryPage({super.key});

  @override
  State<UserPaymentHistoryPage> createState() => _UserPaymentHistoryPageState();
}

class _UserPaymentHistoryPageState extends State<UserPaymentHistoryPage> {
  List<Transaction> transactions = [];
  bool isLoading = true;
  String? userId;
  String? userToken;
  
  // Profile header variables
  String _displayName = 'User';
  String? _profileImageUrl;
  String _headerTitle = 'Payment History';

  // Settings menu state
  String selectedOption = 'Payment History';
  bool isMobileNavOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userToken = prefs.getString('userToken');
      
      if (userToken != null) {
        // Decode JWT token to get userId
        final parts = userToken!.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          // Add padding if needed
          final normalizedPayload = payload.padRight(
            (payload.length + 3) & ~3, '=');
          final decodedBytes = base64Decode(normalizedPayload);
          final decodedToken = json.decode(utf8.decode(decodedBytes));
          userId = decodedToken['_id'];
          
          if (userId != null) {
            await _fetchPaymentHistory();
            await _loadUserProfile(); // Load user profile for header
          }
        }
      } else {
        _showError('User token not found');
      }
    } catch (error) {
      print('Error parsing userToken: $error');
      _showError('Failed to load user data');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Load user profile for header
  Future<void> _loadUserProfile() async {
    if (userToken == null || userId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/userauth/$userId'),
        headers: {'Authorization': 'Bearer $userToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final userData = data['data'];
          setState(() {
            _displayName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
            if (_displayName.isEmpty) _displayName = 'User';
            _profileImageUrl = userData['photoFile'];
          });
        }
      }
    } catch (e) {
      print("Error loading user profile: $e");
    }
  }

  Future<void> _fetchPaymentHistory() async {
    if (userId == null || userToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/userauth/getTransactionHistory/$userId'),
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> transactionData = data['data'];
        
        // Format transactions similar to JS frontend
        List<Transaction> formattedTransactions = transactionData.map((item) {
          return Transaction(
            id: item['_id'],
            shortId: item['_id'].substring(item['_id'].length - 6),
            amount: double.parse(item['amount'].toString()),
            service: 'Video consultation', // Default service type
            date: DateTime.parse(item['createdAt']),
            status: _formatStatus(item['status'] ?? 'Completed'),
            isCompleted: _isStatusCompleted(item['status'] ?? 'Completed'),
            paymentMethod: item['paymentMethod'] ?? 'Credit Card',
          );
        }).toList();

        // Sort by date (newest first)
        formattedTransactions.sort((a, b) => b.date.compareTo(a.date));

        if (mounted) {
          setState(() {
            transactions = formattedTransactions;
          });
        }
      } else {
        _showError('Failed to load payment history');
      }
    } catch (error) {
      print('Error fetching payment history: $error');
      _showError('Failed to load payment history');
    }
  }

  String _formatStatus(String status) {
    // Format status similar to JS frontend
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return 'COMPLETED';
      case 'pending':
        return 'PENDING';
      case 'failed':
      case 'cancelled':
        return 'FAILED';
      default:
        return status.toUpperCase();
    }
  }

  bool _isStatusCompleted(String status) {
    return status.toLowerCase() == 'completed' || status.toLowerCase() == 'success';
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double get totalAmount {
    return transactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }

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

  // Drawer option widget
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
    return Scaffold(
      appBar: UserUpperNavbar(),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // User info section using ProfileHeader
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ProfileHeader(
                  displayName: _displayName,
                  title: _headerTitle,
                  profileImageUrl: _profileImageUrl,
                  onProfileTap: () => Navigator.pushNamed(context, '/user-profile'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Settings section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
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
              ),
              
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              
              // URL section
              _buildUrlSection(),
              
              // Content based on loading state
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : transactions.isEmpty
                        ? _buildEmptyState()
                        : _buildTransactionsList(),
              ),
              
              // Total section (only show if not loading and has transactions)
              if (!isLoading && transactions.isNotEmpty)
                _buildTotalSection(),
            ],
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
      bottomNavigationBar: UserBottomNavbar(currentIndex: 2),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(3, (index) => 
          Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No payments yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return RefreshIndicator(
      onRefresh: _fetchPaymentHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          return _buildTransactionCard(transactions[index]);
        },
      ),
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
            // Status indicator with video icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: transaction.isCompleted 
                  ? Colors.blue[50] 
                  : Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam,
                color: transaction.isCompleted ? Colors.blue : Colors.orange,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Short ID and Amount in same row
                  Row(
                    children: [
                      Text(
                        transaction.shortId,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${transaction.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Service type
                  Text(
                    transaction.service,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Right section - Date, Time, Payment Method, Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Date and time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateFormat.format(transaction.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeFormat.format(transaction.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Payment method and status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          transaction.paymentMethod,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getStatusIcon(transaction.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusTextColor(transaction.status),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getStatusTextColor(transaction.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green[100]!;
      case 'pending':
        return Colors.orange[100]!;
      case 'failed':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green[700]!;
      case 'pending':
        return Colors.orange[700]!;
      case 'failed':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return '✓';
      case 'pending':
        return '⏳';
      case 'failed':
        return '✗';
      default:
        return '•';
    }
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${transactions.length} transactions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Total Spent: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                TextSpan(
                  text: '\$${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
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
  final String id;
  final String shortId;
  final double amount;
  final String service;
  final DateTime date;
  final String status;
  final bool isCompleted;
  final String paymentMethod;

  Transaction({
    required this.id,
    required this.shortId,
    required this.amount,
    required this.service,
    required this.date,
    required this.status,
    required this.isCompleted,
    required this.paymentMethod,
  });
}