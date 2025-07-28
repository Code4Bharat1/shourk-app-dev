import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'expert_session_call.dart';

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({Key? key}) : super(key: key);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final String apiUrl = "http://192.168.0.123:5070";

  String? _userToken;
  String? _userId;
  String _activeTab = "bookings";
  List<dynamic> _mySessions = [];
  List<dynamic> _myBookings = [];
  bool _loadingBookings = true;
  bool _loadingSessions = true;
  String? _errorBookings;
  String? _errorSessions;
  Map<String, dynamic> _sessionState = {};
  bool _showCancelModal = false;
  dynamic _sessionToCancel;
  bool _loadingCancel = false;
  String _sessionFilter = "all";
  String _firstName = "";
  String _lastName = "";
  String? _profileImageUrl;
  String _userInitials = "E";

  // Track selected slots for each session
  Map<String, Map<String, dynamic>> _selectedSlots = {};

  // Cancellation reasons
  List<Map<String, dynamic>> _cancellationReasons = [
    {"id": 1, "reason": "Schedule conflict", "checked": false},
    {"id": 2, "reason": "Found alternative solution", "checked": false},
    {"id": 3, "reason": "Expert not suitable for my needs", "checked": false},
    {"id": 4, "reason": "Technical issues", "checked": false},
    {"id": 5, "reason": "Cost concerns", "checked": false},
    {"id": 6, "reason": "Other", "checked": false},
  ];
  String _otherReason = "";
  bool _termsAccepted = false;

  // Enhanced recursive conversion with type safety
  dynamic _recursiveConvert(dynamic item) {
    if (item == null) return null;

    if (item is Map) {
      final Map<String, dynamic> result = {};
      item.forEach((key, value) {
        final String stringKey = key.toString();
        result[stringKey] = _recursiveConvert(value);
      });
      return result;
    }

    if (item is List) {
      return item.map(_recursiveConvert).toList();
    }

    return item;
  }

  // Slot availability state
  List<Map<String, dynamic>> _availabilitySlots = [];
  bool _loadingSlots = true;
  String _slotsError = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchAvailabilitySlots();
  }

  Future<void> _initializeData() async {
    try {
      await _getValidToken();
      if (_userToken != null && _userId != null) {
        await _fetchUserProfile();
        await _fetchBookings();
        await _fetchSessions();
      } else {
        _handleTokenError("Failed to get valid token");
      }
    } catch (e) {
      _handleTokenError("Initialization failed: ${e.toString()}");
    }
  }

  Future<void> _getValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userToken = prefs.getString('expertToken');

      if (_userToken == null) {
        _handleTokenError("No token found in storage");
        return;
      }

      // Decode token to get userId
      Map<String, dynamic> decodedToken = JwtDecoder.decode(_userToken!);
      _userId = decodedToken['_id'];

      // Check if token is expired
      if (JwtDecoder.isExpired(_userToken!)) {
        await _refreshToken();
      }
    } catch (e) {
      _handleTokenError("Token parsing failed: ${e.toString()}");
    }
  }

  Future<void> _refreshToken() async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/expertauth/refresh-token'),
        headers: {'Authorization': 'Bearer $_userToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userToken = data['newToken'];

        // Save the new token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('expertToken', _userToken!);
      } else if (response.statusCode == 402) {
        _handlePaymentError();
      } else {
        _handleTokenError(
          "Token refresh failed with status: ${response.statusCode}\nBody: ${response.body}",
        );
      }
    } catch (e) {
      _handleTokenError("Token refresh error: ${e.toString()}");
    }
  }

  void _handleTokenError(String message) {
    print("🔑 Token Error: $message");
    setState(() {
      _errorBookings = "Authentication error. Please log in again.";
      _errorSessions = "Authentication error. Please log in again.";
      _loadingBookings = false;
      _loadingSessions = false;
    });
  }

  void _handlePaymentError() {
    print("💳 Payment Required (402) Error");
    setState(() {
      _errorBookings = "Payment required. Please check your subscription.";
      _errorSessions = "Payment required. Please check your subscription.";
      _loadingBookings = false;
      _loadingSessions = false;
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _authenticatedGet('/api/expertauth/$_userId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == true) {
          final userData = data['data'] as Map<String, dynamic>?;
          setState(() {
            _firstName = userData?['firstName']?.toString() ?? '';
            _lastName = userData?['lastName']?.toString() ?? '';
            _profileImageUrl = userData?['photoFile']?.toString();
            _userInitials = _getUserInitials(_firstName, _lastName);
          });
        } else {
          print("❌ Invalid profile response structure: $data");
        }
      } else if (response.statusCode == 402) {
        _handlePaymentError();
      } else {
        print(
          "⚠️ Profile fetch failed: ${response.statusCode}\n${response.body}",
        );
      }
    } catch (e) {
      print("🚨 Profile fetch error: ${e.toString()}");
    }
  }

  Future<void> _fetchBookings() async {
    setState(() => _loadingBookings = true);

    try {
      final response = await _authenticatedGet('/api/session/mybookings');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final convertedData = _recursiveConvert(data);

        if (convertedData is List) {
          setState(() => _myBookings = convertedData);
        } else if (convertedData is Map<String, dynamic> &&
            convertedData.containsKey('data')) {
          final bookingsData = convertedData['data'];
          if (bookingsData is List) {
            setState(() => _myBookings = bookingsData);
          } else {
            print(
              "⚠️ Bookings data is not a list: ${bookingsData.runtimeType}",
            );
          }
        } else {
          print("⚠️ Unexpected bookings response structure: $convertedData");
        }
      } else if (response.statusCode == 402) {
        _handlePaymentError();
      } else {
        setState(
          () =>
              _errorBookings =
                  "Failed to load bookings: ${response.statusCode}\n${response.body}",
        );
      }
    } catch (e) {
      setState(() => _errorBookings = "Bookings error: ${e.toString()}");
      print("🚨 Bookings fetch error: ${e.toString()}");
    } finally {
      setState(() => _loadingBookings = false);
    }
  }

  Future<void> _fetchSessions() async {
    setState(() => _loadingSessions = true);

    try {
      final response = await _authenticatedGet('/api/session/getexpertsession');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final convertedData =
            _recursiveConvert(data) as Map<String, dynamic>; // Add cast here

        print("🔍 Raw sessions response: $convertedData");

        // Extract sessions with explicit casting
        final expertSessions =
            (convertedData['expertSessions'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final userSessions =
            (convertedData['userSessions'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        final combined = [
          ...expertSessions.map(
            (s) => {...s, 'type': 'Expert', 'sessionType': 'expert-to-expert'},
          ),
          ...userSessions.map(
            (s) => {...s, 'type': 'User', 'sessionType': 'user-to-expert'},
          ),
        ];

        // If no sessions, mock a pending session for debugging
        if (combined.isEmpty) {
          print('No sessions found, adding a mock pending session for debug.');
          combined.add({
            '_id': 'mock123',
            'type': 'User',
            'status': 'pending',
            'slots': [
              {
                'selectedDate': DateTime.now().toIso8601String().substring(
                  0,
                  10,
                ),
                'selectedTime': '10:00 AM',
              },
              {
                'selectedDate': DateTime.now().toIso8601String().substring(
                  0,
                  10,
                ),
                'selectedTime': '2:00 PM',
              },
            ],
            'userId': {'firstName': 'Test', 'lastName': 'User'},
            'duration': '30 min',
            'sessionType': 'Video',
            'note': 'This is a mock session for debugging.',
          });
        }

        setState(() => _mySessions = combined);
      } else if (response.statusCode == 402) {
        _handlePaymentError();
      } else {
        setState(
          () =>
              _errorSessions =
                  "Failed to load sessions: ${response.statusCode}\n${response.body}",
        );
      }
    } catch (e) {
      setState(() => _errorSessions = "Sessions error: ${e.toString()}");
      print("🚨 Sessions fetch error: ${e.toString()}");
    } finally {
      setState(() => _loadingSessions = false);
    }
  }

  // Get filtered sessions based on current filter selection
  List<Map<String, dynamic>> getFilteredSessions() {
    if (_sessionFilter == "all") {
      return List<Map<String, dynamic>>.from(_mySessions);
    } else {
      return List<Map<String, dynamic>>.from(
        _mySessions.where((session) => session['type'] == _sessionFilter),
      );
    }
  }

  Future<http.Response> _authenticatedGet(String path) async {
    await _getValidToken();
    final url = Uri.parse('$apiUrl$path');

    if (_userToken == null) {
      return http.Response('No token available', 401);
    }

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_userToken'},
      );

      if (response.statusCode == 402) {
        return response;
      }

      if (response.statusCode == 401) {
        await _refreshToken();
        return await http.get(
          url,
          headers: {'Authorization': 'Bearer $_userToken'},
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  String _getUserInitials(String firstName, String lastName) {
    String initials = "";
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];
    return initials.isNotEmpty ? initials.toUpperCase() : "E";
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'confirmed' || statusLower == 'accepted') {
      return Colors.green;
    } else if (statusLower == 'pending' || statusLower == 'penciling') {
      return Colors.orange;
    } else if (statusLower == 'rejected' ||
        statusLower == 'declined' ||
        statusLower == 'cancelled') {
      return Colors.red;
    } else if (statusLower == 'completed') {
      return Colors.blue;
    } else if (statusLower == 'unconfirmed') {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEE, MMM d').format(date);
    } catch (e) {
      return "Invalid date";
    }
  }

  void _handleSlotSelection(String sessionId, Map<String, dynamic> slot) {
    setState(() {
      _selectedSlots[sessionId] = slot;
    });
  }

  Future<void> _acceptSession(String sessionId, String sessionType) async {
  final selectedSlot = _selectedSlots[sessionId];
  if (selectedSlot == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a time slot')),
    );
    return;
  }

  try {
    http.Response response;
    
    // Check session type and use appropriate API (normalize to lowercase for comparison)
    String normalizedSessionType = sessionType.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    
    if (normalizedSessionType.contains('experttoexpert') || normalizedSessionType.contains('expertoexpert')) {
      // Expert-to-Expert session: Use PUT /api/expertsession/accept first, then confirm status
      print('Accepting Expert-to-Expert session: $sessionId');
      
      // Step 1: Accept the session with selected slot
      response = await _authenticatedPut('/api/expertsession/accept', {
        'id': sessionId,
        'selectedDate': selectedSlot['selectedDate'],
        'selectedTime': selectedSlot['selectedTime'],
      });
      
      if (response.statusCode == 200) {
        // Step 2: Confirm the session status
        print('Confirming Expert-to-Expert session status: $sessionId');
        response = await _authenticatedPatch(
          '/api/expertsession/$sessionId/status',
          {'status': 'confirmed'},
        );
      }
      
    } else if (normalizedSessionType.contains('usertoexpert') || normalizedSessionType.contains('useroexpert')) {
      // User-to-Expert session: PATCH /api/usersession/:sessionId/status
      print('Confirming User-to-Expert session: $sessionId');
      response = await _authenticatedPatch(
        '/api/usersession/$sessionId/status',
        {'status': 'confirmed'},
      );
      
    } else if (normalizedSessionType.contains('usertouser') || normalizedSessionType.contains('userouser')) {
      // User-to-User session: PATCH /api/usersession/:sessionId/status
      print('Confirming User-to-User session: $sessionId');
      response = await _authenticatedPatch(
        '/api/usersession/$sessionId/status',
        {'status': 'confirmed'},
      );
      
    } else {
      // Unknown session type
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown session type: $sessionType')),
      );
      return;
    }

    // Handle response
    if (response.statusCode == 200) {
      setState(() {
        // Update _mySessions list
        final sessionIndex = _mySessions.indexWhere(
          (s) => s['_id'] == sessionId,
        );
        if (sessionIndex != -1) {
          _mySessions[sessionIndex]['status'] = 'confirmed';
          _mySessions[sessionIndex]['slots'] = [selectedSlot];
        }
        
        // Update _myBookings list
        final bookingIndex = _myBookings.indexWhere(
          (b) => b['_id'] == sessionId,
        );
        if (bookingIndex != -1) {
          _myBookings[bookingIndex]['status'] = 'confirmed';
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session accepted and confirmed successfully')),
      );
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept session: ${response.body}')),
      );
    }
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error accepting session: ${e.toString()}')),
    );
  }
}

  Future<http.Response> _authenticatedPatch(
    String path,
    Map<String, dynamic> body,
  ) async {
    await _getValidToken();
    final url = Uri.parse('$apiUrl$path');

    if (_userToken == null) {
      return http.Response('No token available', 401);
    }

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $_userToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 401) {
        await _refreshToken();
        return await http.patch(
          url,
          headers: {
            'Authorization': 'Bearer $_userToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> _authenticatedPut(
    String path,
    Map<String, dynamic> body,
  ) async {
    await _getValidToken();
    final url = Uri.parse('$apiUrl$path');

    if (_userToken == null) {
      return http.Response('No token available', 401);
    }

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $_userToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 401) {
        await _refreshToken();
        return await http.put(
          url,
          headers: {
            'Authorization': 'Bearer $_userToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  void _handleCancelClick(dynamic session) {
    setState(() {
      _sessionToCancel = session;
      _showCancelModal = true;
      _cancellationReasons =
          _cancellationReasons.map((r) => {...r, "checked": false}).toList();
      _otherReason = "";
      _termsAccepted = false;
    });
  }

  // Helper to get the correct label for 'Booking with ...'
  String getBookingLabel(Map<String, dynamic> session) {
    final sessionType = session['sessionType']?.toString() ?? '';
    if (sessionType == 'Expert To Expert' ||
        sessionType == 'ExpertToExpertSession') {
      final expert = session['consultingExpertID'];
      final expertName =
          expert is Map
              ? '${expert['firstName'] ?? ''} ${expert['lastName'] ?? ''}'
              : expert?.toString() ?? '';
      return 'Booking with $expertName';
    } else {
      final expert = session['consultingExpertID'] ?? session['expertId'];
      final expertName =
          expert is Map
              ? '${expert['firstName'] ?? ''} ${expert['lastName'] ?? ''}'
              : expert?.toString() ?? '';
      return 'Booking with $expertName';
    }
  }

  // Improved helper to get the correct label for 'Consultation with Client ...'
  String getConsultationLabel(Map<String, dynamic> session) {
    final sessionType = session['sessionType']?.toString() ?? '';
    String clientName = '';
    if (sessionType == 'Expert To Expert' ||
        sessionType == 'ExpertToExpertSession') {
      // Try consultingExpertID first
      final expert = session['consultingExpertID'];
      if (expert is Map &&
          (expert['firstName'] != null || expert['lastName'] != null)) {
        clientName =
            '${expert['firstName'] ?? ''} ${expert['lastName'] ?? ''}'.trim();
      }
      // Fallback to booking details
      if (clientName.isEmpty) {
        clientName =
            '${session['firstName'] ?? ''} ${session['lastName'] ?? ''}'.trim();
      }
      // Fallback to expertId if still empty
      if (clientName.isEmpty && session['expertId'] is Map) {
        final expertBooker = session['expertId'];
        clientName =
            '${expertBooker['firstName'] ?? ''} ${expertBooker['lastName'] ?? ''}'
                .trim();
      }
    } else {
      // User to Expert: Try userId first
      final user = session['userId'];
      if (user is Map &&
          (user['firstName'] != null || user['lastName'] != null)) {
        clientName =
            '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
      }
      // Fallback to booking details
      if (clientName.isEmpty) {
        clientName =
            '${session['firstName'] ?? ''} ${session['lastName'] ?? ''}'.trim();
      }
    }
    return 'Consultation with ${clientName.isNotEmpty ? clientName : 'N/A'}';
  }

  // Helper to get the correct client name for a session
  String getClientName(Map<String, dynamic> session) {
    final sessionType = session['sessionType']?.toString() ?? '';
    if (sessionType == 'Expert To Expert' ||
        sessionType == 'ExpertToExpertSession') {
      // Client is the expert who booked (expertId)
      final expert = session['expertId'];
      if (expert is Map) {
        return '${expert['firstName'] ?? ''} ${expert['lastName'] ?? ''}';
      }
      // Fallback to booking details
      return '${session['firstName'] ?? ''} ${session['lastName'] ?? ''}';
    } else {
      // Client is the user who booked (userId)
      final user = session['userId'];
      if (user is Map) {
        return '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
      }
      // Fallback to booking details
      return '${session['firstName'] ?? ''} ${session['lastName'] ?? ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ExpertUpperNavbar(),
      body: Column(
        children: [
          // Header with user info
          _buildUserHeader(),

          // Tab selection
          _buildTabBar(),

          // Main content
          Expanded(
            child:
                _activeTab == "bookings"
                    ? _buildBookingsTab()
                    : _buildSessionsTab(),
          ),
        ],
      ),
      bottomNavigationBar: ExpertBottomNavbar(currentIndex: 1),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            backgroundImage:
                _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
            child:
                _profileImageUrl == null
                    ? Text(
                      _userInitials,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, $_firstName $_lastName",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const Text(
                "Video Consultations",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton("bookings", "My Bookings"),
          _buildTabButton("sessions", "My Sessions"),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _activeTab == tab ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: _activeTab == tab ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    if (_loadingBookings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorBookings != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorBookings!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              if (_errorBookings!.contains("Payment required"))
                ElevatedButton(
                  onPressed: () {
                    // Add payment navigation here
                  },
                  child: const Text('Resolve Payment'),
                ),
            ],
          ),
        ),
      );
    }

    if (_myBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Bookings Yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Your upcoming bookings will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _myBookings.length,
      itemBuilder: (context, index) => _buildBookingCard(_myBookings[index]),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    // Safely extract values with null checks
    final slots = (booking['slots'] as List?)?[0] ?? [];
    final status = booking['status']?.toString()?.toLowerCase() ?? 'pending';
    final expert = booking['consultingExpertID'] as Map<String, dynamic>? ?? {};
    final expertName =
        '${expert['firstName'] ?? ''} ${expert['lastName'] ?? ''}';

    // Determine display status
    String displayStatus = status;
    if (status == 'pending') {
      displayStatus = 'Unconfirmed';
    } else if (status == 'confirmed') {
      displayStatus = 'Confirmed';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    getBookingLabel(booking),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(displayStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayStatus.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(displayStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${slots.isNotEmpty ? slots[0]['selectedTime'] : 'TBD'} • ${booking['duration'] ?? ''}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking['sessionType']?.toString() ?? 'Type',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // People section
            const Text(
              'Participants',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildParticipantRow(
                    icon: Icons.person,
                    label: 'Client',
                    name: '${_firstName} ${_lastName}',
                  ),
                  const SizedBox(height: 10),
                  _buildParticipantRow(
                    icon: Icons.work,
                    label: 'Expert',
                    name: expertName,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Slots section
            const Text(
              'Requested Slots',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, children: _buildSlotChips(slots)),

            const SizedBox(height: 20),

            // Actions section
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(),
                const SizedBox(height: 16),

                if (displayStatus.toLowerCase() == 'confirmed')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Chat'),
                          onPressed: () => _navigateToChat(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.blue.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Join Meeting'),
                          onPressed: () => _joinMeeting(booking),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Center(
                    child: Text(
                      'Waiting for Confirmation',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _handleCancelClick(booking),
                  child: const Text(
                    'Cancel Session',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow({
    required IconData icon,
    required String label,
    required String name,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildSlotChips(List<dynamic> slots) {
    if (slots.isEmpty) {
      return [const Chip(label: Text('No slots available'))];
    }

    return slots.map((slot) {
      final date = slot['selectedDate']?.toString();
      final time = slot['selectedTime']?.toString();

      return Chip(
        backgroundColor: Colors.blue[50],
        label: Text(
          '${_formatDate(date)} • ${time ?? "N/A"}',
          style: TextStyle(color: Colors.blue[700]),
        ),
      );
    }).toList();
  }

  Widget _buildSessionsTab() {
    final filteredSessions = getFilteredSessions();

    return Column(
      children: [
        // Filter buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton("all", "All"),
              const SizedBox(width: 8),
              _buildFilterButton("User", "User Sessions"),
              const SizedBox(width: 8),
              _buildFilterButton("Expert", "Expert Sessions"),
            ],
          ),
        ),

        // Session count indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                "Showing ${filteredSessions.length} ${filteredSessions.length == 1 ? 'session' : 'sessions'}",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Spacer(),
              if (_sessionFilter != "all")
                Text(
                  _sessionFilter == "User"
                      ? "User Sessions"
                      : "Expert Sessions",
                  style: TextStyle(
                    color:
                        _sessionFilter == "User"
                            ? Colors.green[700]
                            : Colors.purple[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),

        // Content
        Expanded(
          child:
              _loadingSessions
                  ? const Center(child: CircularProgressIndicator())
                  : _errorSessions != null
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorSessions!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_errorSessions!.contains("Payment required"))
                            ElevatedButton(
                              onPressed: () {
                                // Add payment navigation here
                              },
                              child: const Text('Resolve Payment'),
                            ),
                        ],
                      ),
                    ),
                  )
                  : filteredSessions.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_sessionFilter == "all" ? "" : _sessionFilter} Sessions',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sessionFilter == "all"
                              ? 'You have no upcoming sessions'
                              : 'You have no $_sessionFilter sessions',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredSessions.length,
                    itemBuilder:
                        (context, index) =>
                            _buildSessionCard(filteredSessions[index]),
                  ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    return Flexible(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _sessionFilter == filter ? Colors.blue : Colors.grey[300],
          foregroundColor:
              _sessionFilter == filter ? Colors.white : Colors.grey[700],
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => setState(() => _sessionFilter = filter),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    // Debug print to inspect session data
    print('Session data: ${session.toString()}');
    // Safely extract values with type checking
    final slotsRaw = session['slots'] as List? ?? [];
    List<Map<String, dynamic>> slots = [];
    for (var e in slotsRaw) {
      if (e is Map) {
        slots.add(Map<String, dynamic>.from(e));
      } else if (e is List) {
        for (var inner in e) {
          if (inner is Map) {
            slots.add(Map<String, dynamic>.from(inner));
          }
        }
      }
    }
    print('Parsed slots: $slots');
    final status = session['status']?.toString()?.toLowerCase() ?? 'pending';
    // Debug print to inspect status
    print('Session status: $status');

    // Safely handle client data
    String clientName = "Unknown";
    if (session['type'] == 'User') {
      final client = session['userId'];
      if (client is Map) {
        clientName = '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}';
      } else if (client is String) {
        clientName = client;
      }
    } else {
      final expert = session['consultingExpertID'];
      if (expert is Map) {
        clientName = '${expert['firstName'] ?? ''} ${expert['lastName'] ?? ''}';
      } else if (expert is String) {
        clientName = expert;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    session['type'] == 'User'
                        ? Colors.green[50]
                        : Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                session['type'] == 'User' ? 'USER SESSION' : 'EXPERT SESSION',
                style: TextStyle(
                  color:
                      session['type'] == 'User'
                          ? Colors.green[700]
                          : Colors.purple[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    getConsultationLabel(session),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Time and duration
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${slots.isNotEmpty ? slots[0]['selectedTime'] : 'TBD'} • ${session['duration'] ?? ''}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session['sessionType']?.toString() ?? 'Type',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Main content row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: People
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'People',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildParticipantRow(
                              icon: Icons.person,
                              label: 'Client',
                              name: getClientName(session),
                            ),
                            const SizedBox(height: 10),
                            _buildParticipantRow(
                              icon: Icons.phone,
                              label: 'Contact',
                              name:
                                  session['phone']?.toString() ??
                                  session['mobile']?.toString() ??
                                  'N/A',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right column: Slot selection or confirmed slot
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (status == 'pending' || status == 'unconfirmed')
                        const Text(
                          'Select Date & Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),

                      if (status == 'confirmed' && slots.isNotEmpty)
                        const Text(
                          'Confirmed Slot',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),

                      const SizedBox(height: 8),

                      if (status == 'pending' || status == 'unconfirmed')
                        _buildSlotSelection(session, slots),

                      if (status == 'confirmed' && slots.isNotEmpty)
                        _buildConfirmedSlotDisplay(slots[0]),

                      const SizedBox(height: 16),

                      // Actions
                      _buildSessionActions(session, status),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Session notes
            if (session['note'] != null &&
                session['note'].toString().isNotEmpty) ...[
              const Text(
                'Note:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session['note'].toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSelection(
    Map<String, dynamic> session,
    List<Map<String, dynamic>> slots,
  ) {
    final sessionId = session['_id']?.toString() ?? '';
    final selectedDate = _sessionState[sessionId]?['selectedDate']?.toString();
    final selectedTime = _sessionState[sessionId]?['selectedTime']?.toString();

    // Group slots by date
    final Map<String, List<String>> groupedSlots = {};
    for (final slot in slots) {
      final date = slot['selectedDate']?.toString();
      final time = slot['selectedTime']?.toString();
      if (date != null && time != null) {
        groupedSlots.putIfAbsent(date, () => []).add(time);
      }
    }

    if (groupedSlots.isEmpty) {
      return const Text('No slots available for this session.');
    }

    // Ensure selectedDate is in the keys, else set to null
    final safeSelectedDate =
        (selectedDate != null && groupedSlots.keys.contains(selectedDate))
            ? selectedDate
            : null;
    // Ensure selectedTime is in the available times for the selected date, else set to null
    final safeSelectedTime =
        (selectedTime != null &&
                safeSelectedDate != null &&
                groupedSlots[safeSelectedDate]?.contains(selectedTime) == true)
            ? selectedTime
            : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date dropdown
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: safeSelectedDate,
            hint: const Text('Select a date'),
            items:
                groupedSlots.keys.map((date) {
                  return DropdownMenuItem<String>(
                    value: date,
                    child: Text(_formatDate(date)),
                  );
                }).toList(),
            onChanged: (date) {
              setState(() {
                _sessionState[sessionId] = {
                  ..._sessionState[sessionId] ?? {},
                  'selectedDate': date,
                  'selectedTime': null, // Reset time when date changes
                };
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        // Time dropdown
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: safeSelectedTime,
            hint: const Text('Select a time'),
            items:
                safeSelectedDate != null &&
                        groupedSlots[safeSelectedDate] != null
                    ? groupedSlots[safeSelectedDate]!.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text(time),
                      );
                    }).toList()
                    : [],
            onChanged: (time) {
              setState(() {
                _sessionState[sessionId] = {
                  ..._sessionState[sessionId] ?? {},
                  'selectedTime': time,
                };
                // Find the matching slot
                final slot = slots.firstWhere(
                  (s) =>
                      s['selectedDate'] == safeSelectedDate &&
                      s['selectedTime'] == time,
                  orElse: () => {},
                );
                if (slot.isNotEmpty) {
                  _selectedSlots[sessionId] = slot;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Map<String, List<String>> _groupSlotsByDate(
    List<Map<String, dynamic>> slots,
  ) {
    final Map<String, List<String>> result = {};

    for (final slot in slots) {
      final date = slot['selectedDate']?.toString() ?? 'unknown';
      final time = slot['selectedTime']?.toString() ?? '';

      result.putIfAbsent(date, () => []);

      if (time.isNotEmpty) {
        result[date]!.add(time);
      }
    }

    return result;
  }

  Widget _buildConfirmedSlotDisplay(Map<String, dynamic> slot) {
    final date = slot['selectedDate']?.toString() ?? '';
    final time = slot['selectedTime']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_formatDate(date), style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          const Text(
            'Time',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(time, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSessionActions(Map<String, dynamic> session, String status) {
    final sessionId = session['_id']?.toString() ?? '';
    final selectedDate = _sessionState[sessionId]?['selectedDate']?.toString();
    final selectedTime = _sessionState[sessionId]?['selectedTime']?.toString();
    final sessionType = session['sessionType']?.toString() ?? '';

    if (status == 'pending' || status == 'unconfirmed') {
      return Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineSession(sessionId),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    'Decline Request',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      selectedDate != null && selectedTime != null
                          ? () => _acceptSession(sessionId, sessionType)
                          : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Accept Request'),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (status == 'confirmed') {
      return Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Chat'),
                  onPressed: () => _navigateToChat(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text('Join Meeting'),
                  onPressed: () => _joinMeeting(session),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _handleCancelClick(session),
            child: const Text(
              'Cancel Session',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _navigateToChat() {
    // Implement chat navigation
  }

  void _joinMeeting(dynamic session) {
    final sessionId = session['_id']?.toString() ?? '';
    if (sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid session details')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpertSessionCallPage(
          sessionId: sessionId,
          token: _userToken ?? '',
        ),
      ),
    );
  }

  Future<void> _fetchAvailabilitySlots() async {
    setState(() {
      _loadingSlots = true;
      _slotsError = '';
    });
    try {
      // Ensure token and userId are loaded
      if (_userToken == null || _userId == null) {
        await _getValidToken();
      }
      if (_userId == null) {
        setState(() {
          _slotsError = 'Expert ID not found.';
          _loadingSlots = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$apiUrl/api/expertauth/availability/$_userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['availability'] != null) {
          final availability = data['data']['availability'] as List;
          final List<Map<String, dynamic>> processedSlots = [];
          for (var slot in availability) {
            final date = slot['date'] as String?;
            if (date == null) continue;
            final times = slot['times'] as Map<String, dynamic>?;
            if (times == null) continue;
            final availableTimes =
                times.entries
                    .where((entry) => entry.value == true)
                    .map((entry) => entry.key)
                    .toList();
            processedSlots.add({
              'date': date,
              'formattedDate': _formatDate(date),
              'times': availableTimes,
            });
          }
          setState(() {
            _availabilitySlots = processedSlots;
            _loadingSlots = false;
          });
        } else {
          setState(() {
            _slotsError = 'No availability data found.';
            _loadingSlots = false;
          });
        }
      } else {
        setState(() {
          _slotsError = 'Failed to load slots: \\${response.statusCode}';
          _loadingSlots = false;
        });
      }
    } catch (e) {
      setState(() {
        _slotsError = 'Error: \\${e.toString()}';
        _loadingSlots = false;
      });
    }
  }

  Future<void> _declineSession(String sessionId) async {
    try {
      final response = await _authenticatedPut('/api/session/decline', {
        'id': sessionId,
      });

      if (response.statusCode == 200) {
        // Update local state to reflect declined status
        final sessionIndex = _mySessions.indexWhere(
          (s) => s['_id'] == sessionId,
        );
        if (sessionIndex != -1) {
          setState(() {
            _mySessions[sessionIndex]['status'] = 'rejected';
          });
        }
        // Also update bookings if needed
        final bookingIndex = _myBookings.indexWhere(
          (b) => b['_id'] == sessionId,
        );
        if (bookingIndex != -1) {
          setState(() {
            _myBookings[bookingIndex]['status'] = 'rejected';
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session declined successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline session: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining session: ${e.toString()}')),
      );
    }
  }
}
