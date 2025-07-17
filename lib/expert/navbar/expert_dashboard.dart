import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard',
      home: DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Models for API response
class PaymentReviewData {
  final String id;
  final String userName;
  final String date;
  final String time;
  final int sessionDuration;
  final double sessionFee;
  final double expertEarnings;
  final double rating;
  final String feedback;
  final bool isCompleted;
  final String status;

  PaymentReviewData({
    required this.id,
    required this.userName,
    required this.date,
    required this.time,
    required this.sessionDuration,
    required this.sessionFee,
    required this.expertEarnings,
    required this.rating,
    required this.feedback,
    required this.isCompleted,
    required this.status,
  });

  factory PaymentReviewData.fromJson(Map<String, dynamic> json) {
    return PaymentReviewData(
      id: json['id']?.toString() ?? '',
      userName: json['userName'] ?? json['user_name'] ?? 'Unknown User',
      date: json['date'] ?? json['session_date'] ?? '',
      time: json['time'] ?? json['session_time'] ?? '',
      sessionDuration: json['sessionDuration'] ?? json['session_duration'] ?? 60,
      sessionFee: (json['sessionFee'] ?? json['session_fee'] ?? 0).toDouble(),
      expertEarnings: (json['expertEarnings'] ?? json['expert_earnings'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      feedback: json['feedback'] ?? json['review'] ?? '',
      isCompleted: json['isCompleted'] ?? json['is_completed'] ?? false,
      status: json['status'] ?? 'pending',
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedMainTab = 0; // 0 for Dashboard, 1 for Payment & Reviews
  
  // Dashboard tab states
  String selectedTimeFrame = 'All';
  String selectedTab = 'Sales';
  
  // Payment & Reviews tab states
  int selectedPaymentTab = 0; // 0 for Payments, 1 for Reviews
  
  // API related variables
  List<PaymentReviewData> paymentReviewData = [];
  bool isLoading = false;
  String? errorMessage;
  int currentPage = 1;
  int totalItems = 0;
  static const int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    // Load data when the widget is first created
    _loadPaymentReviewData();
  }

  // Get stored auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('expertToken'); // Adjust key based on your storage
  }

  // API call to fetch payment and review data
  Future<void> _loadPaymentReviewData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Replace with your actual API base URL
      const String apiBaseUrl = 'https://amd-api.code4bharat.com'; // Replace with your actual API URL
      final String apiUrl = '$apiBaseUrl/api/wallet/expert-payout-history';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // Adjust these based on your actual API response structure
        final List<dynamic> dataList = jsonResponse['data'] ?? jsonResponse['payments'] ?? [];
        totalItems = jsonResponse['total'] ?? dataList.length;

        setState(() {
          paymentReviewData = dataList.map((item) => PaymentReviewData.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
      print('API Error: $e');
    }
  }

  // Refresh data
  Future<void> _refreshData() async {
    await _loadPaymentReviewData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Main tab selector
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildMainTabButton('Dashboard', 0),
                    SizedBox(width: 20),
                    _buildMainTabButton('Payment & Reviews', 1),
                  ],
                ),
              ),
            ),
            
