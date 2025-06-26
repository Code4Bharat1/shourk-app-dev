import 'dart:async'; // Add this import for TimeoutException
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  // Get base URL based on platform
  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5070';
    } else if (Platform.isAndroid) {
      return 'http://193.203.160.238:5070';
    } else if (Platform.isIOS) {
      return 'http://localhost:5070';
    }
    return 'http://localhost:5070';
  }

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  // Validation methods
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
    final nameRegex = RegExp(r'^[A-Za-z]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters';
    }
    return null;
  }

  String? _validatePhone(PhoneNumber? phone) {
    if (phone == null || phone.completeNumber.isEmpty) {
      return 'Valid phone number is required';
    }
    return null;
  }

  Future<void> registerUser() async {
    // Clear previous server error
    setState(() {
      _serverError = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if phone number is provided
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _serverError = 'No internet connection. Please check your network.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = emailController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    final url = Uri.parse('${getBaseUrl()}/api/userauth/registeruser');
    print(" Registering user with URL: $url");
    final Map<String, dynamic> body = {
      'email': email,
      'phone': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
    };

    try {
      debugPrint("📤 Sending registration request to: $url");
      debugPrint("📤 Request body: $body");
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      debugPrint("📨 Response status: ${response.statusCode}");
      debugPrint("📨 Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint("✅ Registration Success: $data");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Registration failed (${response.statusCode})';
        
        setState(() {
          _serverError = errorMessage;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on SocketException {
      _handleNetworkError('Server unreachable. Check if backend is running');
    } on http.ClientException {
      _handleNetworkError('Connection refused by server');
    } on FormatException {
      _handleNetworkError('Invalid server response format');
    } on TimeoutException { // This is now properly recognized
      _handleNetworkError('Connection timed out. Please try again');
    } catch (e) {
      debugPrint("⚠️ FULL ERROR: $e");
      _handleNetworkError('Unknown error occurred: ${e.runtimeType}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleNetworkError(String message) {
    debugPrint("⚠️ NETWORK ERROR: $message");
    
    setState(() {
      _serverError = message;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Phone Number
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

              // Email
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
                onChanged: (value) {
                  if (_serverError != null) {
                    setState(() {
                      _serverError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // First Name
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
                  final filteredValue = value.replaceAll(RegExp(r'[^A-Za-z]'), '');
                  if (value != filteredValue) {
                    firstNameController.value = TextEditingValue(
                      text: filteredValue,
                      selection: TextSelection.collapsed(offset: filteredValue.length),
                    );
                  }
                  
                  if (_serverError != null) {
                    setState(() {
                      _serverError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Last Name
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
                  final filteredValue = value.replaceAll(RegExp(r'[^A-Za-z]'), '');
                  if (value != filteredValue) {
                    lastNameController.value = TextEditingValue(
                      text: filteredValue,
                      selection: TextSelection.collapsed(offset: filteredValue.length),
                    );
                  }
                  
                  if (_serverError != null) {
                    setState(() {
                      _serverError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Server Error Display
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

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : registerUser,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              
              // Required fields note
              const Text(
                "* Required fields",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
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