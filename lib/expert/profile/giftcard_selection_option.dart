import 'package:flutter/material.dart';

class GiftCardSelectPage extends StatelessWidget {
  const GiftCardSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final amounts = ['\$200', '\$500', '\$750', '\$1000', '\$Custom'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Card'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send a gift card', style: TextStyle(fontSize: 18)),
            const Text("Gift a session to a friend, family, or coworker",
                style: TextStyle(color: Colors.blue)),
            const SizedBox(height: 20),
            const Text('Buy a giftcard'),
            const Text('Please select an amount'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: amounts
                  .map((amt) => ChoiceChip(
                        label: Text(amt),
                        selected: amt == '\$750',
                        onSelected: (_) {},
                      ))
                  .toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/gift-card-form');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}