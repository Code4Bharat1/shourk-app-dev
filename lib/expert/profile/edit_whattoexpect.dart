import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';

class EditWhatToExpectScreen extends StatefulWidget {
  const EditWhatToExpectScreen({super.key});

  @override
  State<EditWhatToExpectScreen> createState() => _EditWhatToExpectScreenState();
}

class _EditWhatToExpectScreenState extends State<EditWhatToExpectScreen> {
  final TextEditingController _example1Controller = TextEditingController();
  final TextEditingController _example2Controller = TextEditingController();
  final TextEditingController _example3Controller = TextEditingController();

  @override
  void dispose() {
    _example1Controller.dispose();
    _example2Controller.dispose();
    _example3Controller.dispose();
    super.dispose();
  }

  Widget _buildSessionSection({
    required String sessionTitle,
    required String exampleLabel,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Session Duration Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            sessionTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Example Label
        Text(
          exampleLabel,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        
        // Example Input Field
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "- Tap to add an example",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 3,
          minLines: 1,
        ),
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
          "Edit what to Expect",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // Main Title
            const Text(
              "What to expect",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              "Share examples of what can be accomplished during a session",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            
            // 15 minute session
            _buildSessionSection(
              sessionTitle: "15 minute session",
              exampleLabel: "Example #1",
              controller: _example1Controller,
            ),
            const SizedBox(height: 24),
            
            // 30 minute session
            _buildSessionSection(
              sessionTitle: "30 minute session",
              exampleLabel: "Example #2",
              controller: _example2Controller,
            ),
            const SizedBox(height: 24),
            
            // 45 minute session
            _buildSessionSection(
              sessionTitle: "45 minute session",
              exampleLabel: "Example #3",
              controller: _example3Controller,
            ),
            const SizedBox(height: 40),
            
            // Save Button (optional - you can remove if not needed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle save action here if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Examples saved!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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