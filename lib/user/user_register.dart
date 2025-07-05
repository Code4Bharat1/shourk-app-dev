import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shourk_application/user/home/home_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  String phoneNumber = '';
  String countryCode = '';
  bool _isLoading = false;
  String? _serverError;

  // API endpoint
  static const String apiUrl = 'http://localhost:5070/api/userauth/registeruser';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        emailController.text = prefs.getString('registration_email') ?? '';
        firstNameController.text = prefs.getString('registration_firstName') ?? '';
        lastNameController.text = prefs.getString('registration_lastName') ?? '';
        phoneNumber = prefs.getString('registration_phoneNumber') ?? '';
        countryCode = prefs.getString('registration_countryCode') ?? '';
      });
    } catch (e) {
      print('Error loading saved data: $e');
    }
  }

  Future<bool> _saveRegistrationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('registration_email', emailController.text.trim());
      await prefs.setString('registration_firstName', firstNameController.text.trim());
      await prefs.setString('registration_lastName', lastNameController.text.trim());
      await prefs.setString('registration_phoneNumber', phoneNumber);
      await prefs.setString('registration_countryCode', countryCode);
      await prefs.setString('registration_timestamp', DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      print('Error saving registration data: $e');
      return false;
    }
  }

  static Future<Map<String, String?>> getSavedRegistrationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'email': prefs.getString('registration_email'),
        'firstName': prefs.getString('registration_firstName'),
        'lastName': prefs.getString('registration_lastName'),
        'phoneNumber': prefs.getString('registration_phoneNumber'),
        'countryCode': prefs.getString('registration_countryCode'),
        'timestamp': prefs.getString('registration_timestamp'),
      };
    } catch (e) {
      print('Error getting saved registration data: $e');
      return {};
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final nameRegex = RegExp(r'^[A-Za-z\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters and spaces';
    }
    return null;
  }

  String? _validatePhone(PhoneNumber? phone) {
    if (phone == null || phone.completeNumber.isEmpty) {
      return 'Valid phone number is required';
    }
    if (phone.number.length < 7) {
      return 'Phone number too short';
    }
    return null;
  }

  Future<Map<String, dynamic>> _registerUser() async {
    try {
      final Map<String, dynamic> requestBody = {
        'email': emailController.text.trim(),
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
      };

      print('Sending registration request: $requestBody');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Registration successful'
        };
      } else {
        // Handle different error status codes
        String errorMessage = 'Registration failed';
        
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Unknown error occurred';
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
        }

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timed out. Please check your internet connection and try again.'
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection.'
      };
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}'
      };
    }
  }

  Future<void> saveAndContinue() async {
    setState(() {
      _serverError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Make API call to register user
      final registrationResult = await _registerUser();

      if (registrationResult['success']) {
        // Save registration data locally after successful API call
        bool saved = await _saveRegistrationData();

        if (saved) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            await Future.delayed(const Duration(seconds: 1));

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        } else {
          throw Exception('Failed to save registration data locally');
        }
      } else {
        // Handle registration failure
        setState(() {
          _serverError = registrationResult['message'] ?? 'Registration failed';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(registrationResult['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverError = 'Registration failed: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Shourk'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Please Enter Your Info",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              const Text("Phone Number *"),
              const SizedBox(height: 8),
              IntlPhoneField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                initialCountryCode: 'SA',
                validator: _validatePhone,
                onChanged: (phone) {
                  setState(() {
                    phoneNumber = phone.completeNumber;
                    countryCode = phone.countryCode;
                  });
                },
                onCountryChanged: (country) {
                  setState(() {
                    countryCode = country.code;
                  });
                },
              ),
              const SizedBox(height: 20),

              const Text("Email Address *"),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                decoration: InputDecoration(
                  hintText: "Enter your email address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text("First Name *"),
              const SizedBox(height: 8),
              TextFormField(
                controller: firstNameController,
                validator: (value) => _validateName(value, 'First name'),
                decoration: InputDecoration(
                  hintText: "Enter your first name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                onChanged: (value) {
                  final filteredValue = value.replaceAll(
                    RegExp(r'[^A-Za-z\s]'),
                    '',
                  );
                  if (value != filteredValue) {
                    firstNameController.value = TextEditingValue(
                      text: filteredValue,
                      selection: TextSelection.collapsed(
                        offset: filteredValue.length,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),

              const Text("Last Name *"),
              const SizedBox(height: 8),
              TextFormField(
                controller: lastNameController,
                validator: (value) => _validateName(value, 'Last name'),
                decoration: InputDecoration(
                  hintText: "Enter your last name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                onChanged: (value) {
                  final filteredValue = value.replaceAll(
                    RegExp(r'[^A-Za-z\s]'),
                    '',
                  );
                  if (value != filteredValue) {
                    lastNameController.value = TextEditingValue(
                      text: filteredValue,
                      selection: TextSelection.collapsed(
                        offset: filteredValue.length,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),

              if (_serverError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _serverError!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "* Required fields",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}