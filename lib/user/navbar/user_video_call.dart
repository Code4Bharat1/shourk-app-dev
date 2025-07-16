import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';

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
  
  // Cancellation state
  bool isCancelling = false;
  Booking? bookingToCancel;
  List<Map<String, dynamic>> cancellationReasons = [
    {"id": 1, "reason": "Schedule conflict", "checked": false},
    {"id": 2, "reason": "Found alternative solution", "checked": false},
    {"id": 3, "reason": "Expert not suitable for my needs", "checked": false},
    {"id": 4, "reason": "Technical issues", "checked": false},
    {"id": 5, "reason": "Cost concerns", "checked": false},
    {"id": 6, "reason": "Other", "checked": false},
  ];
  String otherReason = "";
  bool termsAccepted = false;
  
  static const String baseUrl = "https://amd-api.code4bharat.com/api";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _getUserToken();
      if (userToken != null && userId != null) {
        await Future.wait([
          _fetchUserProfile(),
          _fetchUserBookings(),
        ]);
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
        
        List<dynamic> bookingData = [];
        if (responseData is List) {
          bookingData = responseData;
        } else if (responseData is Map) {
          bookingData = responseData['data'] ?? responseData['bookings'] ?? [];
        }

        setState(() {
          bookings = bookingData.map((booking) {
            try {
              return Booking.fromJson(Map<String, dynamic>.from(booking));
            } catch (e) {
              print('Error parsing booking: $e');
              return null;
            }
          }).where((booking) => booking != null).cast<Booking>().toList();
        });
      } else if (response.statusCode == 401) {
        await _refreshToken();
        await _fetchUserBookings();
      } else {
        setState(() {
          errorMessage = "Failed to load bookings. Please try again.";
        });
      }
    } catch (e) {
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
        Navigator.pushReplacementNamed(context, '/userlogin');
      }
    } catch (e) {
      print("Token refresh failed: $e");
      Navigator.pushReplacementNamed(context, '/userlogin');
    }
  }

  Future<void> _cancelSession() async {
    if (bookingToCancel == null || userToken == null) return;

    // Prepare cancellation data
    final selectedReasons = cancellationReasons
        .where((reason) => reason['checked'] == true)
        .map((reason) => reason['reason'].toString())
        .toList();

    if (selectedReasons.isEmpty) {
      _showSnackBar('Please select at least one reason for cancellation');
      return;
    }

    final isOtherSelected = cancellationReasons.any((reason) => 
        reason['id'] == 6 && reason['checked'] == true);
    
    if (isOtherSelected && otherReason.trim().isEmpty) {
      _showSnackBar('Please provide details for "Other" reason');
      return;
    }

    if (!termsAccepted) {
      _showSnackBar('Please accept the terms and conditions');
      return;
    }

    setState(() => isCancelling = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cancelsession/canceluser'),
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sessionId': bookingToCancel!.id,
          'reasons': selectedReasons,
          'otherReason': isOtherSelected ? otherReason : "",
          'sessionModel': "UserToExpertSession",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Update local state
          setState(() {
            bookings = bookings.map((booking) {
              if (booking.id == bookingToCancel!.id) {
                return booking.copyWith(status: 'cancelled');
              }
              return booking;
            }).toList();
          });
          
          _showSnackBar('Session cancelled successfully');
          Navigator.of(context).pop(); // Close terms modal
          setState(() => bookingToCancel = null);
        } else {
          throw Exception(data['message'] ?? 'Failed to cancel session');
        }
      } else {
        throw Exception('Failed to cancel session: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error cancelling session: ${e.toString()}');
    } finally {
      setState(() => isCancelling = false);
    }
  }

  void _showCancelDialog(Booking booking) {
    setState(() {
      bookingToCancel = booking;
      // Reset cancellation state
      cancellationReasons = cancellationReasons.map((reason) => 
          {...reason, 'checked': false}).toList();
      otherReason = "";
      termsAccepted = false;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Cancel Session'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please select your reason for cancellation:'),
                  const SizedBox(height: 16),
                  ...cancellationReasons.map((reason) => CheckboxListTile(
                    title: Text(reason['reason']),
                    value: reason['checked'],
                    onChanged: (value) {
                      setState(() {
                        cancellationReasons = cancellationReasons.map((r) => 
                          r['id'] == reason['id'] 
                            ? {...r, 'checked': value ?? false}
                            : {...r, 'checked': false}
                        ).toList();
                      });
                    },
                  )).toList(),
                  if (cancellationReasons.any((r) => r['id'] == 6 && r['checked'] == true))
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Please specify',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => otherReason = value,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showTermsDialog();
                },
                child: const Text('Next'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Cancellation Terms'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please review the cancellation terms:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Cancellations made within 24 hours may incur a fee\n'
                    '2. Full refund for cancellations >24 hours in advance\n'
                    '3. Rescheduling is subject to expert availability\n'
                    '4. Multiple cancellations may affect future bookings',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: termsAccepted,
                        onChanged: (value) => setState(() => termsAccepted = value ?? false),
                      ),
                      const Text('I accept the terms'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: isCancelling ? null : _cancelSession,
                child: isCancelling
                    ? const CircularProgressIndicator()
                    : const Text('Confirm Cancellation'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getUserInitials(String firstName, String lastName) {
    String initials = "";
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];
    return initials.isNotEmpty ? initials.toUpperCase() : "U";
  }

  Future<void> _launchMeeting(String meetingLink) async {
    try {
      final Uri url = Uri.parse(meetingLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch meeting link');
      }
    } catch (e) {
      _showSnackBar('Error opening meeting: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showRatingDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        booking: booking,
        onRatingSubmitted: (updatedBooking) {
          setState(() {
            bookings = bookings.map((b) => 
              b.id == updatedBooking.id ? updatedBooking : b).toList();
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
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'rating submitted':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
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
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildBookingsList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const UserBottomNavbar(currentIndex: 1),
    );
  }
// 1. Header Builder
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
        backgroundImage: profileImageUrl != null 
            ? NetworkImage(profileImageUrl!) 
            : null,
        child: profileImageUrl == null
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

// 2. Info Card Builder
Widget _buildInfoCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Colors.blue, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            "Your upcoming video calls will appear here. Make sure to test your audio/video before joining.",
            style: TextStyle(fontSize: 14, color: Colors.blue),
          ),
        ),
      ],
    ),
  );
}

