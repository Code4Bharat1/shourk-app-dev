import 'package:flutter/material.dart';
import 'package:shourk_application/expert/layout/expert_scaffold.dart';
import './payment_card.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  final TextEditingController _spendingAmountController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController();

  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  int withdrawStep = 0;
  String selectedMethod = 'Bank Transfer';
  double earningsBalance = 8540;
  double spendingBalance = 7500;

  void _showWithdrawDialog() {
    withdrawStep = 0;
    _withdrawAmountController.clear();
    _accountHolderController.clear();
    _accountNumberController.clear();
    _ibanController.clear();
    _bankNameController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          Widget content;

          switch (withdrawStep) {
            case 0:
              content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Withdrawal Amount", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _withdrawAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter amount',
                      suffixText: 'SAR',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Available: $earningsBalance SAR    Minimum: 10 SAR", style: TextStyle(color: Colors.grey)),
                ],
              );
              break;
            case 1:
              content = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Withdrawal Method", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  RadioListTile(
                    value: 'Bank Transfer',
                    groupValue: selectedMethod,
                    onChanged: (val) {
                      setModalState(() => selectedMethod = val.toString());
                    },
                    title: const Text("Bank Transfer"),
                    subtitle: const Text("Transfer directly to your bank account. Processing time: 5–7 business days."),
                  ),
                ],
              );
              break;
            case 2:
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField("Account Holder Name", _accountHolderController),
                  _textField("Account Number", _accountNumberController),
                  _textField("IBAN / Routing Number", _ibanController),
                  _textField("Bank Name", _bankNameController),
                ],
              );
              break;
            default:
              content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Confirm Withdrawal", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _confirmRow("Amount", "${_withdrawAmountController.text} SAR"),
                  _confirmRow("Method", selectedMethod),
                  _confirmRow("Account", _accountHolderController.text),
                  _confirmRow("Bank", _bankNameController.text),
                  _confirmRow("Account Number", "****${_accountNumberController.text.substring(_accountNumberController.text.length - 4)}"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "This withdrawal amount qualifies for automatic approval. Funds should be processed within 5–7 business days.",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              );
          }

          return AlertDialog(
            title: const Text("Withdraw Funds"),
            content: SingleChildScrollView(child: content),
            actions: [
              if (withdrawStep > 0)
                TextButton(
                  onPressed: () => setModalState(() => withdrawStep--),
                  child: const Text("Back"),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              if (withdrawStep < 3)
                ElevatedButton(
                  onPressed: () => setModalState(() => withdrawStep++),
                  child: const Text("Continue"),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Withdrawal submitted successfully!")),
                    );
                  },
                  child: const Text("Submit Withdrawal"),
                )
            ],
          );
        });
      },
    );
  }

  void _showWalletHistory() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Earning Wallet History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (_, index) {
              return ListTile(
                title: Text("6/30/2025, ${10 + index}:00 AM"),
                subtitle: const Text("Quick - 15min"),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpertScaffold(
      currentIndex: 2, // Highlight bottom nav tab
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Manage your wallet, payments and withdrawals", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            _walletCard(
              title: "Earning Wallet Balance",
              amount: earningsBalance,
              showWithdraw: true,
              onWithdraw: _showWithdrawDialog,
              onHistory: _showWalletHistory,
            ),
            const SizedBox(height: 20),

            _walletCard(
              title: "Spending Wallet Balance",
              amount: spendingBalance,
              onHistory: _showWalletHistory,
            ),

            const SizedBox(height: 20),
            const Text("Add Money to Spending Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("Amount (Minimum 10 SAR)"),
            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _spendingAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Enter amount",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text("SAR"),
              ],
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Add Money"),
              onPressed: () {
                final amount = double.tryParse(_spendingAmountController.text.trim()) ?? 0;
                if (amount >= 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Redirecting to payment page...")),
                  );
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PaymentCardPage(amount: amount)),
                    );
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Minimum amount is 10 SAR")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                backgroundColor: Colors.blue[700],
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              "Funds will be available immediately after successful payment. You can use your wallet balance for all services on the platform.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletCard({
    required String title,
    required double amount,
    VoidCallback? onWithdraw,
    VoidCallback? onHistory,
    bool showWithdraw = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: showWithdraw ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("$amount SAR", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (showWithdraw)
                ElevatedButton(
                  onPressed: onWithdraw,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Withdraw"),
                ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onHistory,
                child: const Text("View History"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
