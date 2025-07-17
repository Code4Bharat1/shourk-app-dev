import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:shourk_application/shared/models/expert_model.dart';
import 'package:shourk_application/user/Book_VideoCall/user_booking_profile.dart';

class UserScheduleVideocall extends StatefulWidget {
  final String expertId;

  const UserScheduleVideocall({super.key, required this.expertId});

  @override
  _VideoCallBookingPageState createState() => _VideoCallBookingPageState();
}

class _VideoCallBookingPageState extends State<UserScheduleVideocall> {
  ExpertModel? _expert;
  bool _isLoading = true;
  String _error = '';

  String selectedSessionType = '';
  List<String> selectedTimeSlots = [];
  bool isLoading = true;
  String errorMessage = '';
  List<Map<String, dynamic>> availabilitySlots = [];
  bool showDurationWarning = false;

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
    _fetchExpert();
  }

  Future<void> _fetchExpert() async {
    try {
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/expertauth/${widget.expertId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _expert = ExpertModel.fromJson(data['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load expert: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching expert: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchExpertAvailability() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://amd-api.code4bharat.com/api/expertauth/availability/${widget.expertId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['availability'] != null) {
          final availability = data['data']['availability'] as List;
          final List<Map<String, dynamic>> processedSlots = [];

          for (var slot in availability) {
            final date = slot['date'] as String?;
            if (date == null) continue;

            final times = slot['times'] as Map<String, dynamic>?;
            if (times == null) continue;

            final availableTimes =
                times.entries
                    .where((entry) => entry.value == true)
                    .map((entry) => entry.key)
                    .toList();

            processedSlots.add({
              'date': date,
              'formattedDate': _formatDate(date),
              'times': availableTimes,
            });
          }

          setState(() {
            availabilitySlots = processedSlots;
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

  // Find the date for a selected time slot (expects uniqueKey as 'date-time')
  String _findSelectedDateForTime(String uniqueKey) {
    final parts = uniqueKey.split('-');
    if (parts.length < 2) return '';
    final time = parts.last;
    final date = parts.sublist(0, parts.length - 1).join('-');
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: UserUpperNavbar(),
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
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Session Type Buttons
            Row(
              children: [
                Expanded(child: _buildSessionButton('Quick - 15min', 'quick')),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSessionButton('Regular - 30min', 'regular'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildSessionButton('Extra - 45min', 'extra')),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSessionButton(
                    'All Access - 60min',
                    'all_access',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Duration warning message
            if (showDurationWarning)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "Please select the Video Call Duration first.",
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),

            // Selection counter and limit message
            if (selectedTimeSlots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show limit message when 5 slots are selected
                    if (selectedTimeSlots.length == 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Maximum 5 slots selected. To select more, remove some first.',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Time Slots Section
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (availabilitySlots.isEmpty)
              const Center(child: Text('No available time slots'))
            else
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...availabilitySlots.map(
                        (slot) => _buildDaySection(
                          slot['formattedDate'],
                          slot['date'],
                          slot['times'],
                        ),
                      ),
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
                Text(
                  "SAR ${_expert?.price ?? 'N/A'}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '•',
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Session',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Rating
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) =>
                      const Icon(Icons.star, color: Colors.orange, size: 20),
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_expert != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserBookingProfile(
                          expertId: _expert!.id,
                          selectedSessionType: selectedSessionType.isNotEmpty 
                              ? selectedSessionType 
                              : 'regular',
                          selectedDate: selectedTimeSlots.isNotEmpty 
                              ? _findSelectedDateForTime(selectedTimeSlots.first) 
                              : '',
                          selectedTime: selectedTimeSlots.isNotEmpty 
                              ? selectedTimeSlots.first 
                              : '',
                        ),
                      ),
                    );
                  }
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
      bottomNavigationBar: const UserBottomNavbar(currentIndex: 0),
    );
  }

  Widget _buildSessionButton(String label, String value) {
    bool isSelected = selectedSessionType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSessionType = value;
          showDurationWarning = false;
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

  Widget _buildDaySection(
    String formattedDay,
    String originalDate,
    List<String> times,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: formattedDay,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: '  (${times.length} times available)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        if (times.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: const Text(
              'No available times for this date',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          )
        else
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
              final timeSlot = times[index];
              final uniqueKey = '$originalDate-$timeSlot';
              final isSelected = selectedTimeSlots.contains(uniqueKey);
              final isDisabledByLimit = !isSelected && selectedTimeSlots.length >= 5;
              final isDisabledByDuration = selectedSessionType.isEmpty;

              return GestureDetector(
                onTap: () {
                  if (selectedSessionType.isEmpty) {
                    setState(() {
                      showDurationWarning = true;
                    });
                    return;
                  }

                  if (isDisabledByLimit) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Maximum 5 slots selected. Remove some to select more.',
                        ),
                        backgroundColor: Colors.red[700],
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    if (isSelected) {
                      selectedTimeSlots.remove(uniqueKey);
                    } else {
                      selectedTimeSlots.add(uniqueKey);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFFEDECE8)
                            : (isDisabledByLimit || isDisabledByDuration
                                ? Colors.grey.shade100
                                : Colors.white),
                    border: Border.all(
                      color:
                          (isDisabledByLimit || isDisabledByDuration)
                              ? Colors.grey.shade300
                              : Colors.grey.shade400,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      timeSlot,
                      style: TextStyle(
                        color: (isDisabledByLimit || isDisabledByDuration) 
                                ? Colors.grey 
                                : Colors.black,
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