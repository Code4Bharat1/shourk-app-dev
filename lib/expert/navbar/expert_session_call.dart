import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExpertSessionCallPage extends StatefulWidget {
  final String sessionId;
  final String token;

  const ExpertSessionCallPage({
    Key? key,
    required this.sessionId,
    required this.token,
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
  bool _camOn = false;
  bool _userJoined = false; // Simulate user join for demo
  Timer? _userJoinPollTimer;

  @override
  void initState() {
    super.initState();
    _fetchSessionDetails();
    _startUserJoinPolling();
  }

  void _startUserJoinPolling() {
    // Poll every 3 seconds to check if user has joined
    _userJoinPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_inMeeting || _userJoined) return;
      try {
        final response = await http.get(
          Uri.parse('http://localhost:5070/api/zoomVideo/user-joined/${widget.sessionId}'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['userJoined'] == true) {
            setState(() {
              _userJoined = true;
            });
            _userJoinPollTimer?.cancel();
          }
        }
      } catch (e) {
        // Optionally log polling error
      }
    });
  }

  Future<void> _fetchSessionDetails() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.123:5070/api/zoomVideo/get-session/${widget.sessionId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _sessionData = data['session'];
          _loading = false;
        });
      } else {
        setState(() {
          _errorMsg = 'Failed to fetch session details';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchZoomTokenAndJoin() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.123:5070/api/zoomVideo/generate-expert-video-token'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'meetingId': _sessionData!['zoomMeetingId'],
          'sessionId': widget.sessionId,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _zoomAuthData = data['data'];
          _loading = false;
        });
        await _joinZoomSessionNative();
      } else {
        setState(() {
          _errorMsg = 'Failed to get Zoom token';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _joinZoomSessionNative() async {
    if (_zoomAuthData == null) return;
    
    // Web fallback for testing
    if (kIsWeb) {
      setState(() {
        _inMeeting = true;
        _userJoined = true; // Simulate user joining for web demo
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Web Demo Mode: Zoom SDK integration requires mobile device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      await platform.invokeMethod('joinZoomSession', {
        'token': _zoomAuthData!['token'],
        'sessionName': _zoomAuthData!['sessionName'],
        'userName': (_zoomAuthData!['firstName'] ?? '') + ' ' + (_zoomAuthData!['lastName'] ?? ''),
        'userIdentity': _zoomAuthData!['userIdentity'],
        'role': _zoomAuthData!['role'],
      });
      setState(() {
        _inMeeting = true;
      });
      _startTimer();
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join Zoom session: ${e.message}')),
      );
    }
  }

  Future<void> _leaveZoomSessionNative() async {
    // Web fallback for testing
    if (kIsWeb) {
      setState(() {
        _inMeeting = false;
        _userJoined = false;
      });
      return;
    }
    
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
    int durationMinutes = 15; // default
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
      await platform.invokeMethod('toggleCam', {'on': !_camOn});
      setState(() => _camOn = !_camOn);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle camera: $e')),
      );
    }
  }

  Widget _buildPanel({
    required String role,
    required String name,
    required bool isExpert,
    required bool cameraOn,
    required bool micOn,
    bool waiting = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 12,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232B3B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      width: screenWidth > 600 ? 340 : screenWidth * 0.85,
      child: waiting
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: screenWidth * 0.13, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'Waiting for user to join...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'The consultation will begin once the user connects to the session',
                  style: TextStyle(color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TODO: Replace with real video feed for expert/user
                CircleAvatar(
                  radius: screenWidth * 0.11,
                  backgroundColor: Colors.grey[300],
                  child: cameraOn
                      ? Icon(Icons.videocam, size: screenWidth * 0.11, color: Colors.blue)
                      : Icon(Icons.person, size: screenWidth * 0.11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  cameraOn ? 'Camera is on' : 'Camera is off',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(micOn ? Icons.mic : Icons.mic_off, color: micOn ? Colors.green : Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(micOn ? 'Mic on' : 'Mic muted', style: TextStyle(color: micOn ? Colors.green : Colors.red)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpert ? Colors.purple[700] : Colors.blue[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSessionIntro() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 24),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232B3B) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        width: screenWidth > 600 ? 400 : screenWidth * 0.92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_call, size: screenWidth * 0.13, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Ready to Start Expert Session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Begin your ${_sessionData?['duration'] ?? '15'}-minute consultation session',
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchZoomTokenAndJoin,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Expert Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      color: isDark ? const Color(0xFF181F2C) : Colors.grey[200],
      child: Column(
        children: [
          Expanded(
            child: screenWidth > 600
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPanel(
                        role: 'Expert (Host)',
                        name: 'You (Expert)',
                        isExpert: true,
                        cameraOn: _camOn,
                        micOn: _micOn,
                      ),
                      _buildPanel(
                        role: 'User',
                        name: _userJoined ? 'User (Client)' : '',
                        isExpert: false,
                        cameraOn: false,
                        micOn: false,
                        waiting: !_userJoined,
                      ),
                    ],
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildPanel(
                        role: 'Expert (Host)',
                        name: 'You (Expert)',
                        isExpert: true,
                        cameraOn: _camOn,
                        micOn: _micOn,
                      ),
                      _buildPanel(
                        role: 'User',
                        name: _userJoined ? 'User (Client)' : '',
                        isExpert: false,
                        cameraOn: false,
                        micOn: false,
                        waiting: !_userJoined,
                      ),
                    ],
                  ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: screenWidth * 0.06),
            color: isDark ? const Color(0xFF232B3B) : Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_micOn ? Icons.mic : Icons.mic_off),
                      color: _micOn ? Colors.green : Colors.red,
                      onPressed: _toggleMic,
                    ),
                    IconButton(
                      icon: Icon(_camOn ? Icons.videocam : Icons.videocam_off),
                      color: _camOn ? Colors.green : Colors.red,
                      onPressed: _toggleCam,
                    ),
                  ],
                ),
                Text(
                  'Time left: ${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ElevatedButton.icon(
                  onPressed: _leaveZoomSessionNative,
                  icon: const Icon(Icons.call_end, color: Colors.white),
                  label: const Text('End Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final theme = ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
    );
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMsg != null
                ? Center(child: Text(_errorMsg ?? 'Unknown error'))
                : !_inMeeting
                    ? _buildSessionIntro()
                    : _buildSessionUI(),
      ),
    );
  }
}