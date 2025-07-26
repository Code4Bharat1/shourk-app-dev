import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchSessionDetails();
  }

  Future<void> _fetchSessionDetails() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5070/api/zoomVideo/get-session/${widget.sessionId}'),
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
        Uri.parse('http://localhost:5070/api/zoomVideo/generate-expert-video-token'),
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
    super.dispose();
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232B3B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      width: 420,
      child: waiting
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'Waiting for user to join...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
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
                const Icon(Icons.person, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
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
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232B3B) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_call, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Ready to Start Expert Session',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              'Begin your \\${_sessionData?['duration'] ?? '15'}-minute consultation session',
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchZoomTokenAndJoin,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Expert Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF181F2C) : Colors.grey[200],
      child: Column(
        children: [
          Expanded(
            child: Row(
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
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            color: isDark ? const Color(0xFF232B3B) : Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_micOn ? Icons.mic : Icons.mic_off),
                      color: _micOn ? Colors.green : Colors.red,
                      onPressed: () => setState(() => _micOn = !_micOn),
                    ),
                    IconButton(
                      icon: Icon(_camOn ? Icons.videocam : Icons.videocam_off),
                      color: _camOn ? Colors.green : Colors.red,
                      onPressed: () => setState(() => _camOn = !_camOn),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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