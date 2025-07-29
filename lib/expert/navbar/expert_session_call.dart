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
  bool _camOn = true;
  bool _userJoined = false;
  Timer? _userJoinPollTimer;

  @override
  void initState() {
    super.initState();
    _fetchSessionDetails();
    _startUserJoinPolling();
  }

  void _startUserJoinPolling() {
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
    
    if (kIsWeb) {
      setState(() {
        _inMeeting = true;
        _userJoined = true;
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
          'Waiting for user to join...',
          style: TextStyle(
            fontSize: width * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'The consultation will begin once the user connects to the session',
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

  Widget _buildSessionIntro() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Center(
      child: Container(
        width: screenWidth * 0.85,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: screenHeight * 0.6,
        ),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
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
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to Start Expert Session',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Begin your ${_sessionData?['duration'] ?? '15'}-minute consultation session',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _fetchZoomTokenAndJoin,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  'Start Expert Session',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
    
    return Container(
      color: Colors.grey[200],
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
                color: Colors.black87,
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
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(child: Text(_errorMsg ?? 'Unknown error'))
              : !_inMeeting
                  ? _buildSessionIntro()
                  : _buildSessionUI(),
    );
  }
}