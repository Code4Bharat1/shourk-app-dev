import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/services.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';
import 'package:shourk_application/user/navbar/user_session_call.dart';

class UserVideoCallPage extends StatefulWidget {
  const UserVideoCallPage({Key? key}) : super(key: key);

  @override
  State<UserVideoCallPage> createState() => _UserVideoCallPageState();
}



class _UserVideoCallPageState extends State<UserVideoCallPage> {
  // User data
  String firstName = "";
  String lastName = "";
  String userInitials = "U";
  String? profileImageUrl;
  String? userToken;
  String? userId;

  // Booking data
  List<Booking> bookings = [];
  bool isLoading = false;
  String? errorMessage;


  // static const String baseUrl = "https://amd-api.code4bharat.com/api";
  static const String baseUrl = "https://api.shourk.com/api";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

static const String webBaseUrl = "https://shourk.com"; // Replace with your actual web domain

Future<void> _launchMeeting(String meetingLink) async {
  print('Original meeting link: $meetingLink');
  
  if (meetingLink.isEmpty) {
    _showSnackBar('Meeting link is not available');
    return;
  }

  try {
    String fullUrl;
    
    // Check if it's a relative path or full URL
    if (meetingLink.startsWith('/')) {
      // It's a relative path, construct full URL
      fullUrl = '$webBaseUrl$meetingLink';
    } else if (meetingLink.startsWith('http://') || meetingLink.startsWith('https://')) {
      // It's already a full URL
      fullUrl = meetingLink;
    } else {
      // Add https:// if missing
      fullUrl = 'https://$meetingLink';
    }
    
    print('Full URL to launch: $fullUrl');
    
    final Uri url = Uri.parse(fullUrl);
    
    if (await canLaunchUrl(url)) {
      bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        // Try with browser mode if external app fails
        await launchUrl(
          url,
          mode: LaunchMode.inAppWebView,
        );
      }
    } else {
      // If can't launch, show dialog with copy option
      _showMeetingLinkDialog(fullUrl);
    }
  } catch (e) {
    print('Error launching meeting: $e');
    _showMeetingLinkDialog(meetingLink);
  }
}

