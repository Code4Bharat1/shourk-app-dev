import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:shourk_application/shared/config/api_config.dart';

class ExpertSessionCallPage extends StatefulWidget {
  final String sessionId;
  final String token;
  final String? sessionType; // Add session type parameter

  const ExpertSessionCallPage({
    Key? key,
    required this.sessionId,
    required this.token,
    this.sessionType, // Make it optional for backward compatibility
  }) : super(key: key);

  @override
  State<ExpertSessionCallPage> createState() => _ExpertSessionCallPageState();
}

class _ExpertSessionCallPageState extends State<ExpertSessionCallPage> {
  static const platform = MethodChannel('zoom_channel');

  bool _loading = true;
  bool _inMeeting = false;
  String? _errorMsg;
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _zoomAuthData;
  Timer? _timer;
  int _secondsLeft = 0;
  bool _micOn = true;
  bool _camOn = true;
  bool _userJoined = false;
  Timer? _userJoinPollTimer;
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    print('🔍 ExpertSessionCallPage initState called');
    print('🔍 Session ID: ${widget.sessionId}');
    print('🔍 Token: ${widget.token.substring(0, 20)}...');
    _fetchSessionDetails();
    _startUserJoinPolling();
  }

  void _startUserJoinPolling() {
    _userJoinPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_inMeeting || _userJoined) return;
      try {
        // Poll for user join status
        final response = await http.get(
          Uri.parse(ApiConfig.expertSessionDetails(widget.sessionId)),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Check if user has joined based on session status or other indicators
          if (data['session']?['status'] == 'confirmed' || data['session']?['userJoined'] == true) {
            setState(() {
              _userJoined = true;
            });
            _userJoinPollTimer?.cancel();
          }
        }
      } catch (e) {
        print('User join polling error: $e');
      }
    });
  }

  Future<void> _fetchSessionDetails() async {
    print('🔍 _fetchSessionDetails called');
    print('🔍 Session ID being used: ${widget.sessionId}');
    print('🔍 Session type: ${widget.sessionType ?? 'unknown'}');
    print('🔍 Token (first 20 chars): ${widget.token.substring(0, 20)}...');
    
    // Validate session ID format
    if (widget.sessionId.isEmpty) {
      setState(() {
        _errorMsg = 'Invalid session ID. Please create a real session to test the join functionality.';
        _loading = false;
      });
      return;
    }
    
    setState(() => _loading = true);
    
    // Try multiple endpoints in order of priority
    List<String> endpoints = [];
    
    if (widget.sessionType == 'user-to-expert') {
      endpoints = [
        '${ApiConfig.userToExpertSession}/user-session-details/${widget.sessionId}',
        '${ApiConfig.session}/details/${widget.sessionId}',
        ApiConfig.expertSessionDetails(widget.sessionId),
      ];
    } else if (widget.sessionType == 'expert-to-expert') {
      endpoints = [
        ApiConfig.expertSessionDetails(widget.sessionId),
        '${ApiConfig.session}/details/${widget.sessionId}',
        '${ApiConfig.userToExpertSession}/user-session-details/${widget.sessionId}',
      ];
    } else {
      // Try all endpoints if session type is unknown
      endpoints = [
        ApiConfig.expertSessionDetails(widget.sessionId),
        '${ApiConfig.userToExpertSession}/user-session-details/${widget.sessionId}',
        '${ApiConfig.session}/details/${widget.sessionId}',
      ];
    }
    
    print('🔍 Will try ${endpoints.length} endpoints for session ID: ${widget.sessionId}');
    
    for (int i = 0; i < endpoints.length; i++) {
      final url = endpoints[i];
      print('🔍 Trying endpoint $i: $url');
      
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));
        
        print('🔍 Response status: ${response.statusCode}');
        print('🔍 Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('🔍 Parsed session details response: $data');
          
          // Extract session data from response
          Map<String, dynamic>? sessionData;
          if (data['session'] != null) {
            sessionData = data['session'] as Map<String, dynamic>;
          } else if (data['data'] != null && data['data']['session'] != null) {
            sessionData = data['data']['session'] as Map<String, dynamic>;
          } else {
            sessionData = data;
          }
          
          if (sessionData != null && sessionData['_id'] != null) {
            setState(() {
              _sessionData = sessionData;
              _loading = false;
            });
            print('🔍 Successfully loaded session: ${sessionData['_id']}');
            return; // Success, exit the loop
          } else {
            print('🔍 Session data is null or missing _id');
            if (i == endpoints.length - 1) {
              setState(() {
                _errorMsg = 'Session data is invalid or missing. Please try again.';
                _loading = false;
              });
              return;
            }
            continue; // Try next endpoint
          }
        } else if (response.statusCode == 401) {
          setState(() {
            _errorMsg = 'Authentication failed. Please login again.';
            _loading = false;
          });
          return;
        } else if (response.statusCode == 404) {
          print('🔍 404 Error - Session not found for ID: ${widget.sessionId} at endpoint: $url');
          if (i == endpoints.length - 1) {
            // This was the last endpoint, show detailed error
            setState(() {
              _errorMsg = 'Session not found. The session may have been deleted, expired, or the session ID is incorrect. Please create a new session or contact support.';
              _loading = false;
            });
            return;
          }
          continue; // Try next endpoint
        } else {
          print('🔍 Session fetch failed with status: ${response.statusCode}');
          print('🔍 Response body: ${response.body}');
          if (i == endpoints.length - 1) {
            setState(() {
              _errorMsg = 'Failed to fetch session details: ${response.body}';
              _loading = false;
            });
            return;
          }
          continue; // Try next endpoint
        }
      } catch (e) {
        print('🔍 Session fetch error for endpoint $url: $e');
        if (i == endpoints.length - 1) {
          // This was the last endpoint, show error
          if (e.toString().contains('Connection refused') || e.toString().contains('Connection timed out')) {
            setState(() {
              _errorMsg = 'Unable to connect to server. Please check your internet connection and try again.';
              _loading = false;
            });
          } else if (e.toString().contains('TimeoutException')) {
            setState(() {
              _errorMsg = 'Request timed out. Please check your internet connection and try again.';
              _loading = false;
            });
          } else {
            setState(() {
              _errorMsg = 'Failed to connect to server: $e';
              _loading = false;
            });
          }
          return;
        }
        continue; // Try next endpoint
      }
    }
  }

  Future<void> _fetchZoomTokenAndJoin() async {
    print('🔍 _fetchZoomTokenAndJoin called');
    print('🔍 Session data: $_sessionData');
    print('🔍 Session ID: ${widget.sessionId}');
    print('🔍 Session status: ${_sessionData?['status']}');
    print('🔍 Zoom meeting ID: ${_sessionData?['zoomMeetingId']}');
    print('🔍 Zoom session name: ${_sessionData?['zoomSessionName']}');
    print('🔍 Full session data keys: ${_sessionData?.keys.toList()}');
    print('🔍 Session data type: ${_sessionData.runtimeType}');
    
    if (_sessionData == null) {
      setState(() {
        _errorMsg = 'Session data not available. Please try again.';
        _loading = false;
      });
      return;
    }
    
    // Check if session is confirmed
    final sessionStatus = _sessionData?['status'];
    print('🔍 Session status check: $sessionStatus');
    
    if (sessionStatus != 'confirmed') {
      String statusMessage = 'Session is not confirmed yet.';
      if (sessionStatus == 'pending') {
        statusMessage = 'Session is pending confirmation. Please wait for the session to be confirmed before joining.';
      } else if (sessionStatus == 'unconfirmed') {
        statusMessage = 'Session is unconfirmed. Please wait for the session to be confirmed before joining.';
      } else if (sessionStatus == 'rejected') {
        statusMessage = 'Session has been rejected. Please contact the session organizer.';
      } else if (sessionStatus == 'completed') {
        statusMessage = 'Session has already been completed.';
      } else {
        statusMessage = 'Session status is: $sessionStatus. Please wait for the session to be confirmed before joining.';
      }
      
      setState(() {
        _errorMsg = statusMessage;
        _loading = false;
      });
      return;
    }
    
    // Check if session has a meeting ID
    final zoomMeetingId = _sessionData?['zoomMeetingId'];
    print('🔍 Zoom meeting ID check: $zoomMeetingId');
    
    if (zoomMeetingId == null || zoomMeetingId.toString().isEmpty) {
      setState(() {
        _errorMsg = 'Session does not have a meeting ID assigned. This usually means the session needs to be confirmed first. Please contact the session organizer.';
        _loading = false;
      });
      return;
    }
    
    setState(() => _loading = true);
    
    try {
      print('🔍 Fetching Zoom token for session: ${widget.sessionId}');
      print('🔍 Using API URL: ${ApiConfig.expertGenerateVideoAuth()}');
      
      // Get the meeting number from session data
      final meetingNumber = _sessionData?['zoomMeetingId']?.toString();
      if (meetingNumber == null || meetingNumber.isEmpty) {
        setState(() {
          _errorMsg = 'Session does not have a meeting ID assigned. This usually means the session needs to be confirmed first. Please contact the session organizer.';
          _loading = false;
        });
        return;
      }
      
      final requestBody = {
        'meetingNumber': meetingNumber,
        'role': 1, // Expert role
      };
      
      print('🔍 Request body being sent: $requestBody');
      print('🔍 Using meeting number: $meetingNumber');
      
      final response = await http.post(
        Uri.parse(ApiConfig.expertGenerateVideoAuth()),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30)); // Increased timeout
      
      print('🔍 Zoom token response status: ${response.statusCode}');
      print('🔍 Zoom token response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 Parsed Zoom token response: $data');
        
        // Validate the response data
        final token = data['signature'] ?? data['token'];
        if (token == null) {
          throw Exception('No token received from server');
        }
        
        setState(() {
          _zoomAuthData = {
            'token': token,
            'sessionName': _sessionData?['videoSDKTopic'] ?? _sessionData?['zoomSessionName'] ?? 'Expert Session',
            'firstName': _sessionData?['firstName'] ?? 'Expert',
            'lastName': _sessionData?['lastName'] ?? 'User',
            'userIdentity': 'expert-${widget.sessionId}',
            'role': 1,
          };
          _loading = false;
        });
        
        print('🔍 Zoom auth data set: $_zoomAuthData');
        await _joinZoomSessionNative();
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMsg = 'Authentication failed. Please login again.';
          _loading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMsg = 'Session not found. Please check the session ID.';
          _loading = false;
        });
      } else {
        print('🔍 Zoom token fetch failed with status: ${response.statusCode}');
        print('🔍 Response body: ${response.body}');
        setState(() {
          _errorMsg = 'Failed to get Zoom token: ${response.body}';
          _loading = false;
        });
      }
    } catch (e) {
      print('🔍 Zoom token fetch error: $e');
      String errorMessage = 'Failed to get Zoom token';
      
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please check your internet connection and try again.';
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Connection timed out')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection and try again.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else {
        errorMessage = 'Failed to get Zoom token: $e';
      }
      
      setState(() {
        _errorMsg = errorMessage;
        _loading = false;
      });
    }
  }

  Future<void> _joinZoomSessionNative() async {
    print('🔍 _joinZoomSessionNative called');
    print('🔍 Zoom auth data: $_zoomAuthData');
    
    if (_zoomAuthData == null) {
      print('🔍 Error: Zoom auth data is null');
      setState(() {
        _errorMsg = 'Failed to prepare session data. Please try again.';
        _loading = false;
      });
      return;
    }
    
    try {
      print('🔍 Invoking native method with data: ${_zoomAuthData}');
      
      final result = await platform.invokeMethod('joinZoomSession', {
        'token': _zoomAuthData!['token'],
        'sessionName': _zoomAuthData!['sessionName'],
        'userName': (_zoomAuthData!['firstName'] ?? '') + ' ' + (_zoomAuthData!['lastName'] ?? ''),
        'userIdentity': _zoomAuthData!['userIdentity'],
        'role': _zoomAuthData!['role'],
      });
      
      print('🔍 Native method result: $result');
      
      setState(() {
        _inMeeting = true;
        _sessionStartTime = DateTime.now();
      });
      _startTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined session'),
          backgroundColor: Colors.green,
        ),
      );
    } on PlatformException catch (e) {
      print('🔍 Platform exception: ${e.code} - ${e.message}');
      String errorMessage = 'Failed to join Zoom session';
      
      switch (e.code) {
        case 'INVALID_ARGUMENTS':
          errorMessage = 'Invalid session parameters. Please try again.';
          break;
        case 'INIT_FAILED':
          errorMessage = 'Failed to initialize video session. Please try again.';
          break;
        case 'JOIN_FAILED':
          errorMessage = 'Failed to join session. Please check your internet connection and try again.';
          break;
                  case 'SDK_NOT_AVAILABLE':
            errorMessage = 'Zoom Video SDK is not properly integrated. Please contact support.';
            break;
        default:
          errorMessage = 'Failed to join Zoom session: ${e.message}';
      }
      
      setState(() {
        _errorMsg = errorMessage;
        _loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('🔍 Unexpected error: $e');
      setState(() {
        _errorMsg = 'An unexpected error occurred: $e';
        _loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveZoomSessionNative() async {
    try {
      await platform.invokeMethod('leaveZoomSession');
      setState(() {
        _inMeeting = false;
      });
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave Zoom session: ${e.message}')),
      );
    }
  }

  void _startTimer() {
    int durationMinutes = 15;
    if (_sessionData?['duration'] != null) {
      final d = _sessionData!['duration'].toString();
      final match = RegExp(r'(\d+)').firstMatch(d);
      if (match != null) durationMinutes = int.parse(match.group(1)!);
    }
    _secondsLeft = durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        setState(() => _inMeeting = false);
        _leaveZoomSessionNative();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _userJoinPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    try {
      await platform.invokeMethod('toggleMic', {'on': !_micOn});
      setState(() => _micOn = !_micOn);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle mic: $e')),
      );
    }
  }

  Future<void> _toggleCam() async {
    try {
      // First check if camera is available
      final cameraAvailable = await platform.invokeMethod('checkCameraAvailable');
      if (cameraAvailable != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera not available. Please check camera permissions.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      await platform.invokeMethod('toggleCam', {'on': !_camOn});
      setState(() => _camOn = !_camOn);
    } catch (e) {
      if (e.toString().contains('PERMISSION_DENIED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission required. Please grant camera access in settings.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('NO_CAMERA')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No camera available on this device.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle camera: $e')),
        );
      }
    }
  }

  Widget _buildParticipantCard({
    required String name,
    required bool isExpert,
    required bool cameraOn,
    required bool micOn,
    bool waiting = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    // Calculate card dimensions based on screen size and orientation
    double cardWidth, cardHeight;
    if (isLandscape) {
      cardWidth = screenWidth * 0.45;
      cardHeight = screenHeight * 0.7;
    } else {
      cardWidth = screenWidth * 0.85;
      cardHeight = screenHeight * 0.35;
    }

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF475569) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: waiting
          ? _buildWaitingCard(name, cardWidth, cardHeight)
          : _buildActiveParticipantCard(name, isExpert, cameraOn, micOn, cardWidth, cardHeight),
    );
  }

  Widget _buildWaitingCard(String name, double width, double height) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.person,
          size: width * 0.2,
          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'Waiting for user to join...',
          style: TextStyle(
            fontSize: width * 0.04,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'The consultation will begin once the user connects to the session',
          style: TextStyle(
            fontSize: width * 0.03,
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkMode ? Color(0xFF60A5FA) : Colors.blue,
          ),
        ),
      ],
    );
  }

    Widget _buildActiveParticipantCard(String name, bool isExpert, bool cameraOn, bool micOn, double width, double height) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Video placeholder or camera feed
        Container(
          width: width * 0.6,
          height: height * 0.5,
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF64748B) : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: cameraOn
              ? Icon(
                  Icons.videocam,
                  size: width * 0.15,
                  color: isDarkMode ? Color(0xFF60A5FA) : Colors.blue,
                )
              : Icon(
                      Icons.person,
                  size: width * 0.15,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
        const SizedBox(height: 12),
                  Text(
          name,
                    style: TextStyle(
            fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
        const SizedBox(height: 4),
                  Text(
          cameraOn ? 'Camera is on' : 'Camera is off',
                    style: TextStyle(
            fontSize: width * 0.03,
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
                children: [
            Icon(
              micOn ? Icons.mic : Icons.mic_off,
              color: micOn ? Colors.green : Colors.red,
              size: width * 0.04,
            ),
            const SizedBox(width: 4),
                  Text(
              micOn ? 'Mic on' : 'Mic muted',
                    style: TextStyle(
                color: micOn ? Colors.green : Colors.red,
                fontSize: width * 0.03,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
            color: isExpert ? (isDarkMode ? Color(0xFF7C3AED) : Colors.purple[700]!) : (isDarkMode ? Color(0xFF60A5FA) : Colors.blue[700]!),
            borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
            isExpert ? 'Expert (Host)' : 'User',
            style: const TextStyle(
                  color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildSessionIntro() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Center(
      child: Container(
        width: screenWidth * 0.85,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: screenHeight * 0.6,
        ),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF334155) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_call,
              size: screenWidth * 0.15,
              color: isDarkMode ? Color(0xFF60A5FA) : Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to Start Expert Session',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Begin your ${_sessionData?['duration'] ?? '15'}-minute consultation session',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _fetchZoomTokenAndJoin,
                icon: Icon(Icons.play_arrow, color: Colors.white),
                label: Text(
                  'Start Expert Session',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Color(0xFF60A5FA) : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionUI() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Container(
      color: isDarkMode ? Color(0xFF1E293B) : Colors.grey[200],
      child: Column(
        children: [
          Expanded(
            child: isLandscape
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildParticipantCard(
                        name: 'You (Expert)',
                        isExpert: true,
                        cameraOn: _camOn,
                        micOn: _micOn,
                      ),
                      _buildParticipantCard(
                        name: _userJoined ? 'User (Client)' : '',
                        isExpert: false,
                        cameraOn: false,
                        micOn: false,
                        waiting: !_userJoined,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildParticipantCard(
                        name: 'You (Expert)',
                        isExpert: true,
                        cameraOn: _camOn,
                        micOn: _micOn,
                      ),
                      _buildParticipantCard(
                        name: _userJoined ? 'User (Client)' : '',
                        isExpert: false,
                        cameraOn: false,
                        micOn: false,
                        waiting: !_userJoined,
                      ),
                    ],
                  ),
          ),
          _buildControlBar(screenWidth),
        ],
      ),
    );
  }

  Widget _buildControlBar(double screenWidth) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: isDarkMode ? Color(0xFF334155) : Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left controls
            Row(
              children: [
                _buildControlButton(
                  icon: _micOn ? Icons.mic : Icons.mic_off,
                  color: _micOn ? Colors.green : Colors.red,
                  onPressed: _toggleMic,
                  screenWidth: screenWidth,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: _camOn ? Icons.videocam : Icons.videocam_off,
                  color: _camOn ? Colors.green : Colors.red,
                  onPressed: _toggleCam,
                  screenWidth: screenWidth,
                ),
              ],
            ),
            // Center timer
            Text(
              'Time left: ${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.04,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            // Right end session button
            _buildEndSessionButton(screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double screenWidth,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        iconSize: screenWidth * 0.06,
      ),
    );
  }

  Widget _buildEndSessionButton(double screenWidth) { 
    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.3,
        minWidth: 100,
      ),
      child: ElevatedButton.icon(
        onPressed: _leaveZoomSessionNative,
        icon: const Icon(Icons.call_end, color: Colors.white, size: 20),
        label: const Text(
          'End Session',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 BUILD METHOD - Loading: $_loading, Error: $_errorMsg, InMeeting: $_inMeeting');
    
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF1E293B) : Colors.grey[200],
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode ? Color(0xFF60A5FA) : Colors.blue,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading session...',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            )
          : _errorMsg != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 500),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Color(0xFF334155) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Color(0xFF2B1112) : Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 32,
                              color: isDarkMode ? Color(0xFFFCA5A5) : Color(0xFFEF4444),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Session Error',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _errorMsg!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _errorMsg = null;
                                      _loading = true;
                                    });
                                    _fetchSessionDetails();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? Color(0xFF60A5FA) : Colors.blue,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _errorMsg = null;
                                      _loading = true;
                                    });
                                    _fetchZoomTokenAndJoin();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Retry Join',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMsg!.contains('Session not found'))
                            Column(
                              children: [
                                SizedBox(height: 24),
                                Text(
                                  'Troubleshooting:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• The session ID may not exist in the database\n'
                                  '• Try creating a new session through the booking process\n'
                                  '• Check if the session was deleted or expired',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: isDarkMode ? Colors.white60 : Colors.grey,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Go Back to Sessions'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              : !_inMeeting
                  ? _buildSessionIntro()
                  : _buildSessionUI(),
    );
  }
}