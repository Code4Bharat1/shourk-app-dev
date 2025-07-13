// 📁 lib/screens/expert_search_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExpertSearchScreen extends StatefulWidget {
  const ExpertSearchScreen({Key? key}) : super(key: key);

  @override
  State<ExpertSearchScreen> createState() => _ExpertSearchScreenState();
}

class _ExpertSearchScreenState extends State<ExpertSearchScreen> {
  List<dynamic> topExperts = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTopExperts();
  }

  Future<void> fetchTopExperts() async {
    try {
      final response = await http.get(Uri.parse('https://shourkapi-dev.thedelvierypanda.com/api/user/top-experts'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          topExperts = data['experts'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load top experts');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFAF6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const TextField(
          decoration: InputDecoration(
            hintText: 'Search experts...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {})
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
              : topExperts.isEmpty
                  ? const Center(child: Text("No experts found"))
                  : Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Popular Experts',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: topExperts.length,
                              itemBuilder: (context, index) {
                                final expert = topExperts[index];
                                return ExpertCard(expert: expert);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class ExpertCard extends StatelessWidget {
  final Map<String, dynamic> expert;
  const ExpertCard({required this.expert, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              expert['image'] ?? '',
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 130,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.person, size: 40)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expert['name'] ?? 'Unnamed',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expert['description'] ?? 'No description available',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  "SAR ${expert['price'] ?? '0'}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}