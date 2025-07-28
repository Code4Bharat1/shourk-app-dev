import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shourk_application/expert/navbar/expert_dashboard.dart';
import 'package:permission_handler/permission_handler.dart';

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

  static int _parseDuration(dynamic duration) {
    if (duration == null) return 15;
    
    if (duration is int) return duration;
    
    if (duration is String) {
      String durationStr = duration.toLowerCase();
      RegExp regExp = RegExp(r'(\d+)');
      Match? match = regExp.firstMatch(durationStr);
      
      if (match != null) {
        int value = int.parse(match.group(1)!);
        if (durationStr.contains('hour') || durationStr.contains('hr')) {
          return value * 60;
        }
        return value;
      }
      
      if (durationStr.contains('quick')) return 15;
      else if (durationStr.contains('standard')) return 30;
      else if (durationStr.contains('extended')) return 60;
    }
    
    try {
      return int.parse(duration.toString());
    } catch (e) {
      return 15;
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

  static int _parseRole(dynamic role) {
    if (role == null) return 0;
    
    if (role is int) return role;
    
    if (role is String) {
      try {
        return int.parse(role);
      } catch (e) {
        String roleStr = role.toLowerCase();
        if (roleStr.contains('admin') || roleStr.contains('expert')) return 1;
        else if (roleStr.contains('user')) return 0;
      }
    }
    
    return 0;
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
  static const platform = MethodChannel('zoom_channel');
  
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
  Timer? _expertJoinPollTimer;

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
      _startExpertJoinPolling();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  void _startExpertJoinPolling() {
    // Poll every 3 seconds to check if expert has joined
    _expertJoinPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!isInSession || expertJoined) return;
      try {
        final response = await http.get(
          Uri.parse('${UserSessionCall.baseUrl}/api/zoomVideo/expert-joined/$sessionId'),
          headers: {
            'Authorization': 'Bearer $userToken',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['expertJoined'] == true) {
            expertJoined = true;
            notifyListeners();
            _expertJoinPollTimer?.cancel();
          }
        }
      } catch (e) {
        // Optionally log polling error
      }
    });
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

    // Web fallback for testing
    if (kIsWeb) {
      await Future.delayed(Duration(seconds: 2));
      isInSession = true;
      connectionStatus = "Connected to Zoom (User) - Web Demo";
      notifyListeners();
      await notifyUserJoined();
      return;
    }

    try {
      if (authData == null) {
        throw Exception('Auth data not available');
      }

      await platform.invokeMethod('joinZoomSession', {
        'token': authData!.token,
        'sessionName': authData!.sessionName,
        'userName': '${authData!.firstName} ${authData!.lastName}',
        'userIdentity': authData!.userIdentity,
        'role': authData!.role,
      });

      isInSession = true;
      connectionStatus = "Connected to Zoom (User)";
      notifyListeners();

      await notifyUserJoined();
    } on PlatformException catch (e) {
      error = "Failed to join Zoom session: ${e.message}";
      notifyListeners();
    } catch (e) {
      error = "Failed to join session: $e";
      notifyListeners();
    }
  }

  Future<void> notifyUserJoined() async {
    try {
      await UserSessionCall.notifyUserJoined(sessionId, userToken);
    } catch (e) {
      print('Failed to notify user joined: $e');
    }
  }

  // Updated setupMedia method
Future<void> setupMedia() async {
  try {
    // Request camera and microphone permissions together
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraGranted || !micGranted) {
      mediaError = "Permissions denied for ${!cameraGranted ? 'camera' : ''}${!cameraGranted && !micGranted ? ' and ' : ''}${!micGranted ? 'microphone' : ''}";
      notifyListeners();
      return;
    }

    // Initialize media devices
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

// Updated toggleVideo method
void toggleVideo() async {
  try {
    if (!isVideoOn) {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        mediaError = "Camera permission denied";
        notifyListeners();
        return;
      }
    }
    
    // Call native method to toggle camera in Zoom session
    if (kIsWeb) {
      // Web fallback
      isVideoOn = !isVideoOn;
      notifyListeners();
      return;
    }
    
    try {
      await platform.invokeMethod('toggleCam', {'on': !isVideoOn});
      isVideoOn = !isVideoOn;
      notifyListeners();
    } on PlatformException catch (e) {
      if (e.message?.contains('PERMISSION_DENIED') == true) {
        mediaError = "Camera permission required. Please grant camera access in settings.";
      } else {
        mediaError = "Failed to toggle camera: ${e.message}";
      }
      notifyListeners();
    }
  } catch (e) {
    mediaError = "Failed to toggle video: $e";
    notifyListeners();
  }
}

