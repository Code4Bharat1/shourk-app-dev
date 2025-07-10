import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shourk_application/expert/Book_Video_Call/expert_payment_screen.dart';
import 'package:shourk_application/expert/profile/payment_option.dart';

class ExpertBookingScreen extends StatefulWidget {
  final Map<String, dynamic>? consultingExpert;
  final Map<String, dynamic>? sessionData;

  const ExpertBookingScreen({
    Key? key,
    this.consultingExpert,
    this.sessionData,
  }) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<ExpertBookingScreen> {
  // Controllers for text fields
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController giftCardController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Selected time slot tracking
  String? selectedTimeSlot;
  String? selectedDate;
  List<Map<String, dynamic>> availableSlots = [];

  // Loading states
  bool isBooking = false;
  bool isLoadingBalance = true;
  bool isCheckingEligibility = true;
  bool isCheckingGiftCard = false;

  // Backend data
  Map<String, dynamic>? consultingExpert;
  Map<String, dynamic>? sessionData;
  double walletBalance = 0.0;
  bool isFirstSession = false;
  int wordCount = 0;
  String noteError = "";

  // Gift card state
  Map<String, dynamic>? appliedGiftCard;
  double giftCardDiscount = 0.0;

  // API Base URL
  static const String baseUrl = "https://amd-api.code4bharat.com";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadStoredData();
    await _fetchWalletBalance();
    await _checkFirstSessionEligibility();
    await _loadUserProfile();
    setState(() {
      isLoadingBalance = false;
      isCheckingEligibility = false;
    });
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load consulting expert data
    final expertDataString = prefs.getString('consultingExpertData');
    if (expertDataString != null) {
      consultingExpert = json.decode(expertDataString);
    } else if (widget.consultingExpert != null) {
      consultingExpert = widget.consultingExpert;
    }

    // Load session data
    final sessionDataString = prefs.getString('sessionData');
    if (sessionDataString != null) {
      sessionData = json.decode(sessionDataString);
    } else if (widget.sessionData != null) {
      sessionData = widget.sessionData;
    }

    // Load booking data
    final bookingDataString = prefs.getString('bookingData');
    if (bookingDataString != null) {
      final bookingData = json.decode(bookingDataString);
      firstNameController.text = bookingData['firstName'] ?? '';
      lastNameController.text = bookingData['lastName'] ?? '';
      mobileController.text = bookingData['mobileNumber'] ?? '';
      emailController.text = bookingData['email'] ?? '';
      noteController.text = bookingData['note'] ?? '';
    }

    // Set up available slots from session data
    if (sessionData != null && sessionData!['slots'] != null) {
      availableSlots = List<Map<String, dynamic>>.from(sessionData!['slots']);
    }
  }

