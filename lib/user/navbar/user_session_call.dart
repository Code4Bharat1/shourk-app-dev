import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shourk_application/expert/navbar/expert_dashboard.dart';

// Model classes
class Participant {
  final String userId;
  String displayName;
  bool isHost;
  bool video;
  bool audio;

  Participant({
    required this.userId,
    required this.displayName,
    this.isHost = false,
    this.video = false,
    this.audio = false,
  });
}

class SessionData {
  final String sessionId;
  final String expertFirstName;
  final String expertLastName;
  final int duration;

  SessionData({
    required this.sessionId,
    required this.expertFirstName,
    required this.expertLastName,
    required this.duration,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      sessionId: json['sessionId']?.toString() ?? '',
      expertFirstName: json['expertFirstName']?.toString() ?? '',
      expertLastName: json['expertLastName']?.toString() ?? '',
      duration: _parseDuration(json['duration']),
    );
  }

  // Helper method to parse duration from various formats
  static int _parseDuration(dynamic duration) {
    if (duration == null) return 15; // Default to 15 minutes
    
    if (duration is int) {
      return duration;
    }
    
    if (duration is String) {
      // Handle formats like "Quick - 15min", "30min", "1 hour", etc.
      String durationStr = duration.toLowerCase();
      
      // Extract numbers from the string
      RegExp regExp = RegExp(r'(\d+)');
      Match? match = regExp.firstMatch(durationStr);
      
      if (match != null) {
        int value = int.parse(match.group(1)!);
        
        // Check if it's in hours
        if (durationStr.contains('hour') || durationStr.contains('hr')) {
          return value * 60; // Convert hours to minutes
        }
        
        // Default to minutes
        return value;
      }
      
      // Handle specific cases
      if (durationStr.contains('quick')) {
        return 15;
      } else if (durationStr.contains('standard')) {
        return 30;
      } else if (durationStr.contains('extended')) {
        return 60;
      }
    }
    
    // Try to parse as int if it's a number string
    try {
      return int.parse(duration.toString());
    } catch (e) {
      return 15; // Default fallback
    }
  }
}

class AuthData {
  final String sessionName;
  final String token;
  final String userIdentity;
  final int role;
  final String firstName;
  final String lastName;

  AuthData({
    required this.sessionName,
    required this.token,
    required this.userIdentity,
    required this.role,
    required this.firstName,
    required this.lastName,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      sessionName: json['sessionName']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      userIdentity: json['userIdentity']?.toString() ?? '',
      role: _parseRole(json['role']),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
    );
  }

  // Helper method to parse role from various formats
  static int _parseRole(dynamic role) {
    if (role == null) return 0;
    
    if (role is int) {
      return role;
    }
    
    if (role is String) {
      try {
        return int.parse(role);
      } catch (e) {
        // Handle string roles
        String roleStr = role.toLowerCase();
        if (roleStr.contains('admin') || roleStr.contains('expert')) {
          return 1;
        } else if (roleStr.contains('user')) {
          return 0;
        }
      }
    }
    
    return 0; // Default to user role
  }
}

// Service class for API calls
class UserSessionCall {
  static const String baseUrl = "https://amd-api.code4bharat.com";

  static Future<SessionData> getSessionData(String sessionId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/zoomVideo/user-session-details/$sessionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SessionData.fromJson(data['session'] ?? {});
      } else {
        throw Exception('Failed to load session data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<AuthData> generateUserAuth(
      String meetingId, String sessionId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/zoomVideo/generate-user-video-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'meetingId': meetingId,
          'sessionId': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthData.fromJson(data['data'] ?? {});
      } else {
        throw Exception('Failed to generate user auth: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Authentication error: $e');
    }
  }

