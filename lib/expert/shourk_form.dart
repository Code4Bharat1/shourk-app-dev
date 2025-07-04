import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shourk_application/user/home/home_screen.dart';

class ShourkForm extends StatefulWidget {
  const ShourkForm({Key? key}) : super(key: key); 
  @override
  _ShourkFormState createState() => _ShourkFormState();
}

class _ShourkFormState extends State<ShourkForm> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController socialMediaController = TextEditingController();
  final TextEditingController expertiseController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController specificAreaController = TextEditingController();

  // Changed to PlatformFile for cross-platform compatibility
  PlatformFile? certificateFile;
  PlatformFile? professionalPhotoFile;
  String certificateFileName = 'No file selected';
  String professionalPhotoFileName = 'No file selected';
  
  String selectedAreaOfExpertise = 'Select Area';
  List<String> areaOfExpertiseOptions = [
    'Select Area',
    'Home',
    'Career and Business',
    'Style and Beauty',
    'Wellness',
    'Others'
  ];

  String selectedGender = 'Male';
  List<String> genderOptions = ['Male', 'Female'];

  bool isLoading = false;
  String phoneNumber = '';
  bool isPhoneValid = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickCertificateFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb, // Load file data for web
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          certificateFile = result.files.single;
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
        withData: kIsWeb, // Load file data for web
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          professionalPhotoFile = result.files.single;
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

  bool _validateForm() {
    if (firstNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your first name');
      return false;
    }
    if (lastNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your last name');
      return false;
    }
    if (phoneNumber.isEmpty || !isPhoneValid) {
      _showErrorSnackBar('Please enter a valid mobile number');
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email');
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }
    if (selectedAreaOfExpertise == 'Select Area') {
      _showErrorSnackBar('Please select your area of expertise');
      return false;
    }
    if (selectedAreaOfExpertise == 'Others' && specificAreaController.text.trim().isEmpty) {
      _showErrorSnackBar('Please specify your area of expertise');
      return false;
    }
    if (priceController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your price');
      return false;
    }
    if (expertiseController.text.trim().isEmpty) {
      _showErrorSnackBar('Please describe your expertise');
      return false;
    }
    if (experienceController.text.trim().isEmpty) {
      _showErrorSnackBar('Please describe your experience');
      return false;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // First, let's try without files to see if the text fields work
      bool hasFiles = certificateFile != null || professionalPhotoFile != null;
      
      if (hasFiles) {
        await _submitWithFiles();
      } else {
        await _submitWithoutFiles();
      }
    } catch (e) {
      print('Error submitting form: $e');
      
      String errorMessage = 'Network error. Please check your connection and try again.';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('HTML page')) {
        errorMessage = 'Server error. Please try again later or contact support.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network and try again.';
      } else if (e.toString().contains('Unexpected field')) {
        errorMessage = 'Server configuration error. Please contact support.';
      }
      
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitWithoutFiles() async {
    var response = await http.post(
      Uri.parse('https://amd-api.code4bharat.com/api/expertauth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phone': phoneNumber, // Changed from 'mobile'
        'email': emailController.text.trim(),
        'socialLink': socialMediaController.text.trim(), // Changed from 'socialMediaLink'
        'areaOfExpertise': selectedAreaOfExpertise,
        'price': priceController.text.trim(),
        'expertise': expertiseController.text.trim(),
        'experience': experienceController.text.trim(),
        'gender': selectedGender,
        'specificArea': selectedAreaOfExpertise == 'Others' 
            ? specificAreaController.text.trim()
            : null,
      }),
    );

    await _handleResponse(response);
  }

  Future<void> _submitWithFiles() async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5070/api/expertauth/register'),
    );

    // Add text fields with updated names
    request.fields['firstName'] = firstNameController.text.trim();
    request.fields['lastName'] = lastNameController.text.trim();
    request.fields['phone'] = phoneNumber; // Changed from 'mobile'
    request.fields['email'] = emailController.text.trim();
    request.fields['socialLink'] = socialMediaController.text.trim(); // Changed from 'socialMediaLink'
    request.fields['areaOfExpertise'] = selectedAreaOfExpertise;
    request.fields['price'] = priceController.text.trim();
    request.fields['expertise'] = expertiseController.text.trim();
    request.fields['experience'] = experienceController.text.trim();
    request.fields['gender'] = selectedGender;
    
    // Add specific area only when "Others" is selected
    if (selectedAreaOfExpertise == 'Others') {
      request.fields['specificArea'] = specificAreaController.text.trim();
    }

    // Add files with corrected field names
    if (certificateFile != null) {
      if (kIsWeb) {
        if (certificateFile!.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'certificationFile', // Corrected field name
              certificateFile!.bytes!,
              filename: certificateFile!.name,
            ),
          );
        }
      } else {
        if (certificateFile!.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'certificationFile', // Corrected field name
              certificateFile!.path!,
              filename: certificateFile!.name,
            ),
          );
        }
      }
    }

    if (professionalPhotoFile != null) {
      if (kIsWeb) {
        if (professionalPhotoFile!.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'photoFile', // Correct field name
              professionalPhotoFile!.bytes!,
              filename: professionalPhotoFile!.name,
            ),
          );
        }
      } else {
        if (professionalPhotoFile!.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photoFile', // Correct field name
              professionalPhotoFile!.path!,
              filename: professionalPhotoFile!.name,
            ),
          );
        }
      }
    }

    // Add headers
    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = 'Flutter App';

    print('Sending multipart request to: ${request.url}');
    print('Request fields: ${request.fields}');
    print('Request files: ${request.files.map((f) => f.field).toList()}');

    // Send request with timeout
    var streamedResponse = await request.send().timeout(
      Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Request timeout. Please check your internet connection.');
      },
    );
    
    var response = await http.Response.fromStream(streamedResponse);
    await _handleResponse(response);
  }

  Future<void> _handleResponse(http.Response response) async {
    print('Response status code: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    print('Response body: ${response.body}');

    // Check if response is HTML (error page)
    if (response.body.trim().startsWith('<!DOCTYPE') || 
        response.body.trim().startsWith('<html')) {
      if (response.body.contains('MulterError: Unexpected field')) {
        throw Exception('Unexpected field error - the server doesn\'t recognize one of the field names we\'re sending.');
      } else {
        throw Exception('Server returned an HTML page instead of JSON. This might indicate a server error or incorrect endpoint.');
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        var responseData = json.decode(response.body);
        _showSuccessSnackBar('Registration successful!');
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (jsonError) {
        print('JSON parsing error: $jsonError');
        _showErrorSnackBar('Registration might be successful, but received unexpected response format.');
      }
    } else {
      String errorMessage = 'Registration failed. Server returned status ${response.statusCode}.';
      
      try {
        var errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (jsonError) {
        if (response.body.isNotEmpty && response.body.length < 200) {
          errorMessage = 'Error: ${response.body}';
        }
      }
      
      _showErrorSnackBar(errorMessage);
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
            _buildLabel('First Name *'),
            _buildTextField(firstNameController),
            SizedBox(height: 20),
            
            // Last Name
            _buildLabel('Last Name *'),
            _buildTextField(lastNameController),
            SizedBox(height: 20),
            
            // Mobile Number with International Phone Field
            _buildLabel('Mobile Number *'),
            _buildPhoneNumberField(),
            SizedBox(height: 20),
            
            // Email
            _buildLabel('Email *'),
            _buildTextField(emailController, keyboardType: TextInputType.emailAddress),
            SizedBox(height: 20),
            
            // Gender
            _buildLabel('Gender *'),
            _buildGenderDropdown(),
            SizedBox(height: 20),
            
            // Social Media Link
            _buildLabel('Social Media Link'),
            _buildTextFieldWithIcon(socialMediaController, Icons.link),
            SizedBox(height: 20),
            
            // Area of Expertise Dropdown
            _buildLabel('Area of Expertise *'),
            _buildDropdownField(),
            SizedBox(height: 20),
            
            // Specific Area (Conditional)
            if (selectedAreaOfExpertise == 'Others')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Specify Area of Expertise *'),
                  _buildTextField(specificAreaController),
                  SizedBox(height: 20),
                ],
              ),
            
            // Price (in Riyals)
            _buildLabel('Price (in Riyals) *'),
            _buildTextField(priceController, keyboardType: TextInputType.number),
            SizedBox(height: 20),
            
            // Tell us your Expertise
            _buildLabel('Tell us your Expertise *'),
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
            _buildLabel('Experience *'),
            _buildTextFieldWithCounter(experienceController, 500),
            SizedBox(height: 40),
            
            // Submit Button
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  )
                ),
                child: isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      )
                    : Text(
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

  Widget _buildTextField(TextEditingController controller, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: IntlPhoneField(
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: 'Phone Number',
          hintStyle: TextStyle(color: Colors.grey[400]),
          counterText: '',
        ),
        style: TextStyle(fontSize: 14),
        initialCountryCode: 'SA',
        onChanged: (phone) {
          setState(() {
            phoneNumber = phone.completeNumber;
            isPhoneValid = phone.number.isNotEmpty;
          });
        },
        onCountryChanged: (country) {
          print('Country changed to: ${country.name}');
        },
        validator: (phone) {
          if (phone == null || phone.number.isEmpty) {
            return null;
          }
          return null;
        },
        dropdownIconPosition: IconPosition.trailing,
        dropdownIcon: Icon(
          Icons.arrow_drop_down,
          color: Colors.grey[600],
        ),
        flagsButtonPadding: EdgeInsets.only(left: 8),
        showCountryFlag: true,
        showDropdownIcon: true,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedGender,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          style: TextStyle(fontSize: 14, color: Colors.black),
          dropdownColor: Colors.white,
          items: genderOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedGender = newValue!;
            });
          },
        ),
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
    emailController.dispose();
    socialMediaController.dispose();
    expertiseController.dispose();
    priceController.dispose();
    experienceController.dispose();
    specificAreaController.dispose();
    super.dispose();
  }
}