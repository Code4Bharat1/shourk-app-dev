import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class VideoCallPage extends StatefulWidget {
  final String? sessionId;

  const VideoCallPage({super.key, this.sessionId});

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  int _selectedMainTab = 0;
  int _selectedSubTab = 0;
  List<Booking> _bookings = [];
  List<Session> _sessions = [];
  bool _loadingBookings = true;
  bool _loadingSessions = true;
  String? _bookingsError;
  String? _sessionsError;
  String? _authToken;
  final ScrollController _scrollController = ScrollController();
  String? _highlightedSessionId;
  Map<String, SessionState> _sessionStates = {};
  bool _showRateModal = false;
  Booking? _selectedBooking;
  double _rating = 0;
  bool _showCancelModal = false;
  bool _showTermsModal = false;
  dynamic _sessionToCancel;
  Map<int, bool> _cancellationReasons = {
    1: false,
    2: false,
    3: false,
    4: false,
    5: false,
    6: false,
  };
  String _otherReason = '';
  bool _termsAccepted = false;
  bool _loadingCancel = false;
  late TextEditingController _otherReasonController;

  // API endpoints
  static const String BASE_URL = 'https://amd-api.code4bharat.com';
  static const String MY_BOOKINGS_URL = '$BASE_URL/api/session/mybookings';
  static const String EXPERT_SESSIONS_URL = '$BASE_URL/api/session/getexpertsession';
  static const String REFRESH_TOKEN_URL = '$BASE_URL/api/expertauth/refresh-token';
  static const String ACCEPT_EXPERT_SESSION_URL = '$BASE_URL/api/expertsession/accept';
  static const String UPDATE_USER_SESSION_URL = '$BASE_URL/api/usersession';
  static const String DECLINE_SESSION_URL = '$BASE_URL/api/session/decline';
  static const String CANCEL_SESSION_URL = '$BASE_URL/api/cancelsession/cancelexpert';

  @override
  void initState() {
    super.initState();
    _otherReasonController = TextEditingController();
    _highlightedSessionId = widget.sessionId;
    _initializeApp();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadAuthToken();
    _loadData();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('expertToken');
    });
  }

  Future<void> _refreshToken() async {
    if (_authToken == null) return;
    
    try {
      final response = await http.post(
        Uri.parse(REFRESH_TOKEN_URL),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['newToken'];
        if (newToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('expertToken', newToken);
          setState(() {
            _authToken = newToken;
          });
        }
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
  }

  Future<http.Response> _authenticatedRequest(Future<http.Response> Function() request) async {
    if (_authToken == null) {
      await _loadAuthToken();
    }
    
    http.Response response = await request();
    
    if (response.statusCode == 401) {
      await _refreshToken();
      response = await request();
    }
    
    return response;
  }

  Future<void> _loadData() async {
    if (_authToken == null) {
      setState(() {
        _loadingBookings = false;
        _loadingSessions = false;
        _bookingsError = 'Authentication token not found';
        _sessionsError = 'Authentication token not found';
      });
      return;
    }
    
    await Future.wait([
      _fetchBookings(),
      _fetchSessions(),
    ]);

    if (_highlightedSessionId != null) {
      _scrollToHighlightedSession();
    }
  }

  void _scrollToHighlightedSession() {
    final index = _sessions.indexWhere((s) => s.id == _highlightedSessionId);
    if (index != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          index * 200.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _loadingBookings = true;
      _bookingsError = null;
    });

    try {
      final response = await _authenticatedRequest(() async {
        return await http.get(
          Uri.parse(MY_BOOKINGS_URL),
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Content-Type': 'application/json',
          },
        );
      });

      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        final List<Booking> parsedBookings = [];
        
        for (var item in rawData) {
          try {
            parsedBookings.add(Booking.fromJson(item));
          } catch (e) {
            print('Error parsing booking: $e');
          }
        }
        
        setState(() {
          _bookings = parsedBookings;
          _loadingBookings = false;
        });
      } else {
        setState(() {
          _loadingBookings = false;
          _bookingsError = 'Failed to load bookings (Status: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _loadingBookings = false;
        _bookingsError = 'Network error: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _loadingSessions = true;
      _sessionsError = null;
    });

    try {
      final response = await _authenticatedRequest(() async {
        return await http.get(
          Uri.parse(EXPERT_SESSIONS_URL),
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Content-Type': 'application/json',
          },
        );
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> rawData = json.decode(response.body);
        final List<Session> sessions = [];
        
        // Parse expert sessions
        if (rawData.containsKey('expertSessions')) {
          for (var item in rawData['expertSessions']) {
            try {
              sessions.add(Session.fromExpertJson(item));
              _sessionStates[item['_id']] = SessionState();
            } catch (e) {
              print('Error parsing expert session: $e');
            }
          }
        }
        
        // Parse user sessions
        if (rawData.containsKey('userSessions')) {
          for (var item in rawData['userSessions']) {
            try {
              sessions.add(Session.fromUserJson(item));
              _sessionStates[item['_id']] = SessionState();
            } catch (e) {
              print('Error parsing user session: $e');
            }
          }
        }
        
        setState(() {
          _sessions = sessions;
          _loadingSessions = false;
        });
      } else {
        setState(() {
          _loadingSessions = false;
          _sessionsError = 'Failed to load sessions (Status: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _loadingSessions = false;
        _sessionsError = 'Network error: ${e.toString()}';
      });
    }
  }

  Future<void> _acceptSession(Session session) async {
    if (_authToken == null) return;
    
    try {
      final sessionState = _sessionStates[session.id];
      if (sessionState == null || 
          sessionState.selectedDate == null || 
          sessionState.selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time')),
        );
        return;
      }
      
      dynamic response;
      
      if (session.sessionType == "Expert To Expert") {
        response = await _authenticatedRequest(() async {
          return await http.put(
            Uri.parse(ACCEPT_EXPERT_SESSION_URL),
            headers: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'id': session.id,
              'selectedDate': sessionState.selectedDate,
              'selectedTime': sessionState.selectedTime,
            }),
          );
        });
      } else {
        response = await _authenticatedRequest(() async {
          return await http.patch(
            Uri.parse('$UPDATE_USER_SESSION_URL/${session.id}/status'),
            headers: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({'status': 'confirmed'}),
          );
        });
      }
      
      if (response.statusCode == 200) {
        setState(() {
          _sessions = _sessions.map((s) {
            if (s.id == session.id) {
              return s.copyWith(
                status: 'confirmed',
                sessionDate: sessionState.selectedDate!,
                sessionTime: sessionState.selectedTime!,
              );
            }
            return s;
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session accepted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept session: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting session: $e')),
      );
    }
  }

  Future<void> _declineSession(Session session) async {
    if (_authToken == null) return;
    
    try {
      final response = await _authenticatedRequest(() async {
        return await http.put(
          Uri.parse(DECLINE_SESSION_URL),
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({'id': session.id}),
        );
      });
      
      if (response.statusCode == 200) {
        setState(() {
          _sessions = _sessions.map((s) {
            if (s.id == session.id) {
              return s.copyWith(status: 'rejected');
            }
            return s;
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session declined successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline session: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining session: $e')),
      );
    }
  }

  Future<void> _cancelSession(dynamic session) async {
    if (_authToken == null) return;
    
    try {
      final response = await _authenticatedRequest(() async {
        return await http.post(
          Uri.parse(CANCEL_SESSION_URL),
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'sessionId': session.id,
            'sessionModel': session is Booking ? 'Booking' : 'Session',
          }),
        );
      });
      
      if (response.statusCode == 200) {
        setState(() {
          if (session is Booking) {
            _bookings = _bookings.map((b) {
              if (b.id == session.id) {
                return b.copyWith(status: 'cancelled');
              }
              return b;
            }).toList();
          } else {
            _sessions = _sessions.map((s) {
              if (s.id == session.id) {
                return s.copyWith(status: 'cancelled');
              }
              return s;
            }).toList();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session cancelled successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel session: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling session: $e')),
      );
    }
  }

  Future<void> _joinMeeting(String? meetingLink) async {
    if (meetingLink == null || meetingLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting link not available')),
      );
      return;
    }
    
    if (await canLaunch(meetingLink)) {
      await launch(meetingLink);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch meeting')),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatShortDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('E, MMM dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "confirmed":
        return Color(0xFF4CAF50);
      case "completed":
        return Color(0xFF2196F3);
      case "unconfirmed":
        return Color(0xFFFF9800);
      case "rejected":
      case "cancelled":
        return Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 8),
          Text(
            'Error',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(color: Colors.red.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedMainTab = 0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 0 ? Color(0xFF121212) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "My Bookings",
                    style: TextStyle(
                      color: _selectedMainTab == 0 ? Colors.white : Color(0xFF666666),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedMainTab = 1),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 1 ? Color(0xFF121212) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "My Sessions",
                    style: TextStyle(
                      color: _selectedMainTab == 1 ? Colors.white : Color(0xFF666666),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabs() {
    if (_selectedMainTab != 1) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ["All", "User Sessions", "Expert Sessions"]
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(e.value, style: TextStyle(fontSize: 12)),
                    selected: _selectedSubTab == e.key,
                    selectedColor: Color(0xFF121212),
                    labelStyle: TextStyle(
                      color: _selectedSubTab == e.key ? Colors.white : Colors.black,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedSubTab = e.key);
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFEEEEEE)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Consultation",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF121212),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(booking.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Session Type: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF666666),
                      ),
                    ),
                    TextSpan(
                      text: booking.sessionType,
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Duration: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF666666),
                      ),
                    ),
                    TextSpan(
                      text: booking.duration,
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Client: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF121212),
                      ),
                    ),
                    TextSpan(
                      text: booking.clientName,
                      style: TextStyle(color: Color(0xFF121212)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Expert: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF666666),
                      ),
                    ),
                    TextSpan(
                      text: booking.expertName,
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              Text(
                "Scheduled Time:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF121212),
                ),
              ),
              SizedBox(height: 8),
              if (booking.sessionDate.isNotEmpty) ...[
                Text(
                  _formatShortDate(booking.sessionDate),
                  style: TextStyle(
                    color: Color(0xFF121212),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  booking.sessionTime,
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ] else ...[
                Text(
                  "Not scheduled",
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ],
              SizedBox(height: 16),
              
              if (booking.status == "confirmed")
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ready to join",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF121212),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _joinMeeting(booking.meetingLink),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text("Join Meeting"),
                    ),
                  ],
                ),
              
              if (booking.status == "completed")
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showRateModal = true;
                      _selectedBooking = booking;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Rate This Session"),
                ),
              
              if (booking.status == "confirmed" || booking.status == "unconfirmed")
                TextButton(
                  onPressed: () {
                    setState(() {
                      _sessionToCancel = booking;
                      _showCancelModal = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Text("Cancel Booking"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    final isUnconfirmed = session.status == "unconfirmed";
    final isHighlighted = session.id == _highlightedSessionId;
    final sessionState = _sessionStates[session.id] ?? SessionState();
    final availableSlots = _groupSlotsByDate(session.slots);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isHighlighted ? Colors.blue : Color(0xFFEEEEEE), width: isHighlighted ? 2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Session",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF121212),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(session.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      session.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(session.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Session Type: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF666666),
                      ),
                    ),
                    TextSpan(
                      text: session.sessionType,
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Duration: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF666666),
                      ),
                    ),
                    TextSpan(
                      text: session.duration,
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Client: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF121212),
                      ),
                    ),
                    TextSpan(
                      text: session.clientName,
                      style: TextStyle(color: Color(0xFF121212)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Expert: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF666666),
                      ),
                    ),
                    TextSpan(
                      text: session.expertName,
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              Text(
                "Scheduled Time:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF121212),
                ),
              ),
              SizedBox(height: 8),
              if (session.sessionDate.isNotEmpty) ...[
                Text(
                  _formatShortDate(session.sessionDate),
                  style: TextStyle(
                    color: Color(0xFF121212),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  session.sessionTime,
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ] else if (isUnconfirmed) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: sessionState.selectedDate,
                      decoration: InputDecoration(
                        labelText: 'Select Date',
                        border: OutlineInputBorder(),
                      ),
                      items: availableSlots.keys.map((date) {
                        return DropdownMenuItem(
                          value: date,
                          child: Text(_formatShortDate(date)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          sessionState.selectedDate = value;
                          sessionState.selectedTime = null;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    if (sessionState.selectedDate != null)
                      DropdownButtonFormField<String>(
                        value: sessionState.selectedTime,
                        decoration: InputDecoration(
                          labelText: 'Select Time',
                          border: OutlineInputBorder(),
                        ),
                        items: availableSlots[sessionState.selectedDate]?.map((time) {
                          return DropdownMenuItem(
                            value: time,
                            child: Text(time),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            sessionState.selectedTime = value;
                          });
                        },
                      ),
                  ],
                ),
              ] else ...[
                Text(
                  "Not scheduled",
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ],
              SizedBox(height: 16),
              
              if (session.notes.isNotEmpty) ...[
                Text(
                  "Notes:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121212),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  session.notes,
                  style: TextStyle(color: Color(0xFF666666)),
                ),
                SizedBox(height: 16),
              ],
              
              if (isUnconfirmed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Action Required",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF121212),
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _declineSession(session),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF44336),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text("Decline"),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _acceptSession(session),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text("Accept"),
                        ),
                      ],
                    ),
                  ],
                ),
              
              if (session.status == "confirmed")
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ready to join",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF121212),
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implement chat functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text("Chat"),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _joinMeeting(session.meetingLink),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                          ),
                          child: Text("Join Meeting"),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _sessionToCancel = session;
                              _showCancelModal = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text("Cancel"),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<String>> _groupSlotsByDate(List<Slot> slots) {
    final Map<String, List<String>> grouped = {};
    for (var slot in slots) {
      if (slot.selectedDate.isNotEmpty) {
        grouped.putIfAbsent(slot.selectedDate, () => []);
        grouped[slot.selectedDate]!.add(slot.selectedTime);
      }
    }
    return grouped;
  }

  Widget _buildCancellationModal() {
    return AlertDialog(
      title: Text('Cancel Session'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please select your reason(s) for cancellation:'),
            SizedBox(height: 16),
            ..._cancellationReasons.entries.map((entry) {
              return CheckboxListTile(
                title: Text(_getReasonText(entry.key)),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    _cancellationReasons[entry.key] = value!;
                  });
                },
              );
            }).toList(),
            if (_cancellationReasons[6] == true) ...[
              SizedBox(height: 16),
              TextField(
                controller: _otherReasonController,
                decoration: InputDecoration(
                  labelText: 'Please specify your reason',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _otherReason = value,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showCancelModal = false),
          child: Text('Back'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_cancellationReasons.values.any((value) => value)) {
              if (_cancellationReasons[6] == true && _otherReason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please specify your reason')),
                );
                return;
              }
              setState(() {
                _showCancelModal = false;
                _showTermsModal = true;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please select at least one reason')),
              );
            }
          },
          child: Text('Next'),
        ),
      ],
    );
  }

  String _getReasonText(int reasonId) {
    switch (reasonId) {
      case 1: return "Schedule conflict";
      case 2: return "Found alternative solution";
      case 3: return "Expert not suitable for my needs";
      case 4: return "Technical issues";
      case 5: return "Cost concerns";
      case 6: return "Other";
      default: return "";
    }
  }

  Widget _buildTermsModal() {
    return AlertDialog(
      title: Text('Cancellation Terms'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please read the following terms carefully:'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Cancellations made within 24 hours of the scheduled session may be subject to a cancellation fee.'),
                  SizedBox(height: 8),
                  Text('2. If you cancel more than 24 hours before your scheduled session, you will receive a full refund.'),
                  SizedBox(height: 8),
                  Text('3. Expert\'s availability for rescheduling is not guaranteed after cancellation.'),
                  SizedBox(height: 8),
                  Text('4. Multiple cancellations may affect your ability to book future sessions.'),
                  SizedBox(height: 8),
                  Text('5. For emergency cancellations, please contact customer support directly.'),
                  SizedBox(height: 8),
                  Text('6. Refunds will be processed within 5-7 business days to the original payment method.'),
                  SizedBox(height: 8),
                  Text('7. We reserve the right to review each cancellation on a case-by-case basis.'),
                ],
              ),
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text('I have read and agree to the cancellation terms and conditions'),
              value: _termsAccepted,
              onChanged: (value) {
                setState(() {
                  _termsAccepted = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showTermsModal = false),
          child: Text('Back'),
        ),
        ElevatedButton(
          onPressed: _termsAccepted ? () async {
            setState(() => _loadingCancel = true);
            await _cancelSession(_sessionToCancel);
            setState(() {
              _showTermsModal = false;
              _loadingCancel = false;
            });
          } : null,
          child: _loadingCancel 
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Confirm Cancellation'),
        ),
      ],
    );
  }

  Widget _buildRatingModal() {
    return AlertDialog(
      title: Text('Rate This Session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Comments (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _showRateModal = false;
              _rating = 0;
            });
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Implement rating submission
            setState(() {
              _showRateModal = false;
              _rating = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Rating submitted successfully')),
            );
          },
          child: Text('Submit'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ExpertUpperNavbar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'My Video Consultations',
                    style: TextStyle(
                      color: Color(0xFF121212),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'Manage your upcoming and past consultation sessions',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                _buildMainTabs(),
                SizedBox(height: 16),
                _buildSubTabs(),
                SizedBox(height: 24),
                
                if (_authToken == null)
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(height: 8),
                        Text(
                          'Authentication Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        Text(
                          'Please log in to view your consultations',
                          style: TextStyle(color: Colors.orange.shade600),
                        ),
                      ],
                    ),
                  ),
                
                if (_selectedMainTab == 0) ...[
                  if (_loadingBookings)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading bookings...',
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                        ],
                      ),
                    )
                  else if (_bookingsError != null)
                    _buildErrorWidget(_bookingsError!)
                  else if (_bookings.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today, size: 64, color: Color(0xFF666666)),
                          SizedBox(height: 16),
                          Text(
                            "No bookings found",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Your upcoming bookings will appear here",
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._bookings.map((b) => _buildBookingCard(b)).toList(),
                ],
                
                if (_selectedMainTab == 1) ...[
                  if (_loadingSessions)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading sessions...',
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                        ],
                      ),
                    )
                  else if (_sessionsError != null)
                    _buildErrorWidget(_sessionsError!)
                  else if (_sessions.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.video_call, size: 64, color: Color(0xFF666666)),
                          SizedBox(height: 16),
                          Text(
                            "No sessions found",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Your sessions will appear here",
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._sessions
                        .where((s) => _selectedSubTab == 0 ||
                            (_selectedSubTab == 1 && s.sessionType == "User To Expert") ||
                            (_selectedSubTab == 2 && s.sessionType == "Expert To Expert"))
                        .map((s) => _buildSessionCard(s))
                        .toList(),
                ],
              ],
            ),
          ),
          
          // Modal barrier
          if (_showCancelModal || _showTermsModal || _showRateModal)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
              ),
            ),
          
          // Cancellation modal
          if (_showCancelModal)
            Center(
              child: _buildCancellationModal(),
            ),
          
          // Terms modal
          if (_showTermsModal)
            Center(
              child: _buildTermsModal(),
            ),
          
          // Rating modal
          if (_showRateModal)
            Center(
              child: _buildRatingModal(),
            ),
        ],
      ),
      bottomNavigationBar: ExpertBottomNavbar(currentIndex: 1),
    );
  }
}