// Updated toggleAudio method
void toggleAudio() async {
  try {
    if (!isAudioOn || !audioJoined) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        mediaError = "Microphone permission denied";
        notifyListeners();
        return;
      }
    }
    
    // Call native method to toggle mic in Zoom session
    if (kIsWeb) {
      // Web fallback
      isAudioOn = !isAudioOn;
      audioJoined = true;
      mediaError = null;
      notifyListeners();
      return;
    }
    
    try {
      await platform.invokeMethod('toggleMic', {'on': !isAudioOn});
      isAudioOn = !isAudioOn;
      audioJoined = true;
      mediaError = null;
      notifyListeners();
    } on PlatformException catch (e) {
      mediaError = "Failed to toggle microphone: ${e.message}";
      notifyListeners();
    }
  } catch (e) {
    mediaError = "Failed to toggle audio: $e";
    notifyListeners();
  }
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
      
      if (timeRemaining == 120 && !warningShown) {
        warningShown = true;
      } else if (timeRemaining == 60) {
      } else if (timeRemaining == 30) {
      }
    });
  }

  void setTimeRemaining(int value) {
    timeRemaining = value;
    notifyListeners();
  }

  Future<void> leaveZoomSession() async {
    if (!isInSession) return;
    
    // Web fallback for testing
    if (kIsWeb) {
      isInSession = false;
      notifyListeners();
      return;
    }
    
    try {
      await platform.invokeMethod('leaveZoomSession');
      isInSession = false;
      notifyListeners();
    } on PlatformException catch (e) {
      print("Failed to leave Zoom session: ${e.message}");
    } catch (e) {
      print("Failed to leave session: $e");
    }
  }

  Future<void> endSessionAutomatically([String reason = "Session completed"]) async {
    if (sessionEnded) return;
    
    timer?.cancel();
    timer = null;
    _expertJoinPollTimer?.cancel();
    
    isSessionActive = false;
    sessionEnded = true;
    connectionStatus = "Consultation completed";
    notifyListeners();
    
    // Leave Zoom session
    await leaveZoomSession();
    
    try {
      await UserSessionCall.completeUserSession(
        sessionId,
        sessionDuration,
        userToken,
      );
    } catch (e) {
      print("Failed to update session status: $e");
    }
    
    await Future.delayed(Duration(seconds: 2));
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
    leaveZoomSession();
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
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return ChangeNotifierProvider(
      create: (context) => UserSessionProvider(
        meetingId: meetingId,
        sessionId: sessionId,
        userToken: token,
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [Color(0xFF1E293B), Color(0xFF0F172A)]
                      : [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                ),
              ),
              child: Theme(
                data: ThemeData(
                  brightness: isDarkMode ? Brightness.dark : Brightness.light,
                  colorScheme: ColorScheme(
                    brightness: isDarkMode ? Brightness.dark : Brightness.light,
                    primary: isDarkMode ? Color(0xFF60A5FA) : Color(0xFF2563EB),
                    onPrimary: Colors.white,
                    secondary: Color(0xFF7C3AED),
                    onSecondary: Colors.white,
                    error: Colors.red,
                    onError: Colors.white,
                    background: isDarkMode ? Color(0xFF1E293B) : Color(0xFFF8FAFC),
                    onBackground: isDarkMode ? Colors.white : Color(0xFF334155),
                    surface: isDarkMode ? Color(0xFF1E293B) : Colors.white,
                    onSurface: isDarkMode ? Colors.white : Color(0xFF334155),
                  ),
                ),
                child: _UserSessionBody(),
              ),
            ),
          );
        }
      ),
    );
  }
}

