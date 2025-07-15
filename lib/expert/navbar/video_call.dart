import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _highlightedSessionId = widget.sessionId;
    _initializeApp();
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
    
    // Debug: Print token status
    if (_authToken != null) {
      print('Auth token loaded: ${_authToken!.substring(0, 20)}...');
    } else {
      print('No auth token found');
    }
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
      _scrollController.animateTo(
        index * 200.0, // Approximate height of a session card
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _fetchBookings() async {
    if (_authToken == null) return;

    try {
      print('Fetching bookings...');
      final response = await http.get(
        Uri.parse('http://localhost:5070/api/session/mybookings'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      print('Bookings response status: ${response.statusCode}');
      print('Bookings response body: ${response.body}');

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        
        // Handle different response formats
        List<dynamic> bookingsList = [];
        
        if (rawData is List) {
          bookingsList = rawData;
        } else if (rawData is Map) {
          if (rawData.containsKey('bookings') && rawData['bookings'] is List) {
            bookingsList = rawData['bookings'] as List;
          } else if (rawData.containsKey('data') && rawData['data'] is List) {
            bookingsList = rawData['data'] as List;
          } else {
            // If it's a single booking object, wrap it in a list
            bookingsList = [rawData];
          }
        }
        
        List<Booking> parsedBookings = [];
        for (var item in bookingsList) {
          try {
            if (item is Map<String, dynamic>) {
              parsedBookings.add(Booking.fromJson(item));
            }
          } catch (e) {
            print('Error parsing booking item: $e');
            print('Item: $item');
            // Continue with other items
          }
        }
        
        setState(() {
          _bookings = parsedBookings;
          _loadingBookings = false;
          _bookingsError = null;
        });
        print('Loaded ${_bookings.length} bookings');
      } else {
        setState(() {
          _loadingBookings = false;
          _bookingsError = 'Failed to load bookings (Status: ${response.statusCode})';
        });
        print('Failed to load bookings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _loadingBookings = false;
        _bookingsError = 'Network error: ${e.toString()}';
      });
      print('Error fetching bookings: $e');
    }
  }

  Future<void> _fetchSessions() async {
    if (_authToken == null) return;

    try {
      print('Fetching sessions...');
      final response = await http.get(
        Uri.parse('http://localhost:5070/api/session/getexpertsession'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      print('Sessions response status: ${response.statusCode}');
      print('Sessions response body: ${response.body}');

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        
        List<Session> sessions = [];
        
        if (rawData is Map) {
          // Handle expert sessions
          if (rawData.containsKey('expertSessions') && rawData['expertSessions'] is List) {
            final expertSessions = rawData['expertSessions'] as List;
            for (var item in expertSessions) {
              try {
                if (item is Map<String, dynamic>) {
                  sessions.add(Session.fromExpertJson(item));
                }
              } catch (e) {
                print('Error parsing expert session: $e');
                print('Item: $item');
              }
            }
            print('Added ${expertSessions.length} expert sessions');
          }
          
          // Handle user sessions
          if (rawData.containsKey('userSessions') && rawData['userSessions'] is List) {
            final userSessions = rawData['userSessions'] as List;
            for (var item in userSessions) {
              try {
                if (item is Map<String, dynamic>) {
                  sessions.add(Session.fromUserJson(item));
                }
              } catch (e) {
                print('Error parsing user session: $e');
                print('Item: $item');
              }
            }
            print('Added ${userSessions.length} user sessions');
          }
        } else if (rawData is List) {
          // Handle case where sessions are directly in a list
          for (var item in rawData) {
            try {
              if (item is Map<String, dynamic>) {
                sessions.add(Session.fromExpertJson(item));
              }
            } catch (e) {
              print('Error parsing session from list: $e');
              print('Item: $item');
            }
          }
          print('Added ${sessions.length} sessions from direct list');
        }
        
        setState(() {
          _sessions = sessions;
          _loadingSessions = false;
          _sessionsError = null;
        });
        print('Total sessions loaded: ${_sessions.length}');
      } else {
        setState(() {
          _loadingSessions = false;
          _sessionsError = 'Failed to load sessions (Status: ${response.statusCode})';
        });
        print('Failed to load sessions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _loadingSessions = false;
        _sessionsError = 'Network error: ${e.toString()}';
      });
      print('Error fetching sessions: $e');
    }
  }

  // Format date helper
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

  // Get status color
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

  // Error widget
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
            onPressed: () {
              setState(() {
                _loadingBookings = true;
                _loadingSessions = true;
                _bookingsError = null;
                _sessionsError = null;
              });
              _loadData();
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  // UI Components with updated design
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
              // Title row
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
              
              // Session Type
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
              
              // Duration
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
              
              // Client and Expert
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
              
              // Scheduled Time
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
              
              // Buttons
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
                      onPressed: () {
                        // Join meeting functionality
                        print('Join meeting: ${booking.meetingLink}');
                      },
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    final isUnconfirmed = session.status == "unconfirmed";
    final isHighlighted = session.id == _highlightedSessionId;

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
              // Title row
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
              
              // Session Type
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
              
              // Duration
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
              
              // Client and Expert
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
              
              // Scheduled Time
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
              ] else ...[
                Text(
                  "Not scheduled",
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ],
              SizedBox(height: 16),
              
              // Notes
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
              
              // Buttons
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
                          onPressed: () {
                            // Reject functionality
                            print('Reject session: ${session.id}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF44336),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text("Reject"),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Accept functionality
                            print('Accept session: ${session.id}');
                          },
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
            ],
          ),
        ),
      ),
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
                
                // Debug info
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
        ],
      ),
      bottomNavigationBar: ExpertBottomNavbar(currentIndex: 1),
    );
  }
}