            // Content based on selected main tab
            Expanded(
              child: selectedMainTab == 0 ? _buildDashboardContent() : _buildPaymentReviewsContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ExpertBottomNavbar(
        currentIndex: 4,
      ),
    );
  }

  Widget _buildMainTabButton(String text, int index) {
    bool isSelected = selectedMainTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMainTab = index;
        });
        // Load data when switching to Payment & Reviews tab
        if (index == 1 && paymentReviewData.isEmpty) {
          _loadPaymentReviewData();
        }
      },
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Container(
            height: 2,
            width: text.length * 8.0,
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text
            Text(
              'Dashboard. Take a deeper look at your\nrevenue & more',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),

            // Main dashboard card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[500]!,
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Time frame selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTimeFrameButton('All'),
                        _buildTimeFrameButton('Today'),
                        _buildTimeFrameButton('Wednesday'),
                        _buildTimeFrameButton('TW'),
                        _buildTimeFrameButton('1M'),
                        _buildTimeFrameButton('1Y'),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Tab selector
                    Row(
                      children: [
                        _buildTabButton('Sales'),
                        SizedBox(width: 20),
                        _buildTabButton('Completed'),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Main revenue box - calculate from API data
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F4FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '\$${_calculateTotalRevenue()}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Total Revenue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Two smaller revenue boxes
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFE8F4FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '\$${_calculateCompletedRevenue()}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Completed Revenue',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFE8F4FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '\$${_calculatePendingRevenue()}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Pending Revenue',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Discount Coupon Section (keeping original static content)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discount Coupon User Count',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),

                    // First coupon
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FreeAMD',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '15% OFF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Used by: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: '200',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Second coupon
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FreeAMD',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '15% OFF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Used by: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: '200',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildPaymentReviewsContent() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(height: 20),
          // Payment & Reviews Tab Section
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPaymentTab = 0;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedPaymentTab == 0 ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: selectedPaymentTab == 0 ? null : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Payments',
                      style: TextStyle(
                        color: selectedPaymentTab == 0 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPaymentTab = 1;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedPaymentTab == 1 ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: selectedPaymentTab == 1 ? null : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Reviews',
                      style: TextStyle(
                        color: selectedPaymentTab == 1 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Spacer(),
                // Refresh button
                IconButton(
                  onPressed: _refreshData,
                  icon: Icon(Icons.refresh),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          // Horizontal border
          Container(
            height: 1,
            color: Color(0xFFFE3232),
          ),
          SizedBox(height: 15),
          
          // Content based on loading state
          Expanded(
            child: isLoading 
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildSessionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (paymentReviewData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: paymentReviewData.length,
            itemBuilder: (context, index) {
              final data = paymentReviewData[index];
              return Column(
                children: [
                  SessionItem(
                    data: data,
                    isReviewsTab: selectedPaymentTab == 1,
                    isInitiallyExpanded: index == 0,
                  ),
                  Container(height: 1, color: Color(0xFFFE3232)),
                ],
              );
            },
          ),
        ),
        
        SizedBox(height: 40),
        
        // Pagination
        Center(
          child: Text(
            '$totalItems Total',
            style: TextStyle(
              color: Color(0xFFFE3232),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 15),
        
        // Page numbers with white background and shadow
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          margin: EdgeInsets.symmetric(horizontal: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left, color: Colors.grey),
              SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Color(0xFFFE3232),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$currentPage',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text('2', style: TextStyle(color: Colors.grey)),
              SizedBox(width: 15),
              Text('3', style: TextStyle(color: Colors.grey)),
              SizedBox(width: 10),
              Icon(Icons.chevron_right, color: Color(0xFFFE3232)),
            ],
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  // Helper methods to calculate revenue from API data
  String _calculateTotalRevenue() {
    double total = paymentReviewData.fold(0.0, (sum, item) => sum + item.expertEarnings);
    return total.toStringAsFixed(2);
  }

  String _calculateCompletedRevenue() {
    double completed = paymentReviewData
        .where((item) => item.isCompleted)
        .fold(0.0, (sum, item) => sum + item.expertEarnings);
    return completed.toStringAsFixed(2);
  }

  String _calculatePendingRevenue() {
    double pending = paymentReviewData
        .where((item) => !item.isCompleted)
        .fold(0.0, (sum, item) => sum + item.expertEarnings);
    return pending.toStringAsFixed(2);
  }

  Widget _buildTimeFrameButton(String text) {
    bool isSelected = selectedTimeFrame == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimeFrame = text;
        });
        // You can add filtering logic here based on timeframe
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text) {
    bool isSelected = selectedTab == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = text;
        });
        // You can add filtering logic here based on tab
      },
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class SessionItem extends StatefulWidget {
  final PaymentReviewData data;
  final bool isInitiallyExpanded;
  final bool isReviewsTab;

  const SessionItem({
    Key? key,
    required this.data,
    this.isInitiallyExpanded = false,
    this.isReviewsTab = false,
  }) : super(key: key);

  @override
  _SessionItemState createState() => _SessionItemState();
}

class _SessionItemState extends State<SessionItem> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Star rating and name together on left
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: widget.data.rating > 0 ? Colors.amber : Colors.grey,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          widget.data.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Only show name in Payments tab
                        if (!widget.isReviewsTab) ...[
                          SizedBox(width: 15),
                          Text(
                            widget.data.userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${widget.data.date}    ${widget.data.time}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4CB269),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Session duration and arrow on right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: 8),
                  
                  // Session duration and arrow in a row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.data.sessionDuration} min Session',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      
                      // Arrow (clickable)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          // Expanded content for session
          if (isExpanded) ...[
            SizedBox(height: 15),
            Container(height: 1, color: Color(0xFFFE3232)),
            SizedBox(height: 12),
            
            // Different content based on tab
            if (widget.isReviewsTab) ...[
              // Reviews tab content
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Feedback',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color.fromARGB(255, 12, 12, 12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Text(
                  widget.data.feedback.isNotEmpty 
                    ? widget.data.feedback 
                    : 'No feedback provided',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: 8),              
            ] else ...[
              // Payments tab content
              Row(
                children: [
                  Text(
                    'SESSION FEE - \$${widget.data.sessionFee.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFE3232),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'EXPERT EARNINGS - \$${widget.data.expertEarnings.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4CB269),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Spacer(),
                  Icon(
                    widget.data.isCompleted ? Icons.check_circle : Icons.access_time,
                    color: widget.data.isCompleted ? Color(0xFF4CB269) : Colors.orange,
                    size: 18,
                  ),
                  SizedBox(width: 5),
                  Text(
                    widget.data.isCompleted ? 'Completed' : 'Pending',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}