  static Future<void> notifyUserJoined(String sessionId, String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/zoomVideo/user-joined'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'sessionId': sessionId}),
      );
    } catch (e) {
      print('Failed to notify user joined: $e');
    }
  }

  static Future<void> completeUserSession(
      String sessionId, int duration, String token) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/api/zoomVideo/complete-user-session'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sessionId': sessionId,
          'endTime': DateTime.now().toIso8601String(),
          'status': 'completed',
          'actualDuration': duration,
        }),
      );
    } catch (e) {
      print('Failed to complete user session: $e');
    }
  }
}

// State management provider
class UserSessionProvider with ChangeNotifier {
  // State variables
  bool isLoading = true;
  String? error;
  AuthData? authData;
  SessionData? sessionData;
  bool isInSession = false;
  bool sessionEnded = false;
  bool isSessionActive = false;
  bool isVideoOn = false;
  bool isAudioOn = false;
  bool audioJoined = false;
  bool expertJoined = false;
  bool timerStarted = false;
  bool warningShown = false;
  String connectionStatus = "Connecting...";
  String? mediaError;
  int sessionDuration = 0;
  int timeRemaining = 0;
  DateTime? sessionStartTime;
  List<Participant> participants = [];
  Timer? timer;

  // Initialize from route arguments
  final String meetingId;
  final String sessionId;
  final String userToken;

  UserSessionProvider({
    required this.meetingId,
    required this.sessionId,
    required this.userToken,
  }) {
    initialize();
  }

