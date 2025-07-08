import 'package:flutter/material.dart';
import 'package:shourk_application/expert/Book_Video_Call/expert_payment_screen.dart';
import 'package:shourk_application/expert/profile/payment_option.dart';

class ExpertBookingScreen extends StatefulWidget {
  const ExpertBookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<ExpertBookingScreen> {
  // Controllers for text fields
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController promoCodeController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Selected time slot tracking
  String? selectedTimeSlot;
  String? selectedDate;

  // Loading state
  bool isBooking = false;
  bool isApplyingPromo = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form fields - make these dynamic based on logged-in user
    firstNameController.text;
    lastNameController.text;
    mobileController.text;
    emailController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header greeting
                const Text(
                  "Hi, Ayaan Raje", // Make this dynamic based on logged-in user
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // Page title
                const Text(
                  "Booking",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Expert profile image - OUTSIDE the colored container
                Center(
                  child: Container(
                    width: 350,
                    height: 383,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          Colors
                              .white, // White background for left and right sides
                      borderRadius: BorderRadius.circular(12),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: Colors.black.withOpacity(0.1),
                      //     blurRadius: 8,
                      //     offset: const Offset(0, 2),
                      //   ),
                      // ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/arab_men.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white,
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Expert details section
                Container(
                  color: const Color(0xFFF8F7F3),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expert name - aligned left
                      const Text(
                        "Darrell Steward",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Expert profession - aligned left
                      const Text(
                        "Tech Entrepreneur + Investor",
                        style: TextStyle(
                          color: Color(0xFF9C9C9C),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sessions section
                      const Text(
                        "Sessions-",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Thursday sessions
                      const Text(
                        "Thu, 27 Feb",
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      // Time slots for Thursday
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeSlot(
                              "08:00 AM-08:15 AM",
                              "Thu, 27 Feb",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimeSlot(
                              "08:20 AM-08:35 AM",
                              "Thu, 27 Feb",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Friday sessions
                      const Text(
                        "Fri, 28 Feb",
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      // Time slots for Friday
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeSlot(
                              "08:00 AM-08:15 AM",
                              "Fri, 28 Feb",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimeSlot(
                              "09:00 AM-09:15 AM",
                              "Fri, 28 Feb",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Additional time slot
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.45,
                        child: _buildTimeSlot(
                          "09:20 AM-09:35 AM",
                          "Fri, 28 Feb",
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Important note
                      const Text(
                        "Note - Can add up to 5 sessions at different time slots. Any 1 timeslot might get selected.",
                        style: TextStyle(
                          color: Color(0xFFFE3232),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form fields container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Change button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            // Add logic to change user details or navigate to profile
                            _showSnackBar("Change profile functionality");
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Change",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // First Name field
                      _buildTextFormField(
                        label: "First Name",
                        controller: firstNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Last Name field
                      _buildTextFormField(
                        label: "Last Name",
                        controller: lastNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mobile Number field
                      _buildTextFormField(
                        label: "Mobile Number",
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          // Basic phone number validation
                          if (value.length < 10) {
                            return 'Please enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email field
                      _buildTextFormField(
                        label: "Email",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          // Basic email validation
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Centered Promo Code Section with reduced width
                Center(
                  child: Container(
                    width: 320, // Set your desired width here
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: promoCodeController,
                            decoration: const InputDecoration(
                              hintText: "Add a promo code",
                              hintStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _handleApplyPromo,
                          child:
                              isApplyingPromo
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                  : const Text(
                                    "Apply",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Book Button
                Container(
                  width: 500, // or any specific width you prefer
                  alignment: Alignment.center, // centers the button
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentMethodScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child:
                        isBooking
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "            Book            ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build time slot widgets
  Widget _buildTimeSlot(String timeSlot, String date) {
    bool isSelected = selectedTimeSlot == timeSlot && selectedDate == date;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimeSlot = timeSlot;
          selectedDate = date;
        });
        print("Selected: $timeSlot on $date");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : const Color(0x4D000000),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          timeSlot,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Helper method to build text form fields
  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Handle promo code application
  void _handleApplyPromo() async {
    if (promoCodeController.text.isEmpty) {
      _showSnackBar("Please enter a promo code");
      return;
    }

    setState(() {
      isApplyingPromo = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Here you would make your actual API call to validate promo code
      print("Applying promo code: ${promoCodeController.text}");

      // Simulate success/failure
      if (promoCodeController.text.toLowerCase() == "save10") {
        _showSnackBar("Promo code applied successfully! 10% discount added.");
      } else {
        _showSnackBar("Invalid promo code. Please try again.");
      }
    } catch (error) {
      _showSnackBar("Failed to apply promo code. Please try again.");
    } finally {
      setState(() {
        isApplyingPromo = false;
      });
    }
  }

  // Enhanced booking logic
  void _handleBooking() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if time slot is selected
    if (selectedTimeSlot == null || selectedDate == null) {
      _showSnackBar("Please select a time slot");
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Here you would make your actual API call
      print("Booking Details:");
      print("Name: ${firstNameController.text} ${lastNameController.text}");
      print("Mobile: ${mobileController.text}");
      print("Email: ${emailController.text}");
      print("Selected Time Slot: $selectedTimeSlot on $selectedDate");
      print("Promo Code: ${promoCodeController.text}");

      _showSnackBar("Booking confirmed successfully!");

      // Optionally navigate to confirmation screen
      // Navigator.pushNamed(context, '/booking-confirmation');
    } catch (error) {
      _showSnackBar("Booking failed. Please try again.");
    } finally {
      setState(() {
        isBooking = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    promoCodeController.dispose();
    super.dispose();
  }
}
