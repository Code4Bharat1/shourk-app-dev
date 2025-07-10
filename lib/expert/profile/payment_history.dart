import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final List<Transaction> transactions = [
    Transaction(
      id: 'bdda35',
      amount: 100.00,
      service: 'Full consultation',
      date: DateTime(2025, 7, 8, 11, 40),
      status: 'HYPERPAY PENDING',
      isCompleted: false,
    ),
    Transaction(
      id: '9920b9',
      amount: 100.00,
      service: 'Full consultation',
      date: DateTime(2025, 7, 8, 12, 2),
      status: 'HYPERPAY PENDING',
      isCompleted: false,
    ),
    Transaction(
      amount: 200.00,
      service: 'Full consultation',
      date: DateTime(2025, 6, 23, 14, 22),
      status: 'WALLET COMPLETED',
      isCompleted: true,
    ),
    Transaction(
      amount: 1000.00,
      service: 'Full consultation',
      date: DateTime(2025, 6, 23, 14, 7),
      status: 'HYPERPAY COMPLETED',
      isCompleted: true,
    ),
    Transaction(
      amount: 1000.00,
      service: 'Full consultation',
      date: DateTime(2025, 6, 23, 12, 41),
      status: 'HYPERPAY PENDING',
      isCompleted: false,
    ),
    // Add more transactions as needed
  ];

  double get totalAmount {
    return transactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shourk'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // User info section
          _buildUserInfoSection(),
          
          // URL section
          _buildUrlSection(),
          
          // Transactions list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionCard(transactions[index]);
              },
            ),
          ),
          
          // Total section
          _buildTotalSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildUserInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi, Aks', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 4),
                  Text('Profile', style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  )),
                ],
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1),
        ],
      ),
    );
  }

  Widget _buildUrlSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'shourk.com/expertpanel/expertpanelpr...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {},
            child: const Text('Download', style: TextStyle(fontSize: 14)),
          ),
          const Text('|', style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () {},
            child: const Text('Node.js', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
    
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: transaction.isCompleted 
                  ? Colors.green[100] 
                  : Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: transaction.isCompleted
                ? const Icon(Icons.check, color: Colors.green, size: 24)
                : const SizedBox.shrink(),
            ),
            
            const SizedBox(width: 16),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID if exists
                  if (transaction.id != null) ...[
                    Text(
                      transaction.id!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Service type
                  Row(
                    children: [
                      if (!transaction.isCompleted)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (!transaction.isCompleted) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.service,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Amount
                  Row(
                    children: [
                      const Text(
                        'SAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction.amount.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Date and time
                  Text(
                    '${dateFormat.format(transaction.date)}  ${timeFormat.format(transaction.date)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Payment status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.status.split(' ')[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.status.split(' ')[1],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transaction.status.contains('COMPLETED')
                      ? Colors.green
                      : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${transactions.length} transactions',
            style: const TextStyle(fontSize: 16),
          ),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Total: SAR ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: totalAmount.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('Search', Icons.search),
          _buildNavItem('Video', Icons.video_library),
          _buildNavItem('Profile', Icons.person, isActive: true),
          _buildNavItem('Expert', Icons.work),
          _buildNavItem('Dashboard', Icons.dashboard),
          _buildNavItem('Logout', Icons.logout),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24,
          color: isActive ? Colors.blue : Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }
}

class Transaction {
  final String? id;
  final double amount;
  final String service;
  final DateTime date;
  final String status;
  final bool isCompleted;

  Transaction({
    this.id,
    required this.amount,
    required this.service,
    required this.date,
    required this.status,
    required this.isCompleted,
  });
}