  Future<void> initialize() async {
    try {
      connectionStatus = "Authenticating as User...";
      notifyListeners();

      sessionData = await UserSessionCall.getSessionData(sessionId, userToken);
      authData = await UserSessionCall.generateUserAuth(meetingId, sessionId, userToken);

      sessionDuration = sessionData?.duration ?? 15;
      timeRemaining = sessionDuration * 60;

      isLoading = false;
      connectionStatus = "Ready to join as User";
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startLocalVideo() async {
    try {
      connectionStatus = "Starting session as User...";
      notifyListeners();

      await joinZoomSession();
      await setupMedia();

      connectionStatus = "Waiting for expert to start...";
      notifyListeners();
    } catch (e) {
      error = "Failed to start session: $e";
      notifyListeners();
    }
  }

  Future<void> joinZoomSession() async {
    connectionStatus = "Joining Zoom session as User...";
    notifyListeners();

    // Simulate joining process
    await Future.delayed(Duration(seconds: 2));

    // Add mock participants for demonstration
    participants.add(Participant(
      userId: "expert_123",
      displayName: "Dr. ${sessionData?.expertFirstName ?? 'Expert'} ${sessionData?.expertLastName ?? ''}",
      isHost: true,
      video: true,
      audio: true,
    ));

    isInSession = true;
    connectionStatus = "Connected to Zoom (User)";
    notifyListeners();

    await notifyUserJoined();
  }

  Future<void> notifyUserJoined() async {
    try {
      await UserSessionCall.notifyUserJoined(sessionId, userToken);
    } catch (e) {
      print('Failed to notify user joined: $e');
    }
  }

  Future<void> setupMedia() async {
    try {
      // Simulate media setup
      await Future.delayed(Duration(seconds: 1));
      
      isAudioOn = true;
      audioJoined = true;
      isVideoOn = true;
      mediaError = null;
      notifyListeners();
    } catch (e) {
      mediaError = "Failed to initialize media: $e";
      notifyListeners();
    }
  }

  void toggleVideo() {
    isVideoOn = !isVideoOn;
    notifyListeners();
  }

  void toggleAudio() {
    if (!audioJoined) {
      // Try to join audio again
      isAudioOn = true;
      audioJoined = true;
      mediaError = null;
      notifyListeners();
      return;
    }
    
    isAudioOn = !isAudioOn;
    notifyListeners();
  }

  void startTimer() {
    if (timerStarted) return;
    
    timerStarted = true;
    isSessionActive = true;
    sessionStartTime = DateTime.now();
    
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeRemaining <= 0) {
        endSessionAutomatically();
        return;
      }
      
      setTimeRemaining(timeRemaining - 1);
      
      // Show warnings
      if (timeRemaining == 120 && !warningShown) {
        warningShown = true;
        // showTimeWarning("2 minutes remaining");
      } else if (timeRemaining == 60) {
        // showTimeWarning("1 minute remaining");
      } else if (timeRemaining == 30) {
        // showTimeWarning("30 seconds remaining");
      }
    });
  }

  void setTimeRemaining(int value) {
    timeRemaining = value;
    notifyListeners();
  }

  Future<void> endSessionAutomatically([String reason = "Session completed"]) async {
    if (sessionEnded) return;
    
    timer?.cancel();
    timer = null;
    
    isSessionActive = false;
    sessionEnded = true;
    connectionStatus = "Consultation completed";
    notifyListeners();
    
    try {
      await UserSessionCall.completeUserSession(
        sessionId,
        sessionDuration,
        userToken,
      );
    } catch (e) {
      print("Failed to update session status: $e");
    }
    
    // Simulate cleanup
    await Future.delayed(Duration(seconds: 2));
    
    // Navigate back in real app
    // context.go('/userpanel/videocall');
  }

  String formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String getExpertDisplayName() {
    return sessionData != null
        ? 'Dr. ${sessionData!.expertFirstName} ${sessionData!.expertLastName}'
        : 'Expert';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

// Main page widget
class UserSessionCallPage extends StatelessWidget {
  final String meetingId;
  final String sessionId;

  const UserSessionCallPage({
    super.key,
    required this.meetingId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final token = ModalRoute.of(context)!.settings.arguments as String? ?? '';
    
    return ChangeNotifierProvider(
      create: (context) => UserSessionProvider(
        meetingId: meetingId,
        sessionId: sessionId,
        userToken: token,
      ),
      child: Scaffold(
        body: _UserSessionBody(),
      ),
    );
  }
}

class _UserSessionBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserSessionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingScreen();
        }
        
        if (provider.error != null) {
          return _buildErrorScreen(context,provider.error!);
        }
        
        if (provider.sessionEnded) {
          return _buildSessionEndedScreen(context);
        }
        
        return _buildMainContent(context);
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
            SizedBox(height: 24),
            Text(
              'Loading session...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context,String error) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
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
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 32,
                  color: Color(0xFFEF4444),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Session Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Retry logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2563EB),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Go Back',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Image.asset(
                'assets/images/Shourk_logo.png',
                width: 120,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionEndedScreen(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
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
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 32,
                  color: Color(0xFF10B981),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Session Completed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Your consultation has ended. Thank you for using our service.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                 Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(),
                      ),
                 );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Return to Dashboard',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 24),
              Image.asset(
                'assets/images/Shourk_logo.png',
                width: 120,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final provider = Provider.of<UserSessionProvider>(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(provider),
          
          // Warning banners
          if (provider.mediaError != null) _buildMediaWarningBanner(provider.mediaError!),
          if (provider.timeRemaining <= 120 && provider.timeRemaining > 0)
            _buildTimeWarningBanner(provider.timeRemaining),
          
          // Main content
          Expanded(
            child: provider.isInSession
                ? _buildVideoGrid(provider)
                : _buildPreJoinScreen(provider),
          ),
          
          // Footer controls
          if (provider.isInSession && !provider.sessionEnded)
            _buildFooterControls(provider),
        ],
      ),
    );
  }

  Widget _buildHeader(UserSessionProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left section
          Row(
            children: [
              // Logo
              Image.asset(
                'assets/images/Shourk_logo.png',
                width: 120,
                height: 40,
              ),
              SizedBox(width: 24),
              // Connection status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: provider.isInSession ? Colors.green : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      provider.connectionStatus,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Right section
          Row(
            children: [
              // Timer
              if (provider.timerStarted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 8),
                      Text(
                        provider.formatTime(provider.timeRemaining),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(width: 16),
              // Meeting info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Meeting ID: ${provider.meetingId}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${provider.participants.length + 1} participant${provider.participants.length > 0 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16),
              // User badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'User',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaWarningBanner(String error) {
    return Container(
      color: Color(0xFFFFFBEB),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                error,
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTimeWarningBanner(int timeRemaining) {
    final isCritical = timeRemaining <= 60;
    return Container(
      color: isCritical ? Color(0xFFFEF2F2) : Color(0xFFFFFBEB),
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCritical ? Color(0xFFEF4444) : Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.timer,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              isCritical ? 'Final Minute! - Session ending soon' : '2 Minutes Remaining - Session ending soon',
              style: TextStyle(
                color: isCritical ? Color(0xFFB91C1C) : Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreJoinScreen(UserSessionProvider provider) {
    return Center(
      child: Container(
        width: 500,
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
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
            // User avatar
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 48,
                color: Color(0xFF3B82F6),
              ),
            ),
            SizedBox(height: 32),
            
            // Title
            Text(
              'Ready to Connect',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            
            // Description
            Text(
              'Join your ${provider.sessionDuration}-minute consultation with the expert',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 32),
            
            // Join button
            ElevatedButton(
              onPressed: provider.startLocalVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Join Consultation',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            
            // Footer
            Image.asset(
              'assets/images/Shourk_logo.png',
              width: 120,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGrid(UserSessionProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // Local video (user)
          _buildLocalVideo(provider),
          
          // Participants
          ...provider.participants.map((p) => _buildParticipantVideo(p)),
          
          // Waiting for expert
          if (provider.participants.isEmpty)
            _buildWaitingForExpert(),
        ],
      ),
    );
  }

  Widget _buildLocalVideo(UserSessionProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Video placeholder
          if (provider.isVideoOn)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Placeholder(), // Replace with actual video
            ),
          
          // Avatar when video is off
          if (!provider.isVideoOn)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFF334155),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'You',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Camera is off',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          
          // Overlay
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'You - User',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12),
                  _buildAudioIndicator(provider.isAudioOn),
                ],
              ),
            ),
          ),
          
          // User badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantVideo(Participant participant) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Video placeholder
          if (participant.video)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Placeholder(), // Replace with actual video
            ),
          
          // Avatar when video is off
          if (!participant.video)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFF334155),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    participant.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Camera is off',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          
          // Overlay
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${participant.displayName} - ${participant.isHost ? 'Expert' : 'User'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12),
                  _buildAudioIndicator(participant.audio),
                ],
              ),
            ),
          ),
          
          // Role badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: participant.isHost ? Color(0xFF7C3AED) : Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                participant.isHost ? 'Expert' : 'User',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioIndicator(bool isOn) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOn ? Colors.green[700] : Colors.red[700],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            isOn ? Icons.mic : Icons.mic_off,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            isOn ? 'Live' : 'Muted',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForExpert() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFCBD5E1),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Waiting for Expert',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'The consultation will begin once the expert connects to the session',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLoadingDot(0),
                _buildLoadingDot(200),
                _buildLoadingDot(400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDot(int delay) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildFooterControls(UserSessionProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio toggle
          _buildControlButton(
            icon: provider.isAudioOn ? Icons.mic : Icons.mic_off,
            label: provider.isAudioOn ? 'Mute' : 'Unmute',
            isActive: provider.isAudioOn,
            onPressed: provider.toggleAudio,
          ),
          SizedBox(width: 32),
          
          // Video toggle
          _buildControlButton(
            icon: Icons.videocam,
            label: provider.isVideoOn ? 'Stop Video' : 'Start Video',
            isActive: provider.isVideoOn,
            onPressed: provider.toggleVideo,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Color(0xFFE5E7EB) : Colors.red,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, size: 24),
            color: isActive ? Color(0xFF4B5563) : Colors.white,
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}