class SessionState {
  String? selectedDate;
  String? selectedTime;
}

class Booking {
  final String id;
  final String clientName;
  final String expertName;
  String status;
  final String sessionType;
  final String sessionDate;
  final String sessionTime;
  final String duration;
  final String meetingLink;
  final List<Slot> slots;

  Booking({
    required this.id,
    required this.clientName,
    required this.expertName,
    required this.status,
    required this.sessionType,
    required this.sessionDate,
    required this.sessionTime,
    required this.duration,
    required this.meetingLink,
    required this.slots,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final slots = (json['slots'] as List? ?? [])
        .map((slot) => Slot.fromJson(slot))
        .toList();
        
    final firstSlot = slots.isNotEmpty ? slots.first : Slot.empty();
    
    return Booking(
      id: json['_id']?.toString() ?? '',
      clientName: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      expertName: json['consultingExpertID'] != null
          ? '${json['consultingExpertID']['firstName'] ?? ''} ${json['consultingExpertID']['lastName'] ?? ''}'.trim()
          : 'Unknown Expert',
      status: json['status']?.toString()?.toLowerCase() ?? 'unconfirmed',
      sessionType: json['sessionType']?.toString() ?? 'User To Expert',
      sessionDate: firstSlot.selectedDate,
      sessionTime: firstSlot.selectedTime,
      duration: json['duration']?.toString() ?? '30 mins',
      meetingLink: json['zoomMeetingLink']?.toString() ?? '',
      slots: slots,
    );
  }

  Booking copyWith({
    String? status,
    String? sessionDate,
    String? sessionTime,
  }) {
    return Booking(
      id: id,
      clientName: clientName,
      expertName: expertName,
      status: status ?? this.status,
      sessionType: sessionType,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionTime: sessionTime ?? this.sessionTime,
      duration: duration,
      meetingLink: meetingLink,
      slots: slots,
    );
  }
}

class Session {
  final String id;
  final String clientName;
  final String expertName;
  String status;
  final String sessionType;
  final String duration;
  final List<Slot> slots;
  final String notes;
  String meetingLink;
  final String sessionDate;
  final String sessionTime;

