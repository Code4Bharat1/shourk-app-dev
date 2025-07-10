// payment_card.dart
import 'package:flutter/material.dart';
import 'package:shourk_application/expert/profile/expert_profile_screen.dart';

class PaymentCardPage extends StatefulWidget {
  final double amount;
  const PaymentCardPage({super.key, required this.amount});

  @override
  State<PaymentCardPage> createState() => _PaymentCardPageState();
}

class _PaymentCardPageState extends State<PaymentCardPage> {
  final _formKey = GlobalKey<FormState>();
  String brand = 'mada';
  String cardNumber = '';
  String expiryDate = '';
  String cardHolder = '';
  String cvv = '';

  void _submitPayment() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Redirecting..."),
          content: const Text("Request sent to admin and will be confirmed soon."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ExpertProfilePage()),
                (route) => false,
              ),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    Future.delayed(
      const Duration(milliseconds: 400),
      () => showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Redirecting..."),
          content: Text("You are being redirected to the payment page."),
        ),
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Form"),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: brand,
                items: const [
                  DropdownMenuItem(value: 'mada', child: Text('mada')),
                  DropdownMenuItem(value: 'visa', child: Text('visa')),
                  DropdownMenuItem(value: 'mastercard', child: Text('mastercard')),
                ],
                onChanged: (value) => setState(() => brand = value!),
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
                validator: (val) => val != null && val.length < 16 ? 'Invalid card number' : null,
                onSaved: (val) => cardNumber = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Expiry Date (MM / YY)'),
                validator: (val) => val == null || val.isEmpty ? 'Invalid expiry date' : null,
                onSaved: (val) => expiryDate = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Card holder'),
                validator: (val) => val == null || val.isEmpty ? 'Card holder required' : null,
                onSaved: (val) => cardHolder = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'CVV'),
                obscureText: true,
                keyboardType: TextInputType.number,
                validator: (val) => val != null && val.length < 3 ? 'Invalid CVV' : null,
                onSaved: (val) => cvv = val ?? '',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitPayment,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Pay now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
