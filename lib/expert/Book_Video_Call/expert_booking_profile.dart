import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
// import 'package:shourk_application/expert/navbar/video_call.dart';
import 'package:shourk_application/shared/models/expert_model.dart';

class ExpertBookingScreen extends StatefulWidget {
  final String expertId;
  final String selectedSessionType;
  final List<String> selectedSlots; // Changed to list of slots

  const ExpertBookingScreen({
    super.key,
    required this.expertId,
    required this.selectedSessionType,
    required this.selectedSlots, // Now accepts multiple slots
  });

  @override
  _BookingFormScreenState createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<ExpertBookingScreen> {
  ExpertModel? expert;
  bool isLoading = true;
  String error = '';
  double discountAmount = 0.0;
  double walletBalance = 0.0;
  bool isWalletLoading = true;
  bool isBookingInProgress = false;
  String? authToken;
  String? currentUserId;

  // Add missing form key and controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getAuthToken();
    await Future.wait([
      fetchExpert(),
      fetchWalletBalance(),
    ]);
  }

  Future<void> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      
      if (token != null) {
        final decodedToken = JwtDecoder.decode(token);
        setState(() {
          authToken = token;
          currentUserId = decodedToken['_id'];
        });
      } else {
        setState(() {
          authToken = null;
          currentUserId = null;
        });
      }
    } catch (e) {
      print("Error getting auth token: $e");
      setState(() {
        authToken = null;
        currentUserId = null;
      });
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      if (authToken == null) {
        setState(() {
          isWalletLoading = false;
          walletBalance = 0.0;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5070/api/expertwallet/balances'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
         walletBalance = (data['data']['spending'] ?? 0.0).toDouble();
          isWalletLoading = false;
        });
      } else {
        setState(() {
          walletBalance = 0.0;
          isWalletLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching wallet balance: $e");
      setState(() {
        walletBalance = 0.0;
        isWalletLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> fetchExpert() async {
    try {
      final res = await http.get(
        Uri.parse('http://localhost:5070/api/expertauth/${widget.expertId}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        setState(() {
          expert = ExpertModel.fromJson(data);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load expert (${res.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Helper methods
  double get sessionFee => expert?.price ?? 0.0;
  double get totalAmount => sessionFee * widget.selectedSlots.length - discountAmount;
  bool get isFirstSession => expert?.freeSessionEnabled ?? false;
  double get finalPriceAfterGiftCard => isFirstSession ? 0.0 : totalAmount;

  String _mapSessionDurationLabel(String type) {
    switch (type) {
      case 'quick': return 'Quick - 15min';
      case 'regular': return 'Regular - 30min';
      case 'extra': return 'Extra - 45min';
      case 'all_access': return 'All Access - 60min';
      default: return 'Regular - 30min';
    }
  }

  void _applyPromoCode() {
    final promoCode = _promoController.text.trim();
    if (promoCode.isNotEmpty) {
      setState(() {
        if (promoCode.toUpperCase() == 'SAVE10') {
          discountAmount = sessionFee * widget.selectedSlots.length * 0.1;
        } else if (promoCode.toUpperCase() == 'SAVE20') {
          discountAmount = sessionFee * widget.selectedSlots.length * 0.2;
        } else {
          discountAmount = 0.0;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid promo code')),
          );
        }
      });
    }
  }

  // Parse slot string into date and time
  Map<String, String> _parseSlot(String slot) {
    final parts = slot.split('-');
    final time = parts.last;
    final date = parts.sublist(0, parts.length - 1).join('-');
    return {'date': date, 'time': time};
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(error)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: ExpertUpperNavbar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpertCard(),
            const SizedBox(height: 20),
            _buildSessionInfoCard(),
            const SizedBox(height: 20),
            _buildBookingForm(),
            const SizedBox(height: 20),
            _buildPaymentSummary(),
            const SizedBox(height: 20),
            _buildBookButton(),
          ],
        ),
      ),
      bottomNavigationBar: ExpertBottomNavbar(currentIndex: 1),
    );
  }

  Widget _buildExpertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(expert!.imageUrl),
                backgroundColor: Colors.grey[300],
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expert!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expert!.title ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: index < expert!.rating.round()
                              ? Colors.orange
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16),
                      Text(
                        'SAR ${sessionFee.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Per Session',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Selected Sessions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Display all selected slots
                for (var slot in widget.selectedSlots)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          '${_parseSlot(slot)['date']} at ${_parseSlot(slot)['time']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _mapSessionDurationLabel(widget.selectedSessionType),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have selected ${widget.selectedSlots.length} sessions. Payment will be processed for all sessions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Sessions: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('${widget.selectedSlots.length} slots', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Duration: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(_mapSessionDurationLabel(widget.selectedSessionType), style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete Your Booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name fields
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    hint: 'Enter your first name',
                    prefixIcon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hint: 'Enter your last name',
                    prefixIcon: Icons.person_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Phone and Email
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _phoneController,
                    label: 'Mobile Number',
                    hint: '+1 (555) 000-0000',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'your.email@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Note to Expert
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Note to Expert',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '0/25 words minimum',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Introduce yourself and describe what you\'d like to discuss in the session (minimum 25 words)...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Promo Code
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      labelText: 'Gift Card / Promo Code',
                      hintText: 'Enter gift or promo code',
                      prefixIcon: const Icon(Icons.card_giftcard_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),    
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Your Wallet Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                  ),
                ),
                const Spacer(),
                isWalletLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    )
                  : Text(
                      'SAR ${walletBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Show insufficient balance warning if needed
          if (!isWalletLoading && finalPriceAfterGiftCard > walletBalance && !isFirstSession) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, color: Colors.red[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Insufficient wallet balance. Please top up your wallet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session Fee',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'SAR ${(sessionFee * widget.selectedSlots.length).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          // Show free session discount if applicable
          if (isFirstSession) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'First Session (Free)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                ),
                Text(
                  '-SAR ${(sessionFee * widget.selectedSlots.length).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ],
          
          // Show promo code discount if applicable
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                ),
                Text(
                  '-SAR ${discountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'SAR ${finalPriceAfterGiftCard.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    bool canBook = !isWalletLoading && 
                   (isFirstSession || finalPriceAfterGiftCard <= walletBalance) &&
                   !isBookingInProgress;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canBook ? () {
              if (_formKey.currentState!.validate()) {
                _handleBooking();
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canBook ? Colors.black : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isBookingInProgress 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment),
                    const SizedBox(width: 8),
                    Text(
                      isFirstSession 
                        ? 'Book Free Session'
                        : 'Pay SAR ${finalPriceAfterGiftCard.toStringAsFixed(2)} & Book',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isFirstSession 
            ? 'By clicking "Book Free Session", you agree to our Terms of Service and Privacy Policy.'
            : 'By clicking "Pay SAR ${finalPriceAfterGiftCard.toStringAsFixed(2)} & Book", you agree to our Terms of Service and Privacy Policy.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _handleBooking() async {
    if (authToken == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required or user ID missing. Please re-login.')),
      );
      return;
    }

    setState(() {
      isBookingInProgress = true;
    });

        String _validateAreaOfExpertise(String? input) {
      const allowed = [
        'Home',
        'Digital Marketing',
        'Technology',
        'Style and Beauty',
        'Health and Wellness',
        'Career and Business'
      ];
      return allowed.contains(input) ? input! : 'Home';
    }

    try {
      // Prepare booking data
      final bookingData = {
        'consultingExpertID': widget.expertId,
        'expertId': currentUserId,
        'areaOfExpertise': _validateAreaOfExpertise(expert?.areaOfExpertise),
        'duration': _mapSessionDurationLabel(widget.selectedSessionType),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'note': _noteController.text.trim(),
        'price': sessionFee.toString(),
        'redemptionCode': _promoController.text.trim(),
        'slots': widget.selectedSlots.map((slot) {
          final parsed = _parseSlot(slot);
          return {
            'selectedDate': parsed['date'],
            'selectedTime': parsed['time'],
          };
        }).toList(),
      };

      // First create the session
      final sessionResponse = await http.post(
        Uri.parse('http://localhost:5070/api/session/experttoexpertsession'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bookingData),
      );

      if (sessionResponse.statusCode != 200 && sessionResponse.statusCode != 201) {
        throw Exception('Failed to create session: ${sessionResponse.body}');
      }

      final sessionData = jsonDecode(sessionResponse.body);
      final sessionId = sessionData['session']['_id'];

      // If not a free session and there's a cost, make the payment
      if (!isFirstSession && finalPriceAfterGiftCard > 0) {
        final paymentResponse = await http.post(
          Uri.parse('http://localhost:5070/api/expertwallet/spending/pay'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'sessionId': sessionId,
            'amount': finalPriceAfterGiftCard,
            'payeeExpertId': widget.expertId,
          }),
        );

        if (paymentResponse.statusCode != 200 && paymentResponse.statusCode != 201) {
          throw Exception('Payment failed: ${paymentResponse.body}');
        }

        // Update local wallet balance after successful payment
        setState(() {
          walletBalance = walletBalance - finalPriceAfterGiftCard;
        });
      }

      // Show success confirmation
      _showBookingConfirmation(sessionId);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isBookingInProgress = false;
      });
    }
  }

  void _showBookingConfirmation(String sessionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.selectedSlots.length} sessions with ${expert?.name} have been booked successfully.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Session ID: $sessionId',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Home'),
            ),
          ],
        );
      },
    );
  }
}