  Session({
    required this.id,
    required this.clientName,
    required this.expertName,
    required this.status,
    required this.sessionType,
    required this.duration,
    required this.slots,
    required this.notes,
    required this.sessionDate,
    required this.sessionTime,
    this.meetingLink = "",
  });

  factory Session.fromExpertJson(Map<String, dynamic> json) {
    final slots = (json['slots'] as List? ?? [])
        .map((slot) => Slot.fromJson(slot))
        .toList();
        
    final firstSlot = slots.isNotEmpty ? slots.first : Slot.empty();
    
    return Session(
      id: json['_id']?.toString() ?? '',
      clientName: json['consultingExpertID'] != null
          ? '${json['consultingExpertID']['firstName'] ?? ''} ${json['consultingExpertID']['lastName'] ?? ''}'.trim()
          : 'Unknown Expert',
      expertName: "Me",
      status: json['status']?.toString()?.toLowerCase() ?? 'unconfirmed',
      sessionType: "Expert To Expert",
      duration: json['duration']?.toString() ?? '30 mins',
      slots: slots,
      notes: json['sessionNotes']?.toString() ?? '',
      sessionDate: firstSlot.selectedDate,
      sessionTime: firstSlot.selectedTime,
      meetingLink: json['zoomMeetingLink']?.toString() ?? '',
    );
  }

  factory Session.fromUserJson(Map<String, dynamic> json) {
    final slots = (json['slots'] as List? ?? [])
        .map((slot) => Slot.fromJson(slot))
        .toList();
        
    final firstSlot = slots.isNotEmpty ? slots.first : Slot.empty();
    
    return Session(
      id: json['_id']?.toString() ?? '',
      clientName: '${json['userId']?['firstName'] ?? ''} ${json['userId']?['lastName'] ?? ''}'.trim(),
      expertName: "Me",
      status: json['status']?.toString()?.toLowerCase() ?? 'unconfirmed',
      sessionType: "User To Expert",
      duration: json['duration']?.toString() ?? '30 mins',
      slots: slots,
      notes: json['sessionNotes']?.toString() ?? '',
      sessionDate: firstSlot.selectedDate,
      sessionTime: firstSlot.selectedTime,
      meetingLink: json['zoomMeetingLink']?.toString() ?? '',
    );
  }

  Session copyWith({
    String? status,
    String? sessionDate,
    String? sessionTime,
  }) {
    return Session(
      id: id,
      clientName: clientName,
      expertName: expertName,
      status: status ?? this.status,
      sessionType: sessionType,
      duration: duration,
      slots: slots,
      notes: notes,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionTime: sessionTime ?? this.sessionTime,
      meetingLink: meetingLink,
    );
  }
}

class Slot {
  final String selectedDate;
  final String selectedTime;

  Slot({
    required this.selectedDate,
    required this.selectedTime,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      selectedDate: json['selectedDate']?.toString() ?? '',
      selectedTime: json['selectedTime']?.toString() ?? '',
    );
  }

  factory Slot.empty() {
    return Slot(
      selectedDate: '',
      selectedTime: '',
    );
  }
}