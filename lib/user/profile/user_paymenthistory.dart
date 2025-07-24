import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../navbar/user_bottom_navbar.dart';
import '../navbar/user_upper_navbar.dart';

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
  String? errorMessage;
  
  String _displayName = 'User';
  String? _profileImageUrl;
  String _headerTitle = 'Payment History';

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
      
      if (userToken == null || userToken!.isEmpty) {
        setState(() {
          errorMessage = 'User token not found. Please login again.';
          isLoading = false;
        });
        return;
      }

      // Decode JWT token to get userId
      bool tokenParsed = await _parseJWTToken();
      
      if (!tokenParsed) {
        setState(() {
          errorMessage = 'Invalid user token. Please login again.';
          isLoading = false;
        });
        return;
      }
      
      if (userId != null) {
        await _loadUserProfile();
        await _fetchPaymentHistory();
      }
    } catch (error) {
      print('Error initializing user data: $error');
      setState(() {
        errorMessage = 'Failed to initialize user data. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<bool> _parseJWTToken() async {
    try {
      if (userToken == null || userToken!.isEmpty) return false;
      
      final parts = userToken!.split('.');
      if (parts.length != 3) return false;
      
      final payload = parts[1];
      // Add padding if needed
      String normalizedPayload = payload;
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }
      
      final decodedBytes = base64Decode(normalizedPayload);
      final decodedToken = json.decode(utf8.decode(decodedBytes));
      
      if (decodedToken['_id'] != null) {
        userId = decodedToken['_id'];
        return true;
      }
      
      return false;
    } catch (error) {
      print('Error parsing JWT token: $error');
      return false;
    }
  }

  Future<void> _loadUserProfile() async {
    if (userToken == null || userId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/userauth/$userId'),
        headers: {'Authorization': 'Bearer $userToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final userData = data['data'];
          setState(() {
            String firstName = userData['firstName']?.toString() ?? '';
            String lastName = userData['lastName']?.toString() ?? '';
            _displayName = '$firstName $lastName'.trim();
            if (_displayName.isEmpty) _displayName = 'User';
            _profileImageUrl = userData['photoFile']?.toString();
          });
        }
      }
    } catch (e) {
      print("Error loading user profile: $e");
      // Don't set error message for profile loading failure
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> transactionData = data['data'] ?? [];
          
          if (transactionData.isEmpty) {
            setState(() {
              transactions = [];
              isLoading = false;
              errorMessage = null;
            });
            return;
          }
          
          List<Transaction> formattedTransactions = [];
          
          for (var item in transactionData) {
            try {
              if (item != null && item['_id'] != null) {
                // Safe amount parsing
                double amount = 0.0;
                if (item['amount'] != null) {
                  if (item['amount'] is String) {
                    amount = double.tryParse(item['amount']) ?? 0.0;
                  } else if (item['amount'] is num) {
                    amount = item['amount'].toDouble();
                  }
                }
                
                // Safe date parsing
                DateTime date = DateTime.now();
                if (item['createdAt'] != null) {
                  try {
                    date = DateTime.parse(item['createdAt']);
                  } catch (e) {
                    print('Error parsing date: $e');
                  }
                }
                
                String id = item['_id'].toString();
                String shortId = id.length > 6 ? id.substring(id.length - 6) : id;
                
                formattedTransactions.add(Transaction(
                  id: id,
                  shortId: shortId,
                  amount: amount,
                  date: date,
                  status: _formatStatus(item['status']?.toString() ?? 'Unknown'),
                  paymentMethod: item['paymentMethod']?.toString() ?? 'Unknown',
                ));
              }
            } catch (e) {
              print('Error processing transaction item: $e');
              continue;
            }
          }

          // Sort by date (newest first)
          formattedTransactions.sort((a, b) => b.date.compareTo(a.date));

          setState(() {
            transactions = formattedTransactions;
            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to fetch transaction history';
            isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          transactions = [];
          isLoading = false;
          errorMessage = null;
        });
      } else if (response.statusCode == 500) {
        setState(() {
          errorMessage = 'Server error occurred. Please try again later.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch data. Server returned ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching payment history: $error');
      setState(() {
        errorMessage = 'Network error. Please check your connection and try again.';
        isLoading = false;
      });
    }
  }

  String _formatStatus(String status) {
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
        title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserUpperNavbar(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
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
                  
                  isLoading
                      ? _buildLoadingState()
                      : errorMessage != null
                          ? _buildErrorState()
                          : transactions.isEmpty
                              ? _buildEmptyState()
                              : _buildTransactionsList(),
                  
                  if (!isLoading && transactions.isNotEmpty && errorMessage == null)
                    _buildTotalSection(),
                  
                  // Add extra space at bottom to prevent overflow
                  const SizedBox(height: 80),
                ],
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'An error occurred',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _initializeUserData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
        await _fetchPaymentHistory();
      },
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          return _buildTransactionCard(transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final isCompleted = _isStatusCompleted(transaction.status);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isSmallScreen 
          ? _buildMobileTransactionCard(transaction, isCompleted, dateFormat, timeFormat)
          : _buildDesktopTransactionCard(transaction, isCompleted, dateFormat, timeFormat),
      ),
    );
  }

  Widget _buildDesktopTransactionCard(
    Transaction transaction, 
    bool isCompleted, 
    DateFormat dateFormat, 
    DateFormat timeFormat
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.blue[50] : Colors.orange[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.videocam,
            color: isCompleted ? Colors.blue : Colors.orange,
            size: 24,
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              
              Text(
                'Video consultation',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
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
    );
  }

  Widget _buildMobileTransactionCard(
    Transaction transaction, 
    bool isCompleted, 
    DateFormat dateFormat, 
    DateFormat timeFormat
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.blue[50] : Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam,
                color: isCompleted ? Colors.blue : Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video consultation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Row(
              children: [
                Text(
                  dateFormat.format(transaction.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "ID: ${transaction.shortId}",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontFamily: 'monospace',
          ),
        ),
      ],
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
  final DateTime date;
  final String status;
  final String paymentMethod;

  Transaction({
    required this.id,
    required this.shortId,
    required this.amount,
    required this.date,
    required this.status,
    required this.paymentMethod,
  });
}