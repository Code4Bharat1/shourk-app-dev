import 'package:flutter/material.dart';
import 'package:shourk_application/expert/Book_Video_Call/expert_booking_profile.dart';

class ExpertVideoCallBookingPage extends StatefulWidget {
  const ExpertVideoCallBookingPage({Key? key}) : super(key: key);

  @override
  _VideoCallBookingPageState createState() => _VideoCallBookingPageState();
}

class _VideoCallBookingPageState extends State<ExpertVideoCallBookingPage> {
  String selectedSessionType = '';
  String selectedTimeSlot = '';

  final List<Map<String, String>> sessionTypes = [
    {'label': 'Quick - 15min', 'value': 'quick'},
    {'label': 'Regular - 30min', 'value': 'regular'},
    {'label': 'Extra - 45min', 'value': 'extra'},
    {'label': 'All Access - 60min', 'value': 'all_access'},
  ];

  final Map<String, List<String>> timeSlots = {
    'Monday, Mar 25': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Tuesday, Mar 26': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Wednesday, Mar 27': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Thursday, Mar 28': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Friday, Mar 29': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Saturday, March 30': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Sunday, Mar 31': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Monday, Apr 1': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Tuesday, Apr 2': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Wednesday, Apr 3': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Thursday, Apr 4': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Friday, Apr 5': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Saturday, Apr 6': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Sunday, Apr 7': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Monday, Apr 8': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Tuesday, Apr 9': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Wednesday, Apr 10': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Thursday, April 11': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Friday, April 12': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Saturday, Apr 13': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Sunday, Apr 14': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Monday, Apr 15': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Tuesday, Apr 16': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Wednesday, Apr 17': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Thursday, Apr 18': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Friday, Apr 19': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Saturday, Apr 20': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Sunday, Apr 21': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Monday, Apr 22': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Tuesday, Apr 23': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ],
  'Wednesday, Apr 24': [
    '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Book a video call',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            
            // Subtitle
            const Text(
              'Select one of the available time slots below:',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            
            // Session Type Buttons
            Row(
              children: [
                Expanded(
                  child: _buildSessionButton('Quick - 15min', 'quick'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSessionButton('Regular - 30min', 'regular'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSessionButton('Extra - 45min', 'extra'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSessionButton('All Access - 60min', 'all_access'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Scrollable Time Slots Section
            Container(
              height: MediaQuery.of(context).size.height * 0.5, // Adjust height as needed
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...timeSlots.entries.map((entry) => _buildDaySection(entry.key, entry.value)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Divider
            Container(
              height: 1,
              color: Colors.black,
              margin: const EdgeInsets.symmetric(vertical: 20),
            ),
            
            // Price and Rating Section
            Row(
              children: [
                const Text(
                  '\$550',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '•',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Session',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Rating
            Row(
              children: [
                ...List.generate(5, (index) => 
                  const Icon(Icons.star, color: Colors.orange, size: 20)
                ),
                const SizedBox(width: 8),
                const Text(
                  '5.0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Request Button
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // _handleBookingRequest();
                  Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ExpertBookingScreen()),
            );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionButton(String label, String value) {
    bool isSelected = selectedSessionType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSessionType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF8F7F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDaySection(String day, List<String> times) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: times.length,
          itemBuilder: (context, index) {
            String timeSlot = '$day-${times[index]}';
            bool isSelected = selectedTimeSlot == timeSlot;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedTimeSlot = timeSlot;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEDECE8) : Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    times[index],
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  // CHANGE: Added method to handle booking request
  void _handleBookingRequest() {
    if (selectedSessionType.isEmpty || selectedTimeSlot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both session type and time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Confirmation'),
          content: Text(
            'Session: ${sessionTypes.firstWhere((type) => type['value'] == selectedSessionType)['label']}\n'
            'Time: ${selectedTimeSlot.split('-')[1]}\n'
            'Day: ${selectedTimeSlot.split('-')[0]}\n'
            'Price: \$550',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // CHANGE: Navigate back to home or show success message
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video call booked successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: const Text(
                'Confirm Booking',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
