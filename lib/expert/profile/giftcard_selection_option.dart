import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/profile/expert_profile_screen.dart';

class GiftCardSelectPage extends StatefulWidget {
  const GiftCardSelectPage({super.key});

  @override
  State<GiftCardSelectPage> createState() => _GiftCardSelectPageState();
}

class _GiftCardSelectPageState extends State<GiftCardSelectPage> {
  String? selectedAmount;
  final List<String> predefinedAmounts = ['200', '500', '750', '1000'];
  final TextEditingController customAmountController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool showCustomField = false;

  bool get isContinueEnabled =>
      selectedAmount != null && emailController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final chipPadding = isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    return Scaffold(
      appBar: const ExpertUpperNavbar(),
      bottomNavigationBar: const ExpertBottomNavbar(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  const Text(
                    'Send a Gift Card',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gift a thoughtful session to a friend, family members or colleague.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 24),

            const Text('Choose Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Select a predefined amount or enter a custom value.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isSmallScreen ? 2 : 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.0,
              children: predefinedAmounts.map((amount) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAmount = amount;
                      showCustomField = false;
                      customAmountController.clear();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedAmount == amount && !showCustomField
                          ? Colors.blue[50]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedAmount == amount && !showCustomField
                            ? Colors.blue
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'SAR $amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: selectedAmount == amount && !showCustomField
                              ? Colors.blue
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showCustomField = !showCustomField;
                        if (!showCustomField) {
                          customAmountController.clear();
                          selectedAmount = null;
                        }
                      });
                    },
                    child: Container(
                      padding: chipPadding,
                      decoration: BoxDecoration(
                        color: showCustomField ? Colors.blue[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: showCustomField ? Colors.blue : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Custom Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: showCustomField ? Colors.blue : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showCustomField) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: customAmountController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          selectedAmount = value.isNotEmpty ? value : null;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        prefixText: 'SAR ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            const Text('Recipient Email*',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'recipient@example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Recipient Phone Number (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+1 (555) 123-4567',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Personalised Message (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Write a short message to the recipient',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isContinueEnabled
                    ? () => Navigator.pushNamed(context, '/gift-card-form')
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    customAmountController.dispose();
    emailController.dispose();
    phoneController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
