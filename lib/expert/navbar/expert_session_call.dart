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
  static const platform = MethodChannel('com.shourk_application/zoom_sdk');

  bool _loading = true;
  bool _inMeeting = false;
  String? _errorMsg;
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _zoomAuthData;
  Timer? _timer;
  int _secondsLeft = 0;
  bool _micOn = true;
  bool _camOn = true;

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
        // Optionally: call backend to mark session complete
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

  Widget _buildSessionDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 64),
            const SizedBox(height: 16),
            Text(
              'Ready to Start Expert Session',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Begin your ${_sessionData?['duration'] ?? '15'}-minute consultation session',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Duration: ${_sessionData?['duration'] ?? '15 minutes'}'),
                    Text('Role: Expert (Host)'),
                    Text('Meeting ID: ${_sessionData?['zoomMeetingId'] ?? ''}'),
                    Text('Platform: Zoom Video SDK'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchZoomTokenAndJoin,
              child: const Text('Start Expert Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingUI(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[850] : Colors.grey[200],
            child: Row(
              children: [
                Text(
                  'Waiting for user to join...',
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                Text(
                  'Meeting ID: ${_sessionData?['zoomMeetingId'] ?? ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              // TODO: Integrate your native Zoom Video SDK here using platform channels
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 80, color: isDark ? Colors.white : Colors.black),
                  const SizedBox(height: 8),
                  Text('You (Expert)', style: theme.textTheme.bodyLarge),
                  Text(_camOn ? 'Camera is on' : 'Camera is off', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                  const SizedBox(height: 16),
                  Text(
                    'Time left: ${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _leaveZoomSessionNative,
                    child: const Text('Leave Session'),
                  ),
                  const SizedBox(height: 24),
                  Text('This is a mock UI. Integrate the real Zoom Video SDK here.', style: theme.textTheme.bodySmall),
                ],
              ),
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
                    ? _buildSessionDetails(context)
                    : _buildMeetingUI(context),
      ),
    );
  }
}