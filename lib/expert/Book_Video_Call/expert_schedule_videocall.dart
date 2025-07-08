import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shourk_application/expert/Book_Video_Call/expert_booking_profile.dart';

class ExpertVideoCallBookingPage extends StatefulWidget {
  final String expertId;

  const ExpertVideoCallBookingPage({Key? key, required this.expertId}) : super(key: key);

  @override
  _VideoCallBookingPageState createState() => _VideoCallBookingPageState();
}

class _VideoCallBookingPageState extends State<ExpertVideoCallBookingPage> {
  String selectedSessionType = '';
  String selectedTimeSlot = '';
  bool isLoading = true;
  String errorMessage = '';
  Map<String, List<String>> timeSlots = {};

  final List<Map<String, String>> sessionTypes = [
    {'label': 'Quick - 15min', 'value': 'quick'},
    {'label': 'Regular - 30min', 'value': 'regular'},
    {'label': 'Extra - 45min', 'value': 'extra'},
    {'label': 'All Access - 60min', 'value': 'all_access'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchExpertAvailability();
  }

  Future<void> _fetchExpertAvailability() async {
    try {
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/expertauth/availability/${widget.expertId}'),
        headers: {'Content-Type': 'application/json'},
      );
     
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['availability'] != null) {
          final availability = data['data']['availability'] as List;
          final Map<String, List<String>> processedSlots = {};
          
          for (var slot in availability) {
            final date = slot['date'] as String?;
            if (date == null) continue;
            
            final times = slot['times'] as Map<String, dynamic>?;
            if (times == null) continue;
            
            // Extract available times where value is true
            final availableTimes = times.entries
                .where((entry) => entry.value == true)
                .map((entry) => entry.key) // Use the time string directly
                .toList();
            
            if (availableTimes.isNotEmpty) {
              final formattedDate = _formatDate(date);
              processedSlots[formattedDate] = availableTimes;
            }
          }
          
          setState(() {
            timeSlots = processedSlots;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'No availability data found';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load data: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $error';
      });
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('EEEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book a video call',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            
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
            
            // Time Slots Section
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
            else if (timeSlots.isEmpty)
              const Center(child: Text('No available time slots'))
            else
              Container(
                height: MediaQuery.of(context).size.height * 0.5,
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
}