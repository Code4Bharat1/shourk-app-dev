import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
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
import 'dart:convert';
import 'package:intl/intl.dart';

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
  final TextEditingController _topupAmountController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  int withdrawStep = 1;
  String selectedMethod = 'Bank Transfer';
  double earningBalance = 0.0;
  double spendingBalance = 0.0;
  
  // Drawer state
  bool isMobileNavOpen = false;
  String currentPage = 'Payment Methods';
  
  // User data
  String? expertId;
  String? profileImageUrl;
  String firstName = '';
  String lastName = '';
  String currentLanguage = 'English';
  final String baseUrl = "https://amd-api.code4bharat.com/api/expertauth";
  final String walletBaseUrl = "https://amd-api.code4bharat.com/api/expertwallet";
  final String withdrawalBaseUrl = "https://amd-api.code4bharat.com/api/expertwithdrawal";
  
  List<Map<String, dynamic>> earningHistory = [];
  List<Map<String, dynamic>> spendingHistory = [];
  bool isLoadingHistory = false;
  bool isLoadingBalance = true;
  bool isProcessingWithdrawal = false;
  bool isAddingMoney = false;

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
          await _fetchWalletBalances();
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('$baseUrl/$expertId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
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

  Future<void> _fetchWalletBalances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('$walletBaseUrl/balances'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          earningBalance = data['earning']?.toDouble() ?? 0.0;
          spendingBalance = data['spending']?.toDouble() ?? 0.0;
          isLoadingBalance = false;
        });
      } else {
        print("Failed to fetch wallet balances: ${response.body}");
        setState(() => isLoadingBalance = false);
      }
    } catch (e) {
      print("Error fetching wallet balances: $e");
      setState(() => isLoadingBalance = false);
    }
  }

  Future<void> _fetchEarningHistory() async {
    try {
      setState(() => isLoadingHistory = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('$walletBaseUrl/earning/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both possible response structures
        final history = data['history'] ?? data['data'];
        if (history is List) {
          setState(() {
            earningHistory = List<Map<String, dynamic>>.from(history);
            isLoadingHistory = false;
          });
        } else {
          setState(() {
            earningHistory = [];
            isLoadingHistory = false;
          });
        }
      } else {
        print("Failed to fetch earning history: ${response.body}");
        setState(() {
          earningHistory = [];
          isLoadingHistory = false;
        });
      }
    } catch (e) {
      print("Error fetching earning history: $e");
      setState(() {
        earningHistory = [];
        isLoadingHistory = false;
      });
    }
  }

  Future<void> _fetchSpendingHistory() async {
    try {
      setState(() => isLoadingHistory = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('$walletBaseUrl/spending/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both possible response structures
        final history = data['history'] ?? data['data'];
        if (history is List) {
          setState(() {
            spendingHistory = List<Map<String, dynamic>>.from(history);
            isLoadingHistory = false;
          });
        } else {
          setState(() {
            spendingHistory = [];
            isLoadingHistory = false;
          });
        }
      } else {
        print("Failed to fetch spending history: ${response.body}");
        setState(() {
          spendingHistory = [];
          isLoadingHistory = false;
        });
      }
    } catch (e) {
      print("Error fetching spending history: $e");
      setState(() {
        spendingHistory = [];
        isLoadingHistory = false;
      });
    }
  }

  Future<void> _requestWithdrawal() async {
    try {
      setState(() => isProcessingWithdrawal = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      
      if (token == null) return;
      
      final amount = double.tryParse(_withdrawAmountController.text) ?? 0.0;
      
      Map<String, dynamic> body = {
        'amount': amount,
        'method': selectedMethod == 'Bank Transfer' ? 'bank' : 'tap',
      };

      if (selectedMethod == 'Bank Transfer') {
        body['bankDetails'] = {
          'accountHolderName': _accountHolderController.text,
          'accountNumber': _accountNumberController.text,
          'iban': _ibanController.text,
          'bankName': _bankNameController.text,
        };
      }

      final response = await http.post(
        Uri.parse('$withdrawalBaseUrl/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Withdrawal submitted successfully!")),
          );
          await _fetchWalletBalances();
          await _fetchEarningHistory();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Withdrawal submission failed")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit withdrawal")),
        );
      }
    } catch (e) {
      print("Error submitting withdrawal: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred")),
      );
    } finally {
      setState(() => isProcessingWithdrawal = false);
    }
  }

  Future<void> _initiateTopUp() async {
    try {
      setState(() => isAddingMoney = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      final amount = double.tryParse(_topupAmountController.text) ?? 0.0;
      
      if (token == null) return;
      
      final response = await http.post(
        Uri.parse('$walletBaseUrl/spending/topup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['redirectUrl'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PaymentCardPage(
              redirectUrl: data['data']['redirectUrl'],
              amount: amount,
            )),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Failed to initiate payment")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to initiate payment")),
        );
      }
    } catch (e) {
      print("Error initiating top-up: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred")),
      );
    } finally {
      setState(() => isAddingMoney = false);
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
    withdrawStep = 1;
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
            case 1:
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
                  Text("Available: ${earningBalance.toStringAsFixed(2)} SAR    Minimum: 10 SAR", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Withdrawals up to 20% of your balance may qualify for automatic approval.",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              );
              break;
            case 2:
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
                  RadioListTile(
                    value: 'Original Payment Method (TAP)',
                    groupValue: selectedMethod,
                    onChanged: (val) {
                      setModalState(() => selectedMethod = val.toString());
                    },
                    title: const Text("Original Payment Method (TAP)"),
                    subtitle: const Text("Refund to the card or account used for deposits. Processing time: 2–5 business days."),
                  ),
                ],
              );
              break;
            case 3:
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedMethod == 'Bank Transfer') ...[
                    _textField("Account Holder Name", _accountHolderController),
                    _textField("Account Number", _accountNumberController),
                    _textField("IBAN / Routing Number", _ibanController),
                    _textField("Bank Name", _bankNameController),
                  ] else ...[
                    const Text("TAP Refund Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    const Text("Funds will be returned to the payment method used for your most recent deposit.",
                      style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Important Note", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text("The card used for your deposit must still be active and valid. If expired or canceled, use bank transfer instead.",
                            style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    )
                  ]
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
                  if (selectedMethod == 'Bank Transfer') ...[
                    _confirmRow("Account", _accountHolderController.text),
                    _confirmRow("Bank", _bankNameController.text),
                    _confirmRow("Account Number", "****${_accountNumberController.text.substring(_accountNumberController.text.length - 4)}"),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isAutoApproval() ? Colors.green[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isAutoApproval()
                          ? "This withdrawal qualifies for automatic approval. Funds should be processed within 24 hours."
                          : "This withdrawal requires manual approval. The process may take 1-3 business days.",
                      style: TextStyle(
                        color: _isAutoApproval() ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                ],
              );
          }

          return AlertDialog(
            title: const Text("Withdraw Funds"),
            content: SingleChildScrollView(child: content),
            actions: [
              if (withdrawStep > 1)
                TextButton(
                  onPressed: () => setModalState(() => withdrawStep--),
                  child: const Text("Back"),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              if (withdrawStep < 4)
                ElevatedButton(
                  onPressed: () {
                    if (withdrawStep == 1) {
                      final amount = double.tryParse(_withdrawAmountController.text) ?? 0;
                      if (amount < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Minimum withdrawal is 10 SAR")),
                        );
                        return;
                      }
                      if (amount > earningBalance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Insufficient balance")),
                        );
                        return;
                      }
                    }
                    setModalState(() => withdrawStep++);
                  },
                  child: Text(withdrawStep == 3 ? "Review" : "Continue"),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isProcessingWithdrawal ? null : () {
                    Navigator.pop(context);
                    _requestWithdrawal();
                  },
                  child: isProcessingWithdrawal
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Withdrawal"),
                )
            ],
          );
        });
      },
    );
  }

  void _showEarningHistory() {
    if (earningHistory.isEmpty) {
      _fetchEarningHistory();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Earning Wallet History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : earningHistory.isEmpty
                  ? const Center(child: Text("No transactions found", style: TextStyle(fontSize: 16)))
                  : _buildEarningHistoryTable(),
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

  void _showSpendingHistory() {
    if (spendingHistory.isEmpty) {
      _fetchSpendingHistory();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Spending Wallet History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : spendingHistory.isEmpty
                  ? const Center(child: Text("No transactions found", style: TextStyle(fontSize: 16)))
                  : _buildSpendingHistoryTable(),
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

  Widget _buildEarningHistoryTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Session', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Refund', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: earningHistory.map((transaction) {
            final date = transaction['dateTime'] != null
                ? DateFormat('M/d/yyyy, h:mm:ss a').format(DateTime.parse(transaction['dateTime']))
                : 'N/A';
            final session = transaction['sessionTitle'] ?? transaction['sessionId'] ?? 'N/A';
            final user = transaction['userName'] ?? 'N/A';
            final amount = transaction['amountEarned'] != null
                ? '+${transaction['amountEarned'].toStringAsFixed(2)} SAR'
                : 'N/A';
            final status = transaction['status']?.toString()?.toUpperCase() ?? 'N/A';
            final refund = transaction['refundDetails'] != null ? 'View' : '-';

            return DataRow(cells: [
              DataCell(Text(date)),
              DataCell(Text(session)),
              DataCell(Text(user)),
              DataCell(Text(amount, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status, style: const TextStyle(color: Colors.white)),
                ),
              ),
              DataCell(Text(refund)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSpendingHistoryTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Expert', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Session', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Method', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Refund', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: spendingHistory.map((transaction) {
            final date = transaction['dateTime'] != null
                ? DateFormat('M/d/yyyy, h:mm:ss a').format(DateTime.parse(transaction['dateTime']))
                : 'N/A';
            final expert = transaction['expertName'] ?? 'N/A';
            final session = transaction['sessionId'] ?? 'N/A';
            final amount = transaction['amountPaid'] != null
                ? '-${transaction['amountPaid'].toStringAsFixed(2)} SAR'
                : 'N/A';
            final method = transaction['paymentMethod'] ?? 'N/A';
            final status = transaction['status']?.toString()?.toUpperCase() ?? 'N/A';
            final refund = transaction['refundDetails'] != null ? 'View' : '-';

            return DataRow(cells: [
              DataCell(Text(date)),
              DataCell(Text(expert)),
              DataCell(Text(session)),
              DataCell(Text(amount, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
              DataCell(Text(method)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status, style: const TextStyle(color: Colors.white)),
                ),
              ),
              DataCell(Text(refund)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  bool _isAutoApproval() {
    final amount = double.tryParse(_withdrawAmountController.text) ?? 0;
    return amount <= earningBalance * 0.2 && amount <= 1000;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
      appBar: ExpertUpperNavbar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
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
                        const Text("Payment Methods",
                            style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
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

                // Earning Wallet Card
                _walletCard(
                  title: "Earning Wallet Balance",
                  amount: earningBalance,
                  onWithdraw: _showWithdrawDialog,
                  onHistory: _showEarningHistory,
                  isLoading: isLoadingBalance,
                  backgroundColor: Colors.green[50]!,
                  iconColor: Colors.green,
                  icon: Icons.account_balance_wallet,
                ),

                const SizedBox(height: 20),

                // Spending Wallet Card
                _walletCard(
                  title: "Spending Wallet Balance",
                  amount: spendingBalance,
                  onHistory: _showSpendingHistory,
                  isLoading: isLoadingBalance,
                  backgroundColor: Colors.blue[50]!,
                  iconColor: Colors.blue,
                  icon: Icons.credit_card,
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
                        controller: _topupAmountController,
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
                    final amount = double.tryParse(_topupAmountController.text.trim()) ?? 0;
                    if (amount >= 10) {
                      _initiateTopUp();
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
    bool isLoading = false,
    required Color backgroundColor,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Text("${amount.toStringAsFixed(2)} SAR", 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onWithdraw != null)
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
              if (onWithdraw != null) const SizedBox(width: 12),
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