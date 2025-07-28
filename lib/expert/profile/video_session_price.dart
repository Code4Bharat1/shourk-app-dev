import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';

class VideoSessionPricePage extends StatefulWidget {
  const VideoSessionPricePage({super.key});

  @override
  State<VideoSessionPricePage> createState() => _VideoSessionPricePageState();
}

class _VideoSessionPricePageState extends State<VideoSessionPricePage> {
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _priceFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _token;
  String? _expertId;
  double _currentPrice = 500.0;
  
  // Environment configuration
  static const String _baseUrl = 'http://192.168.0.123:5070'; // Replace with your actual API URL
  
  @override
  void initState() {
    super.initState();
    _loadTokenAndExpertId();
  }

  Future<void> _loadTokenAndExpertId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('expertToken');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No token found. Please login again.')),
      );
      Navigator.pop(context);
      return;
    }

    final decodedToken = JwtDecoder.decode(token);
    final expertId = decodedToken['_id'];

    setState(() {
      _token = token;
      _expertId = expertId;
    });

    _fetchCurrentPrice();
  }

  Future<void> _fetchCurrentPrice() async {
    if (_token == null || _expertId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/expertauth/$_expertId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentPrice = (data['price'] ?? 500.0).toDouble();
          _priceController.text = _currentPrice.toStringAsFixed(0);
        });
      } else {
        _showErrorSnackbar('Failed to fetch current price');
      }
    } catch (error) {
      _showErrorSnackbar('Error fetching price: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrice() async {
    if (_token == null || _expertId == null) {
      _showErrorSnackbar('Authentication required');
      return;
    }

    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      _showErrorSnackbar('Please enter a price');
      return;
    }

    final priceValue = double.tryParse(priceText);
    if (priceValue == null || priceValue <= 0) {
      _showErrorSnackbar('Please enter a valid price');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/expertauth/update-price'),
        headers: {
          'Authorization': 'Bearer $_token',
          'expertid': _expertId!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'price': priceValue,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentPrice = priceValue;
        });
        _showSuccessSnackbar('Price updated successfully!');
        
        // Optional: Navigate back after successful update
        // Navigator.pop(context);
      } else {
        _showErrorSnackbar('Failed to update price');
      }
    } catch (error) {
      _showErrorSnackbar('Error updating price: $error');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '1:1 Video session prices',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main title
                  Text(
                    'Set your rates',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Description
                  Text(
                    'Set your price for a 15 minute video call or a group call & we\'ll calculate the rest',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // Your Base Price section
                  Text(
                    'Your Base Price',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Price input section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // SAR text
                      Text(
                        'SAR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 16),
                      
                      // Price input field
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green[200]!,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _priceController,
                            focusNode: _priceFocusNode,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '500',
                              hintStyle: TextStyle(
                                fontSize: 24,
                                color: Colors.grey[500],
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      
                      // /15 minutes text
                      Text(
                        '/15\nminutes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  
                  // Save Base Price Button
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updatePrice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Save Base Price',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  // Spacer to push content up
                  Spacer(),
                  
                  // Optional: Show current saved price
                  if (_currentPrice > 0)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Current saved price: SAR ${_currentPrice.toStringAsFixed(0)} per 15 minutes',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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