// Add this function to show meeting link dialog
void _showMeetingLinkDialog(String meetingLink) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Meeting Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Unable to launch meeting automatically. You can copy the link below:'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              meetingLink,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        // ElevatedButton(
        //   onPressed: () {
        //     Clipboard.setData(ClipboardData(text: meetingLink));
        //     Navigator.of(context).pop();
        //     _showSnackBar('Meeting link copied to clipboard');
        //   },
        //   child: const Text('Copy Link'),
        // ),
      ],
    ),
  );
}

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _getUserToken();
      if (userToken != null && userId != null) {
        await Future.wait([_fetchUserProfile(), _fetchUserBookings()]);
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to initialize data: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    userToken = prefs.getString('userToken');

    if (userToken == null) {
      Navigator.pushReplacementNamed(context, '/userlogin');
      return;
    }

    try {
      if (JwtDecoder.isExpired(userToken!)) {
        await _refreshToken();
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(userToken!);
      userId = decodedToken['_id'];
    } catch (e) {
      print("Error parsing token: $e");
      Navigator.pushReplacementNamed(context, '/userlogin');
    }
  }

  Future<void> _fetchUserProfile() async {
    if (userId == null || userToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/userauth/$userId'),
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final userData = data['data'];
          setState(() {
            firstName = userData['firstName'] ?? '';
            lastName = userData['lastName'] ?? '';
            profileImageUrl = userData['photoFile'];
            userInitials = _getUserInitials(firstName, lastName);
          });
        }
      } else if (response.statusCode == 401) {
        await _refreshToken();
        await _fetchUserProfile();
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  Future<void> _fetchUserBookings() async {
    if (userToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/session/Userbookings'),
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('API Response: ${responseData.toString()}');

        List<dynamic> bookingData = [];
        if (responseData is List) {
          bookingData = responseData;
        } else if (responseData is Map) {
          bookingData = responseData['data'] ?? [];
        }

        setState(() {
          bookings =
              bookingData
                  .map((booking) {
                    try {
                      return Booking.fromJson(
                        Map<String, dynamic>.from(booking),
                      );
                    } catch (e) {
                      print('Error parsing booking: $e');
                      return Booking(
                        id: 'error',
            status: 'error',
            sessionTime: 'TBD',           // Add this
            duration: 'TBD',              // Add this
            sessionType: 'error',         // Add this
            expertName: 'Error',
            clientFirstName: 'Error',     // Add this
            clientLastName: 'Error',
                      );
                    }
                  })
                  .where((booking) => booking.id != 'error')
                  .toList();
        });
      } else if (response.statusCode == 401) {
        await _refreshToken();
        await _fetchUserBookings();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        setState(() {
          errorMessage = "No Booking found for this User.";
        });
      }
    } catch (e) {
      print('Network Error: $e');
      setState(() {
        errorMessage = "Network error. Please check your connection.";
      });
    }
  }

  Future<void> _refreshToken() async {
    if (userToken == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/userauth/refresh-token'),
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['newToken'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', newToken);
        setState(() {
          userToken = newToken;
        });
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      print("Token refresh failed: $e");
      Navigator.pushReplacementNamed(context, '/');
    }
  }



  String _getUserInitials(String firstName, String lastName) {
    String initials = "";
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];
    return initials.isNotEmpty ? initials.toUpperCase() : "U";
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRatingDialog(Booking booking) {
    showDialog(
      context: context,
      builder:
          (context) => RatingDialog(
            booking: booking,
            onRatingSubmitted: (updatedBooking) {
              setState(() {
                bookings =
                    bookings
                        .map(
                          (b) => b.id == updatedBooking.id ? updatedBooking : b,
                        )
                        .toList();
              });
            },
          ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
      case 'unconfirmed':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'rating submitted':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  // Helper to get the correct consultation label for the user panel
  String getConsultationLabel(Booking booking) {
    // For user panel, the consultation is always with the expert
    return 'Consultation with ${booking.expertName.isNotEmpty ? booking.expertName : 'N/A'}';
  }

  @override
  Widget build(BuildContext context) {
    final userName = '$firstName $lastName'.trim();
    final displayName = userName.isNotEmpty ? userName : 'User';

    return Scaffold(
      appBar: UserUpperNavbar(),
      backgroundColor: const Color(0xFFFCFAF6),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(displayName),
              const SizedBox(height: 24),
              const SizedBox(height: 16),
              _buildBookingsList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const UserBottomNavbar(currentIndex: 1),
    );
  }

  Widget _buildHeader(String displayName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, $displayName",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                "Video Calls",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.deepPurple,
          backgroundImage:
              profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
          child:
              profileImageUrl == null
                  ? Text(
                    userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
      ],
    );
  }


  Widget _buildBookingsList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "My Bookings",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBookingsContent()),
        ],
      ),
    );
  }

  Widget _buildBookingsContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your bookings...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // ElevatedButton(
            //   onPressed: _initializeData,
            //   child: const Text('Try Again'),
            // ),
          ],
        ),
      );
    }

    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Bookings Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Your upcoming video call bookings will appear here',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with session title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    getConsultationLabel(booking),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(booking.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "(${booking.duration}) ${booking.sessionType}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // People and slots section
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return _buildMobileBookingDetails(booking);
                } else {
                  return _buildDesktopBookingDetails(booking);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBookingDetails(Booking booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // People section
        const Text(
          "People",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Client:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.clientFirstName} ${booking.clientLastName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Expert:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    booking.expertName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Booked slots
        const Text(
          "Booked Slot",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(booking.formattedDate, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(booking.sessionTime, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Actions
        _buildActionButtons(booking),
      ],
    );
  }

  Widget _buildDesktopBookingDetails(Booking booking) {
    return Column(
      children: [
        // Header row for sections
        const Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                "People",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "Booked Slots",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "Actions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Content row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // People section
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Client:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${booking.clientFirstName} ${booking.clientLastName}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Expert:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.expertName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Booked slots section
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          booking.formattedDate,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          booking.sessionTime,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Actions section
            Expanded(flex: 2, child: _buildActionButtons(booking)),
          ],
        ),
      ],
    );
  }
    // Add this helper function to extract meeting ID
  String? _extractMeetingId(String? meetingLink) {
    if (meetingLink == null) return null;
    
    try {
      final uri = Uri.parse(meetingLink);
      // Extract from path segments: /j/MEETING_ID
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'j') {
        return uri.pathSegments[1];
      }
      // Extract from last path segment
      return uri.pathSegments.last;
    } catch (e) {
      return meetingLink; // Fallback to full link
    }
  }

