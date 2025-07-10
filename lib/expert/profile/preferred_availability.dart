import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart'; 

class PreferredAvailabilityScreen extends StatefulWidget {
  const PreferredAvailabilityScreen({super.key});

  @override
  State<PreferredAvailabilityScreen> createState() => _PreferredAvailabilityScreenState();
}

class _PreferredAvailabilityScreenState extends State<PreferredAvailabilityScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, Map<String, bool>> _availability = {};
  List<String> _timeSlots = [];
  List<DateTime> _monthDays = [];

  final String baseUrl = "http://localhost:5070/api/expertauth";

  @override
  void initState() {
    super.initState();
    _initializeTimeSlots();
    _generateMonthDays();
    _loadAvailability();
  }

void _initializeTimeSlots() {
  _timeSlots = List.generate(17, (index) {
    final hour = 6 + index;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : hour;
    return '$hour12 $period';  // ✅ Remove ":00" to match backend
  });
}


  void _generateMonthDays() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    
    _monthDays = [];
    for (int i = 0; i < lastDay.day; i++) {
      _monthDays.add(firstDay.add(Duration(days: i)));
    }
  }

  void _initializeEmptyAvailability() {
  _availability = {};
  for (var day in _monthDays) {
    final dayKey = DateFormat('yyyy-MM-dd').format(day);
    _availability[dayKey] = {};
    for (var timeSlot in _timeSlots) {
      _availability[dayKey]![timeSlot] = false;
    }
  }
}


  Future<void> _loadAvailability() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found. Please login again.')),
        );
        Navigator.pop(context);
        return;
      }

      final decodedToken = JwtDecoder.decode(token);
      final expertId = decodedToken['_id'];

      final response = await http.get(
        Uri.parse('$baseUrl/availability/$expertId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          final loadedAvailability = data['data']['availability'] ?? [];
          _mergeAvailabilityWithGenerated(loadedAvailability);
        } else {
          _initializeEmptyAvailability();
        }
      } else {
        _initializeEmptyAvailability();
      }
    } catch (e) {
      print('Error loading availability: $e');
      _initializeEmptyAvailability();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mergeAvailabilityWithGenerated(List<dynamic> loadedAvailability) {
    _initializeEmptyAvailability();
    
    for (var dayData in loadedAvailability) {
      final dayKey = dayData['date'];
      final timeSlots = dayData['timeSlots'] ?? [];
      
      if (_availability.containsKey(dayKey)) {
        for (var timeSlot in timeSlots) {
          if (_availability[dayKey]!.containsKey(timeSlot)) {
            _availability[dayKey]![timeSlot] = true;
          }
        }
      }
    }
  }

  Future<void> _saveAvailability() async {
    try {
      setState(() => _isSaving = true);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('expertToken');

      if (token == null) return;

      final decodedToken = JwtDecoder.decode(token);
      final expertId = decodedToken['_id'];

      // Convert availability to API format
      List<Map<String, dynamic>> availabilityData = [];
      _availability.forEach((date, timeSlots) {
        List<String> selectedSlots = [];
        timeSlots.forEach((timeSlot, isSelected) {
          if (isSelected) {
            selectedSlots.add(timeSlot);
          }
        });
        if (selectedSlots.isNotEmpty) {
          availabilityData.add({
            'date': date,
            'timeSlots': selectedSlots,
          });
        }
      });

      final response = await http.put(
        Uri.parse('$baseUrl/availability/$expertId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'availability': availabilityData,
          'timezone': 'Asia/Riyadh',
          'monthsRange': 1,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save availability: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving availability: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetAllTimeSlots() {
    setState(() {
      _availability.forEach((date, timeSlots) {
        timeSlots.forEach((timeSlot, _) {
          _availability[date]![timeSlot] = false;
        });
      });
    });
  }

  void _toggleTimeSlot(String date, String timeSlot) {
    setState(() {
      _availability[date]![timeSlot] = !_availability[date]![timeSlot]!;
    });
  }

  void _toggleRepeatDay(String dayOfWeek, bool value) {
    setState(() {
      for (var day in _monthDays) {
        if (DateFormat('EEEE').format(day) == dayOfWeek) {
          final dayKey = DateFormat('yyyy-MM-dd').format(day);
          _availability[dayKey]!.forEach((timeSlot, _) {
            _availability[dayKey]![timeSlot] = value;
          });
        }
      }
    });
  }

  Widget _buildTimeSlotGrid(String date) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: _timeSlots.map((timeSlot) {
        final isSelected = _availability[date]?[timeSlot] ?? false;
        return GestureDetector(
          onTap: () => _toggleTimeSlot(date, timeSlot),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                timeSlot,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaySection(DateTime day) {
    final dayKey = DateFormat('yyyy-MM-dd').format(day);
    final dayName = DateFormat('EEEE, MMM d').format(day);
    final dayOfWeek = DateFormat('EEEE').format(day);
    
    // Check if all time slots are selected for this day
    bool allSelected = _availability[dayKey]?.values.every((selected) => selected) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        _buildTimeSlotGrid(dayKey),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Repeat every $dayOfWeek',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Switch(
              value: allSelected,
              onChanged: (value) => _toggleRepeatDay(dayOfWeek, value),
              activeColor: Colors.black,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Set my preferred availability",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Preferred availability. Select the times you prefer to be booked:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _resetAllTimeSlots,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                "Reset All Time Slots",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveAvailability,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      "Save Availability",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _monthDays.length,
                    itemBuilder: (context, index) {
                      return _buildDaySection(_monthDays[index]);
                    },
                  ),
                ),
              ],
            ),
                bottomNavigationBar: ExpertBottomNavbar(
        currentIndex: 3,
        // onTap: (index) {
        //   // TODO: Implement navigation
        // },
      ),
    );
  }
}