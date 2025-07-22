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
  final String apiUrl = "https://api.shourk.com";
  
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

  @override
  void initState() {
    super.initState();
    _initializeData();
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
            "Token refresh failed with status: ${response.statusCode}\nBody: ${response.body}");
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
        print("⚠️ Profile fetch failed: ${response.statusCode}\n${response.body}");
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
        
        // Validate and handle different response structures
        if (convertedData is List) {
          setState(() => _myBookings = convertedData);
        } 
        else if (convertedData is Map && convertedData.containsKey('data')) {
          final bookingsData = convertedData['data'];
          if (bookingsData is List) {
            setState(() => _myBookings = bookingsData);
          } else {
            throw Exception("Bookings data is not a list");
          }
        }
        else {
          throw Exception("Unexpected bookings response structure");
        }
      } else if (response.statusCode == 402) {
        _handlePaymentError();
      } else {
        setState(() => _errorBookings = "Failed to load bookings: ${response.statusCode}\n${response.body}");
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
        final convertedData = _recursiveConvert(data);
        print("🔍 Raw sessions response: $convertedData");

        // Validate response structure
        if (convertedData is! Map) {
          throw Exception("Sessions response is not a map");
        }

        // Extract sessions with type safety
        final expertSessions = _extractSessions(convertedData, 'expertSessions');
        final userSessions = _extractSessions(convertedData, 'userSessions');

        final combined = [
          ...expertSessions.map((s) => {...s, 'type': 'Expert'}),
          ...userSessions.map((s) => {...s, 'type': 'User'}),
        ];

        setState(() => _mySessions = combined);
      } else if (response.statusCode == 402) {
        _handlePaymentError();
      } else {
        setState(() => _errorSessions = "Failed to load sessions: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      setState(() => _errorSessions = "Sessions error: ${e.toString()}");
      print("🚨 Sessions fetch error: ${e.toString()}");
    } finally {
      setState(() => _loadingSessions = false);
    }
  }

  List<Map<String, dynamic>> _extractSessions(Map<String, dynamic> data, String key) {
    try {
      final sessions = data[key];
      if (sessions is List) {
        return sessions.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      print("⚠️ Error extracting $key sessions: ${e.toString()}");
      return [];
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
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red[400]!;
      default: return Colors.grey;
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

  void _handleDateChange(String sessionId, String date) {
    setState(() {
      _sessionState[sessionId] = {
        ..._sessionState[sessionId] ?? {},
        "selectedDate": date,
        "selectedTime": "",
      };
    });
  }

  void _handleTimeChange(String sessionId, String time) {
    setState(() {
      _sessionState[sessionId] = {
        ..._sessionState[sessionId] ?? {},
        "selectedTime": time,
      };
    });
  }

  void _handleCancelClick(dynamic session) {
    setState(() {
      _sessionToCancel = session;
      _showCancelModal = true;
      _cancellationReasons = _cancellationReasons.map((r) => {...r, "checked": false}).toList();
      _otherReason = "";
      _termsAccepted = false;
    });
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
            child: _activeTab == "bookings" 
              ? _buildBookingsTab()
              : _buildSessionsTab()
          ),
        ],
      ),
      bottomNavigationBar: ExpertBottomNavbar(currentIndex: 1,),
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
            backgroundImage: _profileImageUrl != null 
              ? NetworkImage(_profileImageUrl!) 
              : null,
            child: _profileImageUrl == null
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Text(
                "Video Consultations",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                )
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
    final status = booking['status']?.toString() ?? 'pending';
    final expert = booking['consultingExpertID'] as Map<String, dynamic>? ?? {};
    final expertName = '${expert['firstName'] ?? ''} ${expert['lastName'] ?? ''}';

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
                    "Booking with $expertName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking['sessionType']?.toString() ?? 'Type',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
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
                    name: '${booking['firstName']} ${booking['lastName']}'
                  ),
                  const SizedBox(height: 10),
                  _buildParticipantRow(
                    icon: Icons.work,
                    label: 'Expert',
                    name: expertName
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Slots section
            const Text(
              'Booked Slots',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _buildSlotChips(slots),
            ),
            
            const SizedBox(height: 20),
            
            // Actions
            if (status == 'confirmed') _buildBookingActions(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow({required IconData icon, required String label, required String name}) {
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
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
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

  Widget _buildBookingActions(Map<String, dynamic> booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
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
                onPressed: () => _joinMeeting(booking),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
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
    );
  }

  Widget _buildSessionsTab() {
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
        
        // Content
        Expanded(
          child: _loadingSessions 
            ? const Center(child: CircularProgressIndicator())
            : _errorSessions != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorSessions!,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        if (_errorSessions!.contains("Payment required"))
                          ElevatedButton(
                            onPressed: () {
                              // Add payment navigation here
                            },
                            child: const Text('Resolve Payment'),
                          )
                      ],
                    ),
                  ),
                )
              : _mySessions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No Sessions Scheduled',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your upcoming sessions will appear here',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _mySessions.length,
                    itemBuilder: (context, index) => 
                      _buildSessionCard(_mySessions[index]),
                  ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    return Flexible(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _sessionFilter == filter 
            ? Colors.blue 
            : Colors.grey[300],
          foregroundColor: _sessionFilter == filter 
            ? Colors.white 
            : Colors.grey[700],
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => setState(() => _sessionFilter = filter),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    // Safely extract values with type checking
    final slotsData = session['slots'];
    final List<Map<String, dynamic>> slots = [];
    
    if (slotsData is List && slotsData.isNotEmpty) {
      for (var slot in slotsData) {
        if (slot is Map) {
          slots.add(_recursiveConvert(slot));
        }
      }
    }
    
    final status = session['status']?.toString() ?? 'pending';
    
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Session with $clientName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            
            // Type and duration
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: session['type'] == 'User' 
                      ? Colors.green[50] 
                      : Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session['type'] == 'User' 
                      ? 'User Session' 
                      : 'Expert Session',
                    style: TextStyle(
                      color: session['type'] == 'User' 
                        ? Colors.green[700] 
                        : Colors.purple[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 18, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  '${slots.isNotEmpty ? slots[0]['selectedTime'] : 'TBD'} • ${session['duration'] ?? ''}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Client info
            const Text(
              'Client Information',
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
                    label: 'Name',
                    name: clientName
                  ),
                  const SizedBox(height: 10),
                  _buildParticipantRow(
                    icon: Icons.phone,
                    label: 'Contact',
                    name: session['phone']?.toString() ?? session['mobile']?.toString() ?? 'N/A'
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Session notes
            if (session['note'] != null && session['note'].toString().isNotEmpty) ...[
              const Text(
                'Session Notes',
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
              const SizedBox(height: 16),
            ],
            
            // Slot selection/display
            if (status == 'pending') _buildSlotSelection(session, slots),
            
            // Actions
            _buildSessionActions(session, status),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSelection(Map<String, dynamic> session, List<Map<String, dynamic>> slots) {
    final sessionId = session['_id']?.toString() ?? '';
    final groupedSlots = _groupSlotsByDate(slots);
    final selectedDate = _sessionState[sessionId]?['selectedDate']?.toString();
    final selectedTime = _sessionState[sessionId]?['selectedTime']?.toString();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time Slot',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: groupedSlots.entries.map((entry) {
            return InputChip(
              label: Text(_formatDate(entry.key)),
              selected: selectedDate == entry.key,
              onSelected: (selected) {
                if (selected) _handleDateChange(sessionId, entry.key);
              },
            );
          }).toList(),
        ),
        
        if (selectedDate != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: (groupedSlots[selectedDate] ?? []).map((time) {
              return InputChip(
                label: Text(time),
                selected: selectedTime == time,
                onSelected: (selected) {
                  if (selected) _handleTimeChange(sessionId, time);
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Map<String, List<String>> _groupSlotsByDate(List<Map<String, dynamic>> slots) {
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

  Widget _buildSessionActions(Map<String, dynamic> session, String status) {
    final sessionId = session['_id']?.toString() ?? '';
    final selectedDate = _sessionState[sessionId]?['selectedDate']?.toString();
    final selectedTime = _sessionState[sessionId]?['selectedTime']?.toString();

    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleDecline(sessionId),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text(
                'Decline',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: selectedDate != null && selectedTime != null
                ? () => _handleAccept(sessionId)
                : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blue,
              ),
              child: const Text('Accept'),
            ),
          ),
        ],
      );
    } else if (status == 'confirmed') {
      return Column(
        children: [
          const Divider(),
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
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Future<void> _handleDecline(String sessionId) async {
    // Implement decline logic
  }

  Future<void> _handleAccept(String sessionId) async {
    // Implement accept logic
  }

  void _navigateToChat() {
    // Implement chat navigation
  }

  void _joinMeeting(dynamic session) {
    final meetingId = session['zoomMeetingId']?.toString() ?? '';
    final sessionId = session['_id']?.toString() ?? '';

    if (meetingId.isEmpty || sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid session details'))
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpertSessionCallPage(
          meetingId: meetingId,
          sessionId: sessionId,
        ),
        settings: RouteSettings(
          arguments: _userToken, // Pass token via settings
        ),
      ),
    );
  }
}