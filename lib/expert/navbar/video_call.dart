import 'package:flutter/material.dart';
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
  List<Booking> _bookings = [];
  List<Session> _sessions = [];
  bool _loading = true;
  String? _error;
  String? _authToken;
  final ScrollController _scrollController = ScrollController();
  bool _showRateModal = false;
  Booking? _selectedBooking;
  double _rating = 0;
  bool _showCancelModal = false;
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

  @override
  void initState() {
    super.initState();
    _otherReasonController = TextEditingController();
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

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Simulate API calls with mock data
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _bookings = _mockBookings();
        _sessions = _mockSessions();
        _loading = false;
      });

      if (widget.sessionId != null) {
        _scrollToHighlightedSession();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load data: ${e.toString()}';
      });
    }
  }

  void _scrollToHighlightedSession() {
    final index = _sessions.indexWhere((s) => s.id == widget.sessionId);
    if (index != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          index * 300.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  List<Booking> _mockBookings() {
    return [
      Booking(
        id: '1',
        clientName: 'John Doe',
        expertName: 'Basim Thakur',
        status: 'confirmed',
        sessionType: 'expert-to-expert',
        sessionDate: '2025-07-20T14:30:00Z',
        duration: '30 mins',
        meetingLink: 'https://zoom.us/j/1234567890',
      ),
      Booking(
        id: '2',
        clientName: 'Jane Smith',
        expertName: 'Basim Thakur',
        status: 'completed',
        sessionType: 'user-to-expert',
        sessionDate: '2025-07-18T10:00:00Z',
        duration: '45 mins',
        meetingLink: 'https://zoom.us/j/0987654321',
      ),
      Booking(
        id: '3',
        clientName: 'Robert Johnson',
        expertName: 'Basim Thakur',
        status: 'unconfirmed',
        sessionType: 'expert-to-expert',
        sessionDate: '',
        duration: '30 mins',
        meetingLink: '',
      ),
    ];
  }

  List<Session> _mockSessions() {
    return [
      Session(
        id: 's1',
        clientName: 'SDSAFASD ASFASFA',
        expertName: 'Basim Thakur',
        status: 'unconfirmed',
        sessionType: 'expert-to-expert',
        duration: '30 mins',
        notes: 'Please prepare your questions in advance',
        sessionDate: '',
        meetingLink: '',
      ),
      Session(
        id: 's2',
        clientName: 'Alice Wonderland',
        expertName: 'Basim Thakur',
        status: 'confirmed',
        sessionType: 'user-to-expert',
        duration: '45 mins',
        notes: 'Career consultation session',
        sessionDate: '2025-07-22T16:00:00Z',
        meetingLink: 'https://zoom.us/j/1122334455',
      ),
      Session(
        id: 's3',
        clientName: 'Bob Builder',
        expertName: 'Basim Thakur',
        status: 'completed',
        sessionType: 'expert-to-expert',
        duration: '60 mins',
        notes: 'Home renovation consultation',
        sessionDate: '2025-07-15T11:00:00Z',
        meetingLink: '',
      ),
    ];
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
    if (dateString.isEmpty) return 'Not scheduled';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "confirmed":
        return const Color(0xFF4CAF50);
      case "completed":
        return const Color(0xFF2196F3);
      case "unconfirmed":
        return const Color(0xFFFF9800);
      case "rejected":
      case "cancelled":
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  Widget _buildMainTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedMainTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 0 ? const Color(0xFF121212) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "My Bookings",
                    style: TextStyle(
                      color: _selectedMainTab == 0 ? Colors.white : const Color(0xFF666666),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 1 ? const Color(0xFF121212) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "My Sessions",
                    style: TextStyle(
                      color: _selectedMainTab == 1 ? Colors.white : const Color(0xFF666666),
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

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
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
                    color: const Color(0xFF121212),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 16),
            
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Session Type: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  TextSpan(
                    text: booking.sessionType,
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Duration: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  TextSpan(
                    text: booking.duration,
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Client: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF121212),
                    ),
                  ),
                  TextSpan(
                    text: booking.clientName,
                    style: const TextStyle(color: Color(0xFF121212)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Expert: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  TextSpan(
                    text: booking.expertName,
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              "Scheduled Time:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF121212),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(booking.sessionDate),
              style: const TextStyle(color: Color(0xFF666666)),
            ),
            const SizedBox(height: 16),
            
            if (booking.status == "confirmed")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ready to join",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF121212),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _joinMeeting(booking.meetingLink),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text("Join Meeting"),
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
                child: const Text("Rate This Session"),
              ),
            
            if (booking.status == "confirmed" || booking.status == "unconfirmed")
              TextButton(
                onPressed: () {
                  setState(() {
                    _showCancelModal = true;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text("Cancel Booking"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    final isUnconfirmed = session.status == "unconfirmed";
    final isHighlighted = session.id == widget.sessionId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isHighlighted ? Colors.blue : const Color(0xFFEEEEEE), 
          width: isHighlighted ? 2 : 1
        ),
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
                    color: const Color(0xFF121212),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 16),
            
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Session Type: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  TextSpan(
                    text: session.sessionType,
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Duration: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  TextSpan(
                    text: session.duration,
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Client: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF121212),
                    ),
                  ),
                  TextSpan(
                    text: session.clientName,
                    style: const TextStyle(color: Color(0xFF121212)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Expert: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  TextSpan(
                    text: session.expertName,
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              "Scheduled Time:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF121212),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(session.sessionDate),
              style: const TextStyle(color: Color(0xFF666666)),
            ),
            const SizedBox(height: 16),
            
            if (session.notes.isNotEmpty) ...[
              Text(
                "Notes:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF121212),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.notes,
                style: const TextStyle(color: Color(0xFF666666)),
              ),
              const SizedBox(height: 16),
            ],
            
            if (isUnconfirmed)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Action Required",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF121212),
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF44336),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text("Decline"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text("Accept"),
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
                      color: const Color(0xFF121212),
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Chat"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _joinMeeting(session.meetingLink),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Join Meeting"),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showCancelModal = true;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("Cancel"),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationModal() {
    return AlertDialog(
      title: const Text('Cancel Session'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please select your reason(s) for cancellation:'),
            const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextField(
                controller: _otherReasonController,
                decoration: const InputDecoration(
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
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_cancellationReasons.values.any((value) => value)) {
              if (_cancellationReasons[6] == true && _otherReason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please specify your reason')),
                );
                return;
              }
              setState(() {
                _showCancelModal = false;
                _termsAccepted = true; // Skip terms modal for simplicity
                _loadingCancel = true;
              });
              
              // Simulate cancellation
              Future.delayed(const Duration(seconds: 2), () {
                setState(() {
                  _loadingCancel = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session cancelled successfully')),
                  );
                });
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least one reason')),
              );
            }
          },
          child: const Text('Confirm'),
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

  Widget _buildRatingModal() {
    return AlertDialog(
      title: const Text('Rate This Session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          const SizedBox(height: 20),
          const TextField(
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showRateModal = false;
              _rating = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rating submitted successfully')),
            );
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading consultations...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Failed to load data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedMainTab == 0 ? Icons.calendar_today : Icons.video_call,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            _selectedMainTab == 0 
                ? 'No bookings found' 
                : 'No sessions found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedMainTab == 0 
                ? 'Your upcoming bookings will appear here' 
                : 'Your sessions will appear here',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    
    final items = _selectedMainTab == 0 ? _bookings : _sessions;
    if (items.isEmpty) return _buildEmptyState();
    
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        const SizedBox(height: 16),
        ...items.map((item) {
          return _selectedMainTab == 0 
              ? _buildBookingCard(item as Booking) 
              : _buildSessionCard(item as Session);
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Video Consultations'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Manage your upcoming and past consultation sessions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                _buildMainTabs(),
                const SizedBox(height: 24),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
          
          // Modal barrier
          if (_showCancelModal || _showRateModal)
            Container(
              color: Colors.black54,
            ),
          
          // Cancellation modal
          if (_showCancelModal)
            Center(
              child: _buildCancellationModal(),
            ),
          
          // Rating modal
          if (_showRateModal)
            Center(
              child: _buildRatingModal(),
            ),
        ],
      ),
    );
  }
}

class Booking {
  final String id;
  final String clientName;
  final String expertName;
  final String status;
  final String sessionType;
  final String sessionDate;
  final String duration;
  final String meetingLink;

  Booking({
    required this.id,
    required this.clientName,
    required this.expertName,
    required this.status,
    required this.sessionType,
    required this.sessionDate,
    required this.duration,
    required this.meetingLink,
  });
}

class Session {
  final String id;
  final String clientName;
  final String expertName;
  final String status;
  final String sessionType;
  final String duration;
  final String notes;
  final String sessionDate;
  final String meetingLink;

  Session({
    required this.id,
    required this.clientName,
    required this.expertName,
    required this.status,
    required this.sessionType,
    required this.duration,
    required this.notes,
    required this.sessionDate,
    required this.meetingLink,
  });
}