class _UserSessionBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Consumer<UserSessionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingScreen(theme, isDarkMode);
        }
        
        if (provider.error != null) {
          return _buildErrorScreen(context, provider.error!, theme, isDarkMode);
        }
        
        if (provider.sessionEnded) {
          return _buildSessionEndedScreen(context, theme, isDarkMode);
        }
        
        return _buildMainContent(context, theme, isDarkMode);
      },
    );
  }

  Widget _buildLoadingScreen(ThemeData theme, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            SizedBox(height: 24),
            Text(
              'Loading session...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error, ThemeData theme, bool isDarkMode) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                          backgroundColor: theme.colorScheme.primary,
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
      ),
    );
  }

  Widget _buildSessionEndedScreen(BuildContext context, ThemeData theme, bool isDarkMode) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
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
                    color: isDarkMode ? Color(0xFF052E16) : Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 32,
                    color: isDarkMode ? Color(0xFF86EFAC) : Color(0xFF10B981),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Session Completed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Your consultation has ended. Thank you for using our service.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                    backgroundColor: theme.colorScheme.primary,
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
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ThemeData theme, bool isDarkMode) {
    final provider = Provider.of<UserSessionProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Container(
      color: Colors.grey[200],
      child: Column(
        children: [
          // Header
          _buildHeader(provider, theme, isDarkMode, screenSize),
          
          // Warning banners
          if (provider.mediaError != null) 
            _buildMediaWarningBanner(provider.mediaError!, theme, isDarkMode),
          
          if (provider.timeRemaining <= 120 && provider.timeRemaining > 0)
            _buildTimeWarningBanner(provider.timeRemaining, theme, isDarkMode),
          
          // Main content
          Expanded(
            child: provider.isInSession
                ? _buildVideoGrid(provider, theme, isDarkMode, screenSize, isLandscape)
                : _buildPreJoinScreen(provider, theme, isDarkMode, screenSize),
          ),
          
          // Footer controls
          if (provider.isInSession && !provider.sessionEnded)
            _buildFooterControls(provider, theme, isDarkMode, context),
        ],
      ),
    );
  }

