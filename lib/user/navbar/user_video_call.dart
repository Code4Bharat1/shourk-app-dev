import 'package:flutter/material.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';

class UserVideoCallPage extends StatefulWidget {
  const UserVideoCallPage({Key? key}) : super(key: key);

  @override
  State<UserVideoCallPage> createState() => _UserVideoCallPageState();
}

class _UserVideoCallPageState extends State<UserVideoCallPage> {
  String username = "abdul maaz"; // Placeholder
  String userInitials = "AM"; // Placeholder
  bool isLoading = false;
  List<dynamic> bookings = []; // Placeholder booking data

  @override
  void initState() {
    super.initState();
    _fetchUserBookings();
  }

  Future<void> _fetchUserBookings() async {
    setState(() => isLoading = true);

    // TODO: Replace this with your actual API call
    await Future.delayed(const Duration(seconds: 1));
    // Sample response simulation
    setState(() {
      isLoading = false;
      bookings = []; // Add booking objects from API when available
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserUpperNavbar(),
      backgroundColor: const Color(0xFFFCFAF6),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER: Hi, Name | Language | Profile
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hi, $username", style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text(
                        "Video Call",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const Row(
                    children: [
                      Icon(Icons.language, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    userInitials.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  username,
                  style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// MY BOOKINGS BUTTON
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Text(
                "My Bookings",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            /// CONTENT
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : bookings.isEmpty
                      ? const Center(
                          child: Text(
                            "No bookings found for this user.",
                            style: TextStyle(color: Colors.red, fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final booking = bookings[index];
                            return Card(
                              child: ListTile(
                                title: Text("Booking #${booking['id']}"),
                                subtitle: Text("Date: ${booking['date']}"),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const UserBottomNavbar(currentIndex: 1),
    );
  }
}
