import 'package:flutter/material.dart';

class VideoCallPage extends StatefulWidget {
  @override
   _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  int selectedMainTab = 0; // 0 for My Bookings, 1 for My Sessions
  int selectedSubTab =
      0; // 0 for All, 1 for User Sessions, 2 for Expert Sessions
  int selectedBookingTab =
      0; // 0 for Invalid Date, 1 for expert-to-expert, 2 for Quick - 15mins
  String selectedDate = 'Choose a date';
  String selectedTime = 'Choose a time';
  bool showDateDropdown = false;
  bool showTimeDropdown = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, User',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Video Call',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arabic language badge positioned to the left of user profile
                Row(
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'User',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 32),

            // My Video Consultations Section
            Center(
              child: Text(
                'My Video Consultations',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Manage your upcoming and past consultation sessions',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),

            SizedBox(height: 24),

            // Main Tabs (My Bookings / My Sessions) in a single shadowed container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Color(0xFFF6F6F6),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMainTab = 0;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            color:
                                selectedMainTab == 0
                                    ? Colors.black
                                    : Colors.transparent,
                            child: Text(
                              'My Bookings',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    selectedMainTab == 0
                                        ? Colors.white
                                        : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMainTab = 1;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            color:
                                selectedMainTab == 1
                                    ? Colors.black
                                    : Colors.transparent,
                            child: Text(
                              'My Sessions',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    selectedMainTab == 1
                                        ? Colors.white
                                        : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),

            // Content based on selected main tab
            if (selectedMainTab == 0) ...[
              // My Bookings Content
              _buildMyBookingsContent(),
            ] else ...[
              // My Sessions Content (existing code)
              _buildMySessionsContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyBookingsContent() {
    return Column(
      children: [
        // Booking Sub Tabs (Invalid Date / expert-to-expert / Quick - 15mins)
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBookingSubTab('Invalid Date', 0),
              SizedBox(width: 16),
              _buildBookingSubTab('expert-to-expert', 1),
              SizedBox(width: 16),
              _buildBookingSubTab('Quick - 15mins', 2),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Booking Card with shadow
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[600]),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Client: ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'edward Qureshi',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Expert Info with Unconfirmed status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green[100],
                        child: Icon(
                          Icons.verified_user,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Expert: ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Aquib Hingwala',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unconfirmed',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Available Slots Section
              Text(
                'Available Slots:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 12),

              // Time Slot Rectangle
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:
                      MainAxisSize
                          .min, // Important for shrinking to fit content
                  children: [
                    Text(
                      'Fri, Jun 27',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '6:00 AM',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMySessionsContent() {
    return Column(
      children: [
        // Sub Tabs (All / User Sessions / Expert Sessions) in a single row
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubTab('All', 0),
              SizedBox(width: 16),
              _buildSubTab('User Sessions', 1),
              SizedBox(width: 16),
              _buildSubTab('Expert Sessions', 2),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Main content container with shadow
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Type Display
              Text(
                selectedSubTab == 2
                    ? 'Expert to Expert'
                    : selectedSubTab == 1
                    ? 'User to Expert'
                    : 'All Sessions',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 16),

              // Quick Session Info
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    'Quick - 15mins',
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Client Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[600]),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Client: ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'User',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Date and Time Selection with proper Stack positioning
              Stack(
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Date',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showDateDropdown = !showDateDropdown;
                                        showTimeDropdown = false;
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectedDate,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Time',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showTimeDropdown = !showTimeDropdown;
                                        showDateDropdown = false;
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectedTime,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: showDateDropdown || showTimeDropdown ? 20 : 0,
                      ),
                    ],
                  ),

                  // Date Dropdown Overlay
                  if (showDateDropdown)
                    Positioned(
                      top: 70,
                      left: 0,
                      width:
                          (MediaQuery.of(context).size.width - 64) / 2 -
                          8, // Account for padding and spacing
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDropdownItem('30 Jun 2025', () {
                              setState(() {
                                selectedDate = '30 Jun 2025';
                                showDateDropdown = false;
                              });
                            }),
                          ],
                        ),
                      ),
                    ),

                  // Time Dropdown Overlay
                  if (showTimeDropdown)
                    Positioned(
                      top: 70,
                      right: 0,
                      width:
                          (MediaQuery.of(context).size.width - 64) / 2 -
                          8, // Account for padding and spacing
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDropdownItem('10:00 AM', () {
                              setState(() {
                                selectedTime = '10:00 AM';
                                showTimeDropdown = false;
                              });
                            }),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 80,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.black),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 80,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownItem(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(text, style: TextStyle(color: Colors.black, fontSize: 14)),
      ),
    );
  }

  Widget _buildSubTab(String title, int index) {
    bool isSelected = selectedSubTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSubTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSubTab(String title, int index) {
    bool isSelected = selectedBookingTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBookingTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
