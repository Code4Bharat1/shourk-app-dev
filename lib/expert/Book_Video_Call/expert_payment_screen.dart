import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatefulWidget {
  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool isWalletSelected = false;
  bool isPaypalSelected = false;
  bool isCreditDebitSelected = false;
  bool isNetBankingSelected = false;
  String? selectedBank;

  final List<String> bankOptions = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
  ];

  void openWallet() {
    // Add your wallet opening logic here
    print('Opening wallet...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening wallet...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Icon(Icons.arrow_back, color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment method title
            Text(
              'Payment method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),

            // Wallet Balance Container
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Left side image
                  Image.asset(
                    'assets/images/payment.png',
                    width: 180,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.account_balance_wallet, color: Colors.blue),
                      );
                    },
                  ),
                  SizedBox(width: 16),
                  // Right side text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Wallet Balance is-',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Center(
                          child: Text(
                            '\$500',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Wallet Payment Option
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Checkbox(
                    value: isWalletSelected,
                    onChanged: (value) {
                      setState(() {
                        isWalletSelected = value!;
                      });
                    },
                    activeColor: Colors.transparent,
                    checkColor: Colors.black,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Pay through your Wallet. ',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
                GestureDetector(
                  onTap: openWallet,
                  child: Text(
                    'Add Money to your Wallet',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // PayPal Option
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Checkbox(
                    value: isPaypalSelected,
                    onChanged: (value) {
                      setState(() {
                        isPaypalSelected = value!;
                      });
                    },
                    activeColor: Colors.transparent,
                    checkColor: Colors.black,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Paypal',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
                SizedBox(width: 8),
                Image.asset(
                  'assets/images/paypal.png',
                  width: 45,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 30,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text('PP', style: TextStyle(fontSize: 10, color: Colors.blue)),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),

            // Credit or Debit Card Option
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Checkbox(
                    value: isCreditDebitSelected,
                    onChanged: (value) {
                      setState(() {
                        isCreditDebitSelected = value!;
                      });
                    },
                    activeColor: Colors.transparent,
                    checkColor: Colors.black,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Credit or Debit Card',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Credit/Debit Card Images
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Image.asset(
                'assets/images/creditordebit.png',
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Row(
                    children: [
                      Container(
                        width: 40,
                        height: 25,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(child: Text('VISA', style: TextStyle(fontSize: 8))),
                      ),
                      Container(
                        width: 40,
                        height: 25,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(child: Text('MC', style: TextStyle(fontSize: 8))),
                      ),
                      Container(
                        width: 40,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(child: Text('AMEX', style: TextStyle(fontSize: 8))),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 20),

            // Net Banking Option
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Checkbox(
                    value: isNetBankingSelected,
                    onChanged: (value) {
                      setState(() {
                        isNetBankingSelected = value!;
                      });
                    },
                    activeColor: Colors.transparent,
                    checkColor: Colors.black,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Net Banking',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Dropdown for Net Banking
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBank,
                  hint: Text('View Options'),
                  isExpanded: true,
                  items: bankOptions.map((String bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Text(bank),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBank = newValue;
                    });
                  },
                ),
              ),
            ),
            
            Spacer(),

            // Pay Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Add payment logic here
                  print('Payment initiated');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Pay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
}