Widget _buildHeader(UserSessionProvider provider, ThemeData theme, bool isDarkMode, Size screenSize) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
      border: Border(
        bottom: BorderSide(color: theme.dividerColor),
      ),
    ),
    child: screenSize.width > 600
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center, // Add this
            children: [
              Flexible( // Wrap with Flexible
                child: _buildHeaderLeftSection(provider, theme),
              ),
              SizedBox(width: 12), // Add spacing
              _buildHeaderRightSection(provider, theme),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // Change to start
                children: [
                  Flexible( // Wrap with Flexible
                    child: _buildHeaderLeftSection(provider, theme),
                  ),
                  _buildHeaderRightSection(provider, theme),
                ],
              ),
              SizedBox(height: 8),
              _buildMeetingInfo(provider, theme),
            ],
          ),
  );
}

  Widget _buildHeaderLeftSection(UserSessionProvider provider, ThemeData theme) {
  return Row(
    children: [
      Image.asset(
        'assets/images/Shourk_logo.png',
        width: 100,
        height: 40,
      ),
      SizedBox(width: 12),
      Flexible( // Add Flexible here
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Add this
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
              Flexible( // Add Flexible here
                child: Text(
                  provider.connectionStatus,
                  overflow: TextOverflow.ellipsis, // Add overflow handling
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildHeaderRightSection(UserSessionProvider provider, ThemeData theme) {
    return Row(
      children: [
        if (provider.timerStarted)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                SizedBox(width: 6),
                Text(
                  provider.formatTime(provider.timeRemaining),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(width: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'User',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingInfo(UserSessionProvider provider, ThemeData theme) {
    return Row(
      children: [
        Text(
          'Meeting ID: ${provider.meetingId}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 12),
        Text(
          '${provider.participants.length + 1} participant${provider.participants.length > 0 ? 's' : ''}',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaWarningBanner(String error, ThemeData theme, bool isDarkMode) {
    return Container(
      color: isDarkMode ? Color(0xFF422006) : Color(0xFFFFFBEB),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFFFCD34D) : Color(0xFFF59E0B),
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
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error,
                    style: TextStyle(
                      color: isDarkMode ? Color(0xFFFCD34D) : Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTimeWarningBanner(int timeRemaining, ThemeData theme, bool isDarkMode) {
    final isCritical = timeRemaining <= 60;
    return Container(
      color: isCritical 
          ? (isDarkMode ? Color(0xFF2B1112) : Color(0xFFFEF2F2))
          : (isDarkMode ? Color(0xFF422006) : Color(0xFFFFFBEB)),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCritical 
                    ? (isDarkMode ? Color(0xFFFCA5A5) : Color(0xFFEF4444))
                    : (isDarkMode ? Color(0xFFFCD34D) : Color(0xFFF59E0B)),
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
                color: isCritical 
                    ? (isDarkMode ? Color(0xFFFCA5A5) : Color(0xFFB91C1C))
                    : (isDarkMode ? Color(0xFFFCD34D) : Color(0xFF92400E)),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreJoinScreen(UserSessionProvider provider, ThemeData theme, bool isDarkMode, Size screenSize) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: screenSize.width * 0.9,
          constraints: BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Ready to Connect',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Join your ${provider.sessionDuration}-minute consultation with the expert',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: provider.startLocalVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Join Consultation',
                      style: TextStyle(fontSize: 16,
                      color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Image.asset(
                'assets/images/Shourk_logo.png',
                width: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGrid(UserSessionProvider provider, ThemeData theme, bool isDarkMode, Size screenSize, bool isLandscape) {
    return Container(
      color: Colors.grey[200],
      child: isLandscape
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildParticipantCard(
                  name: 'You (User)',
                  isExpert: false,
                  cameraOn: provider.isVideoOn,
                  micOn: provider.isAudioOn,
                  screenSize: screenSize,
                ),
                _buildParticipantCard(
                  name: provider.getExpertDisplayName(),
                  isExpert: true,
                  cameraOn: provider.expertJoined,
                  micOn: provider.expertJoined,
                  screenSize: screenSize,
                  waiting: !provider.expertJoined,
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildParticipantCard(
                  name: 'You (User)',
                  isExpert: false,
                  cameraOn: provider.isVideoOn,
                  micOn: provider.isAudioOn,
                  screenSize: screenSize,
                ),
                _buildParticipantCard(
                  name: provider.getExpertDisplayName(),
                  isExpert: true,
                  cameraOn: provider.expertJoined,
                  micOn: provider.expertJoined,
                  screenSize: screenSize,
                  waiting: !provider.expertJoined,
                ),
              ],
            ),
    );
  }

  Widget _buildParticipantCard({
    required String name,
    required bool isExpert,
    required bool cameraOn,
    required bool micOn,
    required Size screenSize,
    bool waiting = false,
  }) {
    final isLandscape = screenSize.width > screenSize.height;
    
    // Calculate card dimensions based on screen size and orientation
    double cardWidth, cardHeight;
    if (isLandscape) {
      cardWidth = screenSize.width * 0.45;
      cardHeight = screenSize.height * 0.7;
    } else {
      cardWidth = screenSize.width * 0.85;
      cardHeight = screenSize.height * 0.35;
    }

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.person,
          size: width * 0.2,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'Waiting for expert to join...',
          style: TextStyle(
            fontSize: width * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'The consultation will begin once the expert connects to the session',
          style: TextStyle(
            fontSize: width * 0.03,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }

  Widget _buildActiveParticipantCard(String name, bool isExpert, bool cameraOn, bool micOn, double width, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Video placeholder or camera feed
        Container(
          width: width * 0.6,
          height: height * 0.5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: cameraOn
              ? Icon(
                  Icons.videocam,
                  size: width * 0.15,
                  color: Colors.blue,
                )
              : Icon(
                  Icons.person,
                  size: width * 0.15,
                  color: Colors.grey[600],
                ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(
            fontSize: width * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cameraOn ? 'Camera is on' : 'Camera is off',
          style: TextStyle(
            fontSize: width * 0.03,
            color: Colors.grey[600],
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
            color: isExpert ? Colors.purple[700] : Colors.blue[700],
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

  Widget _buildAudioIndicator(bool isOn) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOn ? Colors.green[700] : Colors.red[700],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            isOn ? Icons.mic : Icons.mic_off,
            size: 12,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            isOn ? 'Live' : 'Muted',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForExpert(ThemeData theme, bool isDarkMode, Size screenSize) {
    return Container(
      height: screenSize.height * 0.3,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 30,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Waiting for Expert',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The consultation will begin once the expert connects to the session',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLoadingDot(0, theme),
                _buildLoadingDot(200, theme),
                _buildLoadingDot(400, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDot(int delay, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildFooterControls(UserSessionProvider provider, ThemeData theme, bool isDarkMode, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left controls
            Row(
              children: [
                _buildControlButton(
                  icon: provider.isAudioOn ? Icons.mic : Icons.mic_off,
                  color: provider.isAudioOn ? Colors.green : Colors.red,
                  onPressed: provider.toggleAudio,
                  screenWidth: screenWidth,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: provider.isVideoOn ? Icons.videocam : Icons.videocam_off,
                  color: provider.isVideoOn ? Colors.green : Colors.red,
                  onPressed: provider.toggleVideo,
                  screenWidth: screenWidth,
                ),
              ],
            ),
            // Center timer
            Text(
              'Time left: ${provider.formatTime(provider.timeRemaining)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.04,
                color: Colors.black87,
              ),
            ),
            // Right end session button
            _buildEndSessionButton(screenWidth, provider),
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

  Widget _buildEndSessionButton(double screenWidth, UserSessionProvider provider) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.3,
        minWidth: 100,
      ),
      child: ElevatedButton.icon(
        onPressed: provider.endSessionAutomatically,
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
}