// 3. Bookings List Builder
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
        Expanded(
          child: _buildBookingsContent(),
        ),
      ],
    ),
  );
}

// 4. Bookings Content Builder
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
          ElevatedButton(
            onPressed: _initializeData,
            child: const Text('Try Again'),
          ),
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

// 5. Booking Card Builder
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
          _buildBookingHeader(booking),
          const SizedBox(height: 12),
          _buildBookingDetails(booking),
          const SizedBox(height: 12),
          _buildParticipants(booking),
          const SizedBox(height: 16),
          _buildActionButtons(booking),
        ],
      ),
    ),
  );
}

// 6. Booking Header Builder
Widget _buildBookingHeader(Booking booking) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          booking.formattedDate,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor(booking.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          booking.status.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _getStatusColor(booking.status),
          ),
        ),
      ),
    ],
  );
}

// 7. Booking Details Builder
Widget _buildBookingDetails(Booking booking) {
  return Row(
    children: [
      const Icon(Icons.access_time, size: 16, color: Colors.blue),
      const SizedBox(width: 8),
      Text(
        '${booking.sessionTime ?? 'TBD'} • ${booking.duration ?? 'TBD'}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          booking.sessionType,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    ],
  );
}

// 8. Participants Builder
Widget _buildParticipants(Booking booking) {
  return Container(
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
            const Text('You:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Text('$firstName $lastName', style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.person_outline, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Expert:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Text(booking.expertName, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    ),
  );
}

// 9. Action Buttons Builder
Widget _buildActionButtons(Booking booking) {
  List<Widget> buttons = [];

  if (booking.status.toLowerCase() == 'confirmed') {
    buttons.add(
      OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/home'),
        icon: const Icon(Icons.chat, size: 16),
        label: const Text('Chat'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );

    if (booking.userMeetingLink != null && booking.userMeetingLink!.isNotEmpty) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () => _launchMeeting(booking.userMeetingLink!),
          icon: const Icon(Icons.videocam, size: 16),
          label: const Text('Join Meeting'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
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
            'Meeting link pending',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ),
      );
    }

    // Add cancel button for confirmed sessions
    buttons.add(
      OutlinedButton.icon(
        onPressed: () => _showCancelDialog(booking),
        icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
        label: const Text('Cancel', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  if (booking.status.toLowerCase() == 'unconfirmed') {
    buttons.add(
      OutlinedButton.icon(
        onPressed: () => _showCancelDialog(booking),
        icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
        label: const Text('Cancel', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
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

  return buttons.isEmpty
      ? const SizedBox.shrink()
      : Wrap(
          spacing: 8,
          runSpacing: 8,
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
  final String? userMeetingLink;
  final DateTime? sessionDate;
  final bool hasRating;

  Booking({
    required this.id,
    required this.status,
    this.sessionTime = 'TBD',
    this.duration = 'TBD',
    this.sessionType = 'User To Expert',
    this.expertName = 'Expert',
    this.userMeetingLink,
    this.sessionDate,
    this.hasRating = false,
  });

  String get formattedDate {
    if (sessionDate != null) {
      return '${sessionDate!.day}/${sessionDate!.month}/${sessionDate!.year}';
    }
    return 'TBD';
  }

  Booking copyWith({
    String? id,
    String? status,
    String? sessionTime,
    String? duration,
    String? sessionType,
    String? expertName,
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
      userMeetingLink: userMeetingLink ?? this.userMeetingLink,
      sessionDate: sessionDate ?? this.sessionDate,
      hasRating: hasRating ?? this.hasRating,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
      // Parse session date
      DateTime? sessionDate;
      if (json['sessionDate'] != null) {
        sessionDate = DateTime.tryParse(json['sessionDate'].toString());
      }

      // Parse expert name
      String expertName = 'Expert';
      if (json['expertId'] is Map) {
        final expertData = json['expertId'];
        final firstName = expertData['firstName']?.toString() ?? '';
        final lastName = expertData['lastName']?.toString() ?? '';
        expertName = '$firstName $lastName'.trim();
        if (expertName.isEmpty) expertName = 'Expert';
      } else if (json['consultingExpertID'] is Map) {
        final expertData = json['consultingExpertID'];
        final firstName = expertData['firstName']?.toString() ?? '';
        final lastName = expertData['lastName']?.toString() ?? '';
        expertName = '$firstName $lastName'.trim();
        if (expertName.isEmpty) expertName = 'Expert';
      }

      return Booking(
        id: json['_id']?.toString() ?? '',
        status: json['status']?.toString()?.toLowerCase() ?? 'pending',
        sessionTime: json['sessionTime']?.toString() ?? 'TBD',
        duration: json['duration']?.toString() ?? 'TBD',
        sessionType: json['sessionType']?.toString() ?? 'User To Expert',
        expertName: expertName,
        userMeetingLink: json['userMeetingLink']?.toString(),
        sessionDate: sessionDate,
        hasRating: json['rating'] != null,
      );
    } catch (e) {
      print('Error parsing booking: $e');
      return Booking(
        id: 'error',
        status: 'error',
        expertName: 'Error',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      final response = await http.post(
        Uri.parse('https://amd-api.code4bharat.com/api/rating/rateSession'),
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
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Add a comment (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitRating,
          child: isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}