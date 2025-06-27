import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:shourk_application/user/home/home_screen.dart';

class AMDFormScreen extends StatefulWidget {
  const AMDFormScreen({Key? key}) : super(key: key); 
  @override
  _AMDFormScreenState createState() => _AMDFormScreenState();
}

class _AMDFormScreenState extends State<AMDFormScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController socialMediaController = TextEditingController();
  final TextEditingController expertiseController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  File? certificateFile;
  File? professionalPhotoFile;
  String certificateFileName = 'No file selected';
  String professionalPhotoFileName = 'No file selected';
  
  String selectedAreaOfExpertise = 'Select Area';
  List<String> areaOfExpertiseOptions = [
    'Select Area',
    'Home',
    'Career and Business',
    'Style and Beauty',
    'Wellness'
  ];

  @override
  void initState() {
    super.initState();
    firstNameController.text = "Ayaan";
    lastNameController.text = "Raja";
    mobileController.text = "+919124245630";
    emailController.text = "ayaanrajk25@gmail.com";
  }

  Future<void> _pickCertificateFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          certificateFile = File(result.files.single.path!);
          certificateFileName = result.files.single.name;
        });
      }
    } catch (e) {
      print("Error picking certificate file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _pickPhotoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          professionalPhotoFile = File(result.files.single.path!);
          professionalPhotoFileName = result.files.single.name;
        });
      }
    } catch (e) {
      print("Error picking photo file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SHOURK',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Center(
              child: Text(
                'Please Enter Your Info',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 30),
            
            // First Name
            _buildLabel('First Name'),
            _buildTextField(firstNameController),
            SizedBox(height: 20),
            
            // Last Name
            _buildLabel('Last Name'),
            _buildTextField(lastNameController),
            SizedBox(height: 20),
            
            // Mobile Number
            _buildLabel('Mobile Number'),
            _buildTextField(mobileController),
            SizedBox(height: 20),
            
            // Email
            _buildLabel('Email'),
            _buildTextField(emailController),
            SizedBox(height: 20),
            
            // Social Media Link
            _buildLabel('Social Media Link'),
            _buildTextFieldWithIcon(socialMediaController, Icons.link),
            SizedBox(height: 20),
            
            // Area of Expertise Dropdown
            _buildLabel('Area of Expertise'),
            _buildDropdownField(),
            SizedBox(height: 20),
            
            // Price (in Riyals)
            _buildLabel('Price (in Riyals)'),
            _buildTextField(priceController),
            SizedBox(height: 20),
            
            // Tell us your Expertise
            _buildLabel('Tell us your Expertise'),
            _buildTextFieldWithCounter(expertiseController, 500),
            SizedBox(height: 20),
            
            // Professional Certificate
            _buildLabel('Professional Certificate'),
            _buildUploadField(
              certificateFileName,
              _pickCertificateFile,
            ),
            SizedBox(height: 20),
            
            // Professional Photos
            _buildLabel('Professional Photos'),
            _buildUploadField(
              professionalPhotoFileName,
              _pickPhotoFile,
            ),
            SizedBox(height: 20),
            
            // Experience
            _buildLabel('Experience'),
            _buildTextFieldWithCounter(experienceController, 500),
            SizedBox(height: 40),
            
            // Submit Button
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => HomeScreen())
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedAreaOfExpertise,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          style: TextStyle(fontSize: 14, color: Colors.black),
          dropdownColor: Colors.white,
          items: areaOfExpertiseOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  value,
                  style: TextStyle(
                    color: value == 'Select Area' ? Colors.grey[400] : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedAreaOfExpertise = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTextFieldWithIcon(TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: Icon(icon, color: Colors.grey[600], size: 20),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildTextFieldWithCounter(TextEditingController controller, int maxLength) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLines: 3,
            maxLength: maxLength,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintStyle: TextStyle(color: Colors.grey[400]),
              counterText: '',
            ),
            style: TextStyle(fontSize: 14),
            onChanged: (text) {
              setState(() {});
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${controller.text.length}/$maxLength',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadField(String fileName, VoidCallback onPressed) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 14,
                  color: fileName == 'No file selected' 
                      ? Colors.grey[400]
                      : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(6),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: Size(70, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Upload',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    socialMediaController.dispose();
    expertiseController.dispose();
    priceController.dispose();
    experienceController.dispose();
    super.dispose();
  }
}