  Future<void> _saveBookingData() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingData = {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'mobileNumber': mobileController.text,
      'email': emailController.text,
      'note': noteController.text,
      'bookingType': 'individual',
    };
    await prefs.setString('bookingData', json.encode(bookingData));
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/expert/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final profile = data['data'];
          firstNameController.text = profile['firstName'] ?? '';
          lastNameController.text = profile['lastName'] ?? '';
          mobileController.text = profile['mobileNumber'] ?? '';
          emailController.text = profile['email'] ?? '';
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      if (token == null) {
        _showSnackBar('Authentication error');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/wallet/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            walletBalance = (data['data']['balance'] as num).toDouble();
          });
        }
      } else if (response.statusCode == 401) {
        _showSnackBar('Authentication failed. Please log in again.');
      }
    } catch (e) {
      print('Error fetching wallet balance: $e');
      _showSnackBar('Error loading wallet balance');
    }
  }

  Future<void> _checkFirstSessionEligibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      if (token == null || consultingExpert == null) return;

      // Decode token to get current expert ID
      final tokenParts = token.split('.');
      if (tokenParts.length != 3) return;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))),
      );
      final currentExpertId = payload['_id'];

      final response = await http.get(
        Uri.parse('$baseUrl/api/freesession/check-eligibility/$currentExpertId/${consultingExpert!['_id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isFirstSession = data['eligible'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking free session eligibility: $e');
      setState(() {
        isFirstSession = false;
      });
    }
  }

  Future<void> _handleApplyGiftCard() async {
    if (giftCardController.text.trim().isEmpty) {
      _showSnackBar('Please enter a gift card code');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('expertToken');
    if (token == null) {
      _showSnackBar('Authentication token not found. Please log in.');
      return;
    }

    if (isFirstSession) {
      _showSnackBar('This is a free first session. Gift card not applicable.');
      return;
    }

    setState(() {
      isCheckingGiftCard = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giftcard/check/${giftCardController.text.trim()}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['giftCard'] != null) {
          final card = data['giftCard'];
          
          if ((card['status'] != 'active' && card['status'] != 'anonymous_active') || 
              (card['balance'] ?? 0) <= 0) {
            _showSnackBar('This gift card is inactive or has no balance.');
            return;
          }

          final currentSessionPrice = sessionData?['price']?.toDouble() ?? 0.0;
          if (currentSessionPrice == 0) {
            _showSnackBar('Cannot apply gift card to a session that is already free.');
            return;
          }

          final cardValueForDiscount = (card['originalAmount'] ?? card['amount']).toDouble();
          final discountToApply = (cardValueForDiscount < currentSessionPrice) 
              ? cardValueForDiscount 
              : currentSessionPrice;

          setState(() {
            appliedGiftCard = {...card, 'code': giftCardController.text.trim()};
            giftCardDiscount = discountToApply;
            giftCardController.clear();
          });

          _showSnackBar('Gift card applied! SAR ${discountToApply.toStringAsFixed(2)} discount.');
        } else {
          _showSnackBar('Gift card not found or has already been redeemed.');
        }
      } else {
        _showSnackBar('Invalid gift card code or it may have been used.');
      }
    } catch (e) {
      print('Error applying gift card: $e');
      _showSnackBar('Failed to apply gift card. Please try again.');
    } finally {
      setState(() {
        isCheckingGiftCard = false;
      });
    }
  }

  void _handleRemoveGiftCard() {
    setState(() {
      appliedGiftCard = null;
      giftCardDiscount = 0.0;
      giftCardController.clear();
    });
    _showSnackBar('Gift card removed.');
  }

  Future<void> _handleBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedTimeSlot == null || selectedDate == null) {
      _showSnackBar('Please select a time slot');
      return;
    }

    final noteWords = noteController.text.trim().split(RegExp(r'\s+'));
    if (noteWords.length < 25) {
      setState(() {
        noteError = "Note must contain at least 25 words.";
      });
      _showSnackBar('✍️ Your note must be at least 25 words.');
      return;
    }

    setState(() {
      noteError = "";
    });

    // Calculate prices
    final price = isFirstSession ? 0.0 : (sessionData?['price']?.toDouble() ?? 0.0);
    final finalPriceAfterGiftCard = (price - giftCardDiscount).clamp(0.0, double.infinity);

    // Check wallet balance
    if (!isFirstSession && finalPriceAfterGiftCard > 0 && walletBalance < finalPriceAfterGiftCard) {
      _showSnackBar(
        'Insufficient wallet balance. Your balance (SAR ${walletBalance.toStringAsFixed(2)}) '
        'is less than the session price (SAR ${finalPriceAfterGiftCard.toStringAsFixed(2)}). '
        'Please top up your wallet.' 
      );
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');
      if (token == null) throw Exception('No authentication token found');

      // Prepare booking data
      final fullBookingData = {
        ...?sessionData,
        'consultingExpertId': consultingExpert?['_id'],
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'mobile': mobileController.text,
        'email': emailController.text,
        'note': noteController.text,
        'bookingType': 'individual',
        'paymentMethod': (isFirstSession || finalPriceAfterGiftCard == 0) ? 'free' : 'wallet',
        'price': finalPriceAfterGiftCard,
        'originalPrice': price,
        'isFreeSession': isFirstSession,
        'selectedDate': selectedDate,
        'selectedTimeSlot': selectedTimeSlot,
        if (appliedGiftCard != null) 'redemptionCode': appliedGiftCard!['code'],
      };

      // Store token before payment
      await prefs.setString('tempExpertToken', token);

      // Create session
      final sessionResponse = await http.post(
        Uri.parse('$baseUrl/api/session/experttoexpertsession'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(fullBookingData),
      );

      if (sessionResponse.statusCode != 200) {
        throw Exception('Failed to create session');
      }

      final sessionResponseData = json.decode(sessionResponse.body);
      if (sessionResponseData['session'] == null) {
        throw Exception('Session data not found in response');
      }
      final sessionId = sessionResponseData['session']['_id'] as String?;
      if (sessionId == null) {
        throw Exception('Session ID is null');
      }

      // Make payment if not free
      if (!isFirstSession && finalPriceAfterGiftCard > 0) {
        final paymentResponse = await http.post(
          Uri.parse('$baseUrl/api/wallet/pay'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'sessionId': sessionId,
            'amount': finalPriceAfterGiftCard,
          }),
        );

        if (paymentResponse.statusCode != 200) {
          throw Exception('Payment failed');
        }

        // Update local wallet balance
        setState(() {
          walletBalance -= finalPriceAfterGiftCard;
        });
      }

      // Store session ID and clean up
      await prefs.setString('pendingSessionId', sessionId);
      await prefs.remove('sessionData');
      await prefs.remove('consultingExpertData');
      await prefs.remove('bookingData');

      final successMessage = isFirstSession
          ? 'Free session booked successfully! Redirecting to video call...'
          : finalPriceAfterGiftCard == 0 && appliedGiftCard != null
              ? 'Gift card applied! Session booked successfully. Redirecting to video call...'
              : 'Payment successful! Redirecting to video call...';

      _showSnackBar(successMessage);

      // Navigate to video call after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const ExpertPaymentScreen(),
        //   ),
        // );
      }
    } catch (e) {
      print('Booking error: $e');
      _showSnackBar('Booking failed: $e');
    } finally {
      setState(() {
        isBooking = false;
      });
    }
  }

  void _handleTopUpWallet() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => const PaymentOption(),
    //   ),
    // );
  }

  void _updateWordCount(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    setState(() {
      wordCount = words.where((word) => word.isNotEmpty).length;
    });
  }

  // Build expert photo header
 Widget _buildExpertPhotoHeader() {
  return Center(
    child: Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: ClipOval(
            child: consultingExpert?['profileImage'] != null
                ? Image.network(
                    consultingExpert!['profileImage'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          consultingExpert?['firstName'] ?? 'Expert Name',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          consultingExpert?['areaOfExpertise'] ?? 'Professional',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}  @override
 
  Widget build(BuildContext context) {
    if (isLoadingBalance || isCheckingEligibility) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final price = isFirstSession ? 0.0 : (sessionData?['price']?.toDouble() ?? 0.0);
    final finalPriceAfterGiftCard = (price - giftCardDiscount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header greeting
                Text(
                  "Hi, ${firstNameController.text.isNotEmpty ? firstNameController.text : 'Expert'}",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 6),

                // Page title
                const Text(
                  "Booking",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Expert photo header at the top
                if (consultingExpert != null) _buildExpertPhotoHeader(),
                const SizedBox(height: 16),

                // Wallet Balance Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wallet Balance',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'SAR ${walletBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (walletBalance < finalPriceAfterGiftCard && !isFirstSession)
                        ElevatedButton(
                          onPressed: _handleTopUpWallet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Top Up', style: TextStyle(fontSize: 14)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Free Session Indicator
                if (isFirstSession)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'This is your FREE first session!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (isFirstSession) const SizedBox(height: 12),

                // Expert details section
                Container(
                  color: const Color(0xFFF8F7F3),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sessions section
                      const Text(
                        "Sessions-",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time slots
                      ...(_buildTimeSlots()),

                      const SizedBox(height: 12),

                      // Important note
                      const Text(
                        "Note - Can add up to 5 sessions at different time slots. Any 1 timeslot might get selected.",
                        style: TextStyle(
                          color: Color(0xFFFE3232),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form fields container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Change button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            _showSnackBar("Change profile functionality");
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Change",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // First Name field
                      _buildTextFormField(
                        label: "First Name",
                        controller: firstNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Last Name field
                      _buildTextFormField(
                        label: "Last Name",
                        controller: lastNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Mobile Number field
                      _buildTextFormField(
                        label: "Mobile Number",
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (value.length < 10) {
                            return 'Please enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email field
                      _buildTextFormField(
                        label: "Email",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Note field
                      _buildTextFormField(
                        label: "Note (minimum 25 words)",
                        controller: noteController,
                        maxLines: 4,
                        onChanged: (value) {
                          _updateWordCount(value);
                          _saveBookingData();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a note';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),

                      // Word count and error
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Words: $wordCount/25',
                            style: TextStyle(
                              color: wordCount >= 25 ? Colors.green : Colors.red,
                              fontSize: 10,
                            ),
                          ),
                          if (noteError.isNotEmpty)
                            Text(
                              noteError,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Gift Card Section (only if not first session)
                if (!isFirstSession) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gift Card',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        if (appliedGiftCard == null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: giftCardController,
                                  decoration: const InputDecoration(
                                    hintText: "Enter gift card code",
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: isCheckingGiftCard ? null : _handleApplyGiftCard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                child: isCheckingGiftCard
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Apply', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.card_giftcard, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gift Card Applied: ${appliedGiftCard!['code']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Discount: SAR ${giftCardDiscount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _handleRemoveGiftCard,
                                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Price Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      if (!isFirstSession)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Price",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "SAR ${price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      
                      if (giftCardDiscount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Gift Card Discount",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                "-SAR ${giftCardDiscount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      

                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Colors.grey),
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFirstSession ? "Total" : "Final Price",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isFirstSession
                                ? "FREE"
                                : "SAR ${finalPriceAfterGiftCard.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isFirstSession ? Colors.green : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Book Now button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: isBooking ? null : _handleBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: isBooking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "BOOK NOW",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build time slot buttons
 List<Widget> _buildTimeSlots() {
    return availableSlots.map((slot) {
      final date = slot['date'];
      final slots = List<String>.from(slot['timeSlots']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: slots.map((time) {
              final isSelected = selectedDate == date && selectedTimeSlot == time;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                    selectedTimeSlot = time;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey,
                    ),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
      );
    }).toList();
  }


  // Helper method to build text form fields
  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
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
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  // Helper method to show snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}