Widget _buildActionButtons(Booking booking) {
  List<Widget> buttons = [];

  if (booking.status.toLowerCase() == 'confirmed') {
    buttons.add(
      OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/'),
        icon: const Icon(Icons.chat, size: 16),
        label: const Text('Chat'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );

    // Check for meeting link
if (booking.userMeetingLink != null && booking.userMeetingLink!.isNotEmpty) {
  buttons.add(
    ElevatedButton.icon(
  onPressed: () {
    // Extract meeting ID from the link
    final meetingId = _extractMeetingId(booking.userMeetingLink);
    final sessionId = booking.id;

    if (meetingId == null || meetingId.isEmpty) {
      _showSnackBar('Meeting ID is missing');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSessionCallPage(
          meetingId: meetingId,
          sessionId: sessionId,
        ),
        settings: RouteSettings(arguments: userToken),
      ),
    );
  },
  icon: const Icon(Icons.videocam, size: 16),
  label: const Text('Join Meeting'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
),
  );
      
      // Add a secondary button to copy the full link
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            String fullUrl = booking.userMeetingLink!.startsWith('/') 
              ? '$webBaseUrl${booking.userMeetingLink!}'
              : booking.userMeetingLink!;
            
            Clipboard.setData(ClipboardData(text: fullUrl));
            _showSnackBar('Meeting link copied to clipboard');
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy Link'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      );
    } else {
      buttons.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Zoom link coming soon',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ),
      );
    }
  }


  if (booking.status.toLowerCase() == 'completed' && !booking.hasRating) {
    buttons.add(
      ElevatedButton.icon(
        onPressed: () => _showRatingDialog(booking),
        icon: const Icon(Icons.star, size: 16),
        label: const Text('Rate Session'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.start,
    children: buttons,
  );
}
}

class Booking {
  final String id;
  final String status;
  final String sessionTime;
  final String duration;
  final String sessionType;
  final String expertName;
  final String clientFirstName;
  final String clientLastName;
  final String? userMeetingLink;
  final DateTime? sessionDate;
  final bool hasRating;

  Booking({
    required this.id,
    required this.status,
    required this.sessionTime,
    required this.duration,
    required this.sessionType,
    required this.expertName,
    required this.clientFirstName,
    required this.clientLastName,
    this.userMeetingLink,
    this.sessionDate,
    this.hasRating = false,
  });

  String get formattedDate {
    if (sessionDate != null) {
      return '${_getWeekday(sessionDate!)}, ${sessionDate!.day}/${sessionDate!.month}';
    }
    return 'TBD';
  }

  String _getWeekday(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  Booking copyWith({
    String? id,
    String? status,
    String? sessionTime,
    String? duration,
    String? sessionType,
    String? expertName,
    String? clientFirstName,
    String? clientLastName,
    String? userMeetingLink,
    DateTime? sessionDate,
    bool? hasRating,
  }) {
    return Booking(
      id: id ?? this.id,
      status: status ?? this.status,
      sessionTime: sessionTime ?? this.sessionTime,
      duration: duration ?? this.duration,
      sessionType: sessionType ?? this.sessionType,
      expertName: expertName ?? this.expertName,
      clientFirstName: clientFirstName ?? this.clientFirstName,
      clientLastName: clientLastName ?? this.clientLastName,
      userMeetingLink: userMeetingLink ?? this.userMeetingLink,
      sessionDate: sessionDate ?? this.sessionDate,
      hasRating: hasRating ?? this.hasRating,
    );
  }

factory Booking.fromJson(Map<String, dynamic> json) {
  try {
    print('=== BOOKING JSON DEBUG ===');
    print('Full JSON: ${json.toString()}');
    print('consultingExpertID: ${json['consultingExpertID']}');
    print('expertId: ${json['expertId']}');
    print('expertName: ${json['expertName']}'); // 🔥 ADD THIS DEBUG LINE
    print('========================');

    // Parse session time and date
    String sessionTime = 'TBD';
    DateTime? sessionDate;
    if (json['slots'] != null && json['slots'] is List && json['slots'].isNotEmpty) {
      final outerSlot = json['slots'][0];
      if (outerSlot is List && outerSlot.isNotEmpty) {
        final firstSlot = outerSlot[0];
        if (firstSlot is Map) {
          sessionTime = firstSlot['selectedTime']?.toString() ?? 'TBD';
          if (firstSlot['selectedDate'] != null) {
            sessionDate = DateTime.tryParse(firstSlot['selectedDate']);
          }
        }
      }
    }

    // ===== EXPERT NAME PARSING WITH FALLBACK =====
    String expertName = 'Expert';
    
    // 🔥 FIRST: Try the expertName field we're adding
    if (json['expertName'] != null && json['expertName'].toString().trim().isNotEmpty) {
      expertName = json['expertName'].toString().trim();
    }
    // Try consultingExpertID if it's a Map
    else if (json['consultingExpertID'] is Map) {
      final expert = json['consultingExpertID'] as Map<String, dynamic>;
      String firstName = expert['firstName']?.toString().trim() ?? '';
      String lastName = expert['lastName']?.toString().trim() ?? '';
      
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        expertName = '$firstName $lastName'.trim();
      } else if (expert['name'] != null) {
        expertName = expert['name'].toString().trim();
      }
    }
    // Try expertId if it's a Map
    else if (json['expertId'] is Map) {
      final expert = json['expertId'] as Map<String, dynamic>;
      String firstName = expert['firstName']?.toString().trim() ?? '';
      String lastName = expert['lastName']?.toString().trim() ?? '';
      
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        expertName = '$firstName $lastName'.trim();
      }
    }
    // 🔥 FALLBACK: Create expert name from areaOfExpertise + "Specialist"
    else if (json['areaOfExpertise'] != null) {
      String area = json['areaOfExpertise'].toString();
      if (area != 'Home') {
        expertName = '$area Specialist';
      } else {
        expertName = 'Home & Lifestyle Expert';
      }
    }

    // Get client name
    String clientFirstName = json['firstName']?.toString().trim() ?? 'Client';
    String clientLastName = json['lastName']?.toString().trim() ?? '';

    if (clientFirstName.isEmpty && clientLastName.isEmpty) {
      if (json['email'] != null) {
        clientFirstName = json['email'].toString().split('@').first;
      } else {
        clientFirstName = 'Client';
      }
    }

    return Booking(
      id: json['_id']?.toString() ?? '',
      status: json['status']?.toString()?.toLowerCase() ?? 'pending',
      sessionTime: sessionTime,
      duration: json['duration']?.toString() ?? 'TBD',
      sessionType: json['sessionType']?.toString() ?? 'user-to-expert',
      expertName: expertName,
      clientFirstName: clientFirstName,
      clientLastName: clientLastName,
      userMeetingLink: json['userMeetingLink']?.toString() ?? 
                      json['zoomMeetingLink']?.toString(),
      sessionDate: sessionDate,
      hasRating: json['rating'] != null,
    );
  } catch (e) {
    print('Error parsing booking: $e');
    print('Raw JSON: $json');
    
    return Booking(
      id: json['_id']?.toString() ?? 'unknown',
      status: 'error',
      sessionTime: 'TBD',
      duration: 'TBD',
      sessionType: 'user-to-expert',
      expertName: 'Error Loading Expert',
      clientFirstName: 'Client',
      clientLastName: '',
    );
  }
}
}

class RatingDialog extends StatefulWidget {
  final Booking booking;
  final Function(Booking) onRatingSubmitted;

  const RatingDialog({
    Key? key,
    required this.booking,
    required this.onRatingSubmitted,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      final response = await http.post(
        // Uri.parse('https://amd-api.code4bharat.com/api/rating/rateSession'),
        Uri.parse('https://api.shourk.com/api/rating/rateSession'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sessionId': widget.booking.id,
          'rating': rating,
          'comment': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final updatedBooking = widget.booking.copyWith(
          status: 'rating submitted',
          hasRating: true,
        );

        widget.onRatingSubmitted(updatedBooking);
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully!')),
        );
      } else {
        throw Exception('Failed to submit rating');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting rating: ${e.toString()}')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Your Session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('How was your session with ${widget.booking.expertName}?'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => rating = index + 1),
                icon: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Add a comment (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitRating,
          child:
              isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Submit Rating'),
        ),
      ],
    );
  }
}