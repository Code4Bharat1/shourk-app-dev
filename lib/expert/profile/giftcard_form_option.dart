import 'package:flutter/material.dart';

class GiftCardFormPage extends StatelessWidget {
  const GiftCardFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Card'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text('Send a gift card', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ...['Recipient Email', 'Recipient Phone Number', 'Card Number', 'Expiry Date(MM/YY)', 'Card Holder Name', 'Personalized Message (Optional)']
                .map((label) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: label,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    )),
            CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text("Send Anonymously"),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Buy'),
            )
          ],
        ),
      ),
    );
  }
}