// Data Models
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
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id']?.toString() ?? '',
      clientName: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      expertName: json['consultingExpertID'] != null
          ? '${json['consultingExpertID']['firstName'] ?? ''} ${json['consultingExpertID']['lastName'] ?? ''}'.trim()
          : 'Unknown Expert',
      status: json['status']?.toString() ?? 'unconfirmed',
      sessionType: json['sessionType']?.toString() ?? 'User To Expert',
      sessionDate: json['slots'] != null && json['slots'].isNotEmpty
          ? json['slots'][0]['selectedDate']?.toString() ?? ''
          : '',
      sessionTime: json['slots'] != null && json['slots'].isNotEmpty
          ? json['slots'][0]['selectedTime']?.toString() ?? ''
          : '',
      duration: json['duration']?.toString() ?? '30 mins',
      meetingLink: json['userMeetingLink']?.toString() ?? '',
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
    final firstSlot = json['slots'] != null && json['slots'].isNotEmpty
        ? Slot.fromJson(json['slots'][0])
        : Slot(selectedDate: '', selectedTime: '');
    
    return Session(
      id: json['_id']?.toString() ?? '',
      clientName: json['consultingExpertID'] != null
          ? '${json['consultingExpertID']['firstName'] ?? ''} ${json['consultingExpertID']['lastName'] ?? ''}'.trim()
          : 'Unknown Expert',
      expertName: "Me",
      status: json['status']?.toString() ?? 'unconfirmed',
      sessionType: "Expert To Expert",
      duration: json['duration']?.toString() ?? '30 mins',
      slots: json['slots'] != null
          ? (json['slots'] as List).map((s) => Slot.fromJson(s)).toList()
          : [],
      notes: json['sessionNotes']?.toString() ?? '',
      sessionDate: firstSlot.selectedDate,
      sessionTime: firstSlot.selectedTime,
      meetingLink: json['zoomMeetingLink']?.toString() ?? '',
    );
  }

  factory Session.fromUserJson(Map<String, dynamic> json) {
    final firstSlot = json['slots'] != null && json['slots'].isNotEmpty
        ? Slot.fromJson(json['slots'][0])
        : Slot(selectedDate: '', selectedTime: '');
    
    return Session(
      id: json['_id']?.toString() ?? '',
      clientName: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      expertName: "Me",
      status: json['status']?.toString() ?? 'unconfirmed',
      sessionType: "User To Expert",
      duration: json['duration']?.toString() ?? '30 mins',
      slots: json['slots'] != null
          ? (json['slots'] as List).map((s) => Slot.fromJson(s)).toList()
          : [],
      notes: json['sessionNotes']?.toString() ?? '',
      sessionDate: firstSlot.selectedDate,
      sessionTime: firstSlot.selectedTime,
      meetingLink: json['zoomMeetingLink']?.toString() ?? '',
    );
  }
}

class Slot {
  final String selectedDate;
  final String selectedTime;

  Slot({required this.selectedDate, required this.selectedTime});

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      selectedDate: json['selectedDate']?.toString() ?? '',
      selectedTime: json['selectedTime']?.toString() ?? '',
    );
  }
}