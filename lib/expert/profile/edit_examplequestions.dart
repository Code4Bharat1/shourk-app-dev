import 'package:flutter/material.dart';

class EditExampleQuestionsScreen extends StatefulWidget {
  const EditExampleQuestionsScreen({super.key});

  @override
  State<EditExampleQuestionsScreen> createState() => _EditExampleQuestionsScreenState();
}

class _EditExampleQuestionsScreenState extends State<EditExampleQuestionsScreen> {
  List<TextEditingController> _questionControllers = [TextEditingController()];

  @override
  void dispose() {
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestion(int index) {
    if (_questionControllers.length > 1) {
      setState(() {
        _questionControllers[index].dispose();
        _questionControllers.removeAt(index);
      });
    }
  }

  Widget _buildQuestionField(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question #${index + 1}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            if (_questionControllers.length > 1)
              IconButton(
                onPressed: () => _removeQuestion(index),
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _questionControllers[index],
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
          "Edit example questions",
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
              "Example questions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              "Give the caller examples of questions people have asked",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            
            // Question Fields
            ...List.generate(
              _questionControllers.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildQuestionField(index),
              ),
            ),
            
            // Add Question Button
            GestureDetector(
              onTap: _addQuestion,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Add a question",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Save Button (optional)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle save action here if needed
                  List<String> questions = _questionControllers
                      .map((controller) => controller.text.trim())
                      .where((text) => text.isNotEmpty)
                      .toList();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved ${questions.length} questions!')),
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
    );
  }
}