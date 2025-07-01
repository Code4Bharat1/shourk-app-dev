import 'package:flutter/material.dart';

class PaymentMethodPage extends StatelessWidget {
  const PaymentMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment method'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text.rich(
                TextSpan(
                  text: 'Pay through your Wallet. ',
                  children: [
                    TextSpan(
                      text: 'Add Money to your Wallet',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text('Paypal'),
              secondary: Image.network('https://www.paypalobjects.com/webstatic/mktg/logo/pp_cc_mark_111x69.jpg', width: 40),
            ),
            CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text('Credit or Debit Card'),
              secondary: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/Visa.svg/1200px-Visa.svg.png', width: 40),
            ),
            const SizedBox(height: 10),
            const Text('Net Banking'),
            const SizedBox(height: 6),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('View Options'),
              items: ['SBI', 'HDFC', 'ICICI']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }
}