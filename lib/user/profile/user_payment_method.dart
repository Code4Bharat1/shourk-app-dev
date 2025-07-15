import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:url_launcher/url_launcher.dart'; // Added for payment redirection
import '../navbar/user_bottom_navbar.dart';

class UserPaymentMethod extends StatefulWidget {
  @override
  _UserPaymentMethodState createState() => _UserPaymentMethodState();
}

class _UserPaymentMethodState extends State<UserPaymentMethod> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController();
  bool _showWithdrawalHistory = false;
  String _selectedPaymentMethod = 'Visa / Mastercard';
  bool _showPaymentDropdown = false;
  bool _showWithdrawModal = false;
  int _withdrawStep = 1;
  String _withdrawMethod = 'bank';
  Map<String, String> _bankDetails = {
    'accountNumber': '',
    'routingNumber': '',
    'bankName': '',
    'accountHolderName': ''
  };
  
  // Settings menu state
  String selectedOption = 'Payment Dashboard';
  bool isMobileNavOpen = false;
  
  // Wallet data
  double _walletBalance = 0.0;
  bool _isLoadingBalance = true;
  bool _isProcessingTopup = false;
  bool _isWithdrawing = false;
  List<dynamic> _withdrawalHistory = [];
  bool _isLoadingHistory = false;
  
  @override
  void initState() {
    super.initState();
    selectedOption = 'Payment Methods';
    _fetchWalletBalance();
    _fetchWithdrawalHistory();
  }
  
  // Fetch wallet balance from API
  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/userwallet/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _walletBalance = data['data']['balance'].toDouble();
          });
        } else {
          throw Exception('Failed to fetch balance: ${data['message']}');
        }
      } else {
        throw Exception('Failed to fetch balance: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoadingBalance = false;
      });
    }
  }
  
  // Fetch withdrawal history from API
  Future<void> _fetchWithdrawalHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/withdrawal/history'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _withdrawalHistory = data['data'];
          });
        } else {
          throw Exception('Failed to fetch history: ${data['message']}');
        }
      } else {
        throw Exception('Failed to fetch history: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }
  
  // Handle wallet top-up - FIXED
  Future<void> _handleTopupWallet() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount (minimum 10 SAR)')),
      );
      return;
    }
    
    setState(() {
      _isProcessingTopup = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      // Store token temporarily for payment flow
      prefs.setString('tempUserToken', token);
      
      final response = await http.post(
        Uri.parse('https://amd-api.code4bharat.com/api/userwallet/topup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({'amount': amount}),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (data['success'] == true && data['data'] != null && data['data']['redirectUrl'] != null) {
          // Redirect to payment page
          final redirectUrl = data['data']['redirectUrl'];
          if (await canLaunch(redirectUrl)) {
            await launch(redirectUrl);
          } else {
            throw Exception('Could not launch payment page');
          }
        } else {
          throw Exception(data['message'] ?? 'Payment initiation failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode} - ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessingTopup = false;
      });
    }
  }
  
  // Handle withdrawal request
  Future<void> _handleWithdrawalRequest() async {
    final amount = double.tryParse(_withdrawAmountController.text) ?? 0;
    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount (minimum 10 SAR)')),
      );
      return;
    }
    
    if (amount > _walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient wallet balance')),
      );
      return;
    }
    
    setState(() {
      _isWithdrawing = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final withdrawalData = {
        'amount': amount,
        'method': _withdrawMethod,
      };
      
      if (_withdrawMethod == 'bank') {
        withdrawalData['bankDetails'] = _bankDetails;
      }
      
      final response = await http.post(
        Uri.parse('https://amd-api.code4bharat.com/api/withdrawal/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(withdrawalData),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Withdrawal request submitted successfully!')),
        );
        // Reset and close modal
        setState(() {
          _showWithdrawModal = false;
          _withdrawStep = 1;
          _withdrawAmountController.clear();
          _bankDetails = {
            'accountNumber': '',
            'routingNumber': '',
            'bankName': '',
            'accountHolderName': ''
          };
        });
        // Refresh data
        _fetchWalletBalance();
        _fetchWithdrawalHistory();
      } else {
        throw Exception(data['message'] ?? 'Withdrawal request failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isWithdrawing = false;
      });
    }
  }
  
  // Navigation methods
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
        title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
        onTap: onTap,
      ),
    );
  }
  
  // Withdrawal modal widget
  Widget _buildWithdrawModal() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showWithdrawModal = false;
              _withdrawStep = 1;
            });
          },
          child: Container(
            color: Colors.black54,
          ),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Withdraw Funds',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showWithdrawModal = false;
                          _withdrawStep = 1;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Progress steps
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStepIndicator(1, 'Amount', _withdrawStep >= 1),
                    _buildStepIndicator(2, 'Method', _withdrawStep >= 2),
                    _buildStepIndicator(3, 'Details', _withdrawStep >= 3),
                    _buildStepIndicator(4, 'Confirm', _withdrawStep >= 4),
                  ],
                ),
                SizedBox(height: 24),
                
                // Step content
                if (_withdrawStep == 1) _buildWithdrawAmountStep(),
                if (_withdrawStep == 2) _buildWithdrawMethodStep(),
                if (_withdrawStep == 3) _buildWithdrawDetailsStep(),
                if (_withdrawStep == 4) _buildWithdrawConfirmStep(),
                
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showWithdrawModal = false;
                          _withdrawStep = 1;
                        });
                      },
                      child: Text('Cancel'),
                    ),
                    Row(
                      children: [
                        if (_withdrawStep > 1)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _withdrawStep--;
                              });
                            },
                            child: Text('Back'),
                          ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_withdrawStep < 4) {
                              setState(() {
                                _withdrawStep++;
                              });
                            } else {
                              _handleWithdrawalRequest();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _withdrawStep == 4 ? Colors.red : Colors.blue,
                          ),
                          child: Text(
                            _withdrawStep == 4 
                              ? _isWithdrawing ? 'Processing...' : 'Submit Withdrawal'
                              : 'Continue',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepIndicator(int stepNumber, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildWithdrawAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdrawal Amount',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _withdrawAmountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount (Minimum 10 SAR)',
            border: OutlineInputBorder(),
            suffixText: 'SAR',
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Available: ${_walletBalance.toStringAsFixed(2)} SAR'),
            Text('Minimum: 10 SAR'),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Withdrawals up to 20% of your balance may qualify for automatic approval.',
                  style: TextStyle(color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildWithdrawMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Withdrawal Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildMethodOption(
          'Bank Transfer',
          Icons.account_balance,
          'Transfer directly to your bank account. Processing time: 1-3 business days.',
          'bank',
        ),
        const SizedBox(height: 12),
        _buildMethodOption(
          'Original Payment Method (TAP)',
          Icons.credit_card,
          'Refund to the card or account you used for deposits. Processing time: 2-5 business days.',
          'tap',
        ),
      ],
    );
  }

  Widget _buildMethodOption(String title, IconData icon, String description, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _withdrawMethod = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _withdrawMethod == value ? Colors.blue[50] : Colors.white,
          border: Border.all(
            color: _withdrawMethod == value ? Colors.blue : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Radio(
              value: value,
              groupValue: _withdrawMethod,
              onChanged: (value) {
                setState(() {
                  _withdrawMethod = value.toString();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWithdrawDetailsStep() {
    if (_withdrawMethod == 'bank') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Account Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildBankDetailField('Account Holder Name', 'accountHolderName'),
          SizedBox(height: 12),
          _buildBankDetailField('Account Number', 'accountNumber'),
          SizedBox(height: 12),
          _buildBankDetailField('IBAN / Routing Number', 'routingNumber'),
          SizedBox(height: 12),
          _buildBankDetailField('Bank Name', 'bankName'),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAP Refund Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.yellow[700]),
                    SizedBox(width: 8),
                    Text(
                      'Important Note',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'The card used for your deposit must still be active and valid for this refund method to work. If your card has expired or been canceled, please use the bank transfer option instead.',
                  style: TextStyle(color: Colors.yellow[700]),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
  
  Widget _buildBankDetailField(String label, String fieldKey) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _bankDetails[fieldKey] = value;
        });
      },
    );
  }
  
  Widget _buildWithdrawConfirmStep() {
    final amount = double.tryParse(_withdrawAmountController.text) ?? 0;
    final isAutoApproval = amount <= _walletBalance * 0.2 && amount <= 1000;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Withdrawal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildConfirmDetail('Amount:', '${amount.toStringAsFixed(2)} SAR'),
              _buildConfirmDetail('Method:', _withdrawMethod == 'bank' ? 'Bank Transfer' : 'Original Payment Method (TAP)'),
              if (_withdrawMethod == 'bank') ...[
                _buildConfirmDetail('Account:', _bankDetails['accountHolderName'] ?? ''),
                _buildConfirmDetail('Bank:', _bankDetails['bankName'] ?? ''),
                _buildConfirmDetail(
                  'Account Number:', 
                  _bankDetails['accountNumber']?.isNotEmpty == true 
                    ? '${_bankDetails['accountNumber']!.substring(0, 4)}••••${_bankDetails['accountNumber']!.substring(_bankDetails['accountNumber']!.length - 4)}'
                    : ''
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAutoApproval ? Colors.green[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isAutoApproval ? Icons.check_circle : Icons.info,
                color: isAutoApproval ? Colors.green : Colors.blue,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAutoApproval
                    ? 'This withdrawal amount qualifies for automatic approval. Funds should be processed within 24 hours.'
                    : 'This withdrawal requires manual approval. The process may take 1-3 business days.',
                  style: TextStyle(
                    color: isAutoApproval ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildConfirmDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  // Withdrawal history item
  Widget _buildWithdrawalHistoryItem(Map<String, dynamic> transaction) {
    String getStatusText(String status) {
      switch (status) {
        case 'pending': return 'Pending';
        case 'approved': return 'Approved';
        case 'rejected': return 'Rejected';
        case 'completed': return 'Completed';
        default: return status;
      }
    }
    
    Color getStatusColor(String status) {
      switch (status) {
        case 'pending': return Colors.orange;
        case 'approved': return Colors.green;
        case 'rejected': return Colors.red;
        case 'completed': return Colors.blue;
        default: return Colors.grey;
      }
    }
    
    IconData getStatusIcon(String status) {
      switch (status) {
        case 'pending': return Icons.pending;
        case 'approved': return Icons.check_circle;
        case 'rejected': return Icons.cancel;
        case 'completed': return Icons.done_all;
        default: return Icons.info;
      }
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${transaction['amount']?.toStringAsFixed(2) ?? '0.00'} SAR',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Chip(
                label: Text(
                  getStatusText(transaction['status'] ?? ''),
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: getStatusColor(transaction['status'] ?? ''),
                avatar: Icon(getStatusIcon(transaction['status'] ?? ''), size: 18, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            transaction['method'] == 'bank' ? 'Bank Transfer' : 'Original Payment Method (TAP)',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 4),
          Text(
            '${DateTime.tryParse(transaction['createdAt'] ?? '')?.toLocal() ?? 'Unknown date'}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          if (transaction['adminComments']?.isNotEmpty == true) ...[
            SizedBox(height: 8),
            Text(
              'Admin comment: ${transaction['adminComments']}',
              style: TextStyle(color: Colors.orange[700], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UserUpperNavbar(),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
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
                          if (_isLoadingBalance)
                            CircularProgressIndicator()
                          else
                            Text(
                              _walletBalance.toStringAsFixed(2),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showWithdrawModal = true;
                                _withdrawStep = 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward, size: 16),
                                SizedBox(width: 4),
                                Text('Withdraw'),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showWithdrawalHistory = !_showWithdrawalHistory;
                                if (_showWithdrawalHistory && _withdrawalHistory.isEmpty) {
                                  _fetchWithdrawalHistory();
                                }
                              });
                            },
                            child: Row(
                              children: [
                                Icon(Icons.history, size: 16),
                                SizedBox(width: 4),
                                Text(_showWithdrawalHistory ? 'Hide History' : 'View History'),
                              ],
                            ),
                          ),
                        ],
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
                    onPressed: _isProcessingTopup ? null : _handleTopupWallet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessingTopup
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(
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
                  
                  if (_isLoadingHistory)
                    Center(child: CircularProgressIndicator())
                  else if (_withdrawalHistory.isEmpty)
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
                    )
                  else
                    Column(
                      children: _withdrawalHistory.map((transaction) {
                        return _buildWithdrawalHistoryItem(
                          Map<String, dynamic>.from(transaction));
                      }).toList(),
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
          
          // Withdraw Modal
          if (_showWithdrawModal) _buildWithdrawModal(),
        ],
      ),
      bottomNavigationBar: UserBottomNavbar(currentIndex: 2),
    );
  }
}