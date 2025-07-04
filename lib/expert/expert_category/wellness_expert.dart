import 'package:flutter/material.dart';
import 'package:shourk_application/shared/models/expert_model.dart';
import 'package:shourk_application/shared/widgets/expert_card.dart';
import 'package:shourk_application/expert/expert_category/top_expert.dart';
import 'package:shourk_application/expert/expert_category/home_expert.dart';
import 'package:shourk_application/expert/expert_category/career_expert.dart';
import 'package:shourk_application/expert/expert_category/fashion_expert.dart';

class WellnessExpertsScreen extends StatefulWidget {
  const WellnessExpertsScreen({super.key});

  @override
  State<WellnessExpertsScreen> createState() => _WellnessExpertsScreenState();
}

class _WellnessExpertsScreenState extends State<WellnessExpertsScreen> {
  String selectedFilter = 'Recommended';

  final List<Map<String, dynamic>> categories = [
    {'label': 'Top Experts', 'image': 'assets/images/img2.jpg', 'route': const TopExpertsScreen()},
    {'label': 'Home', 'image': 'assets/images/home.jpg', 'route': const HomeExpertsScreen()},
    {'label': 'Career and Business', 'image': 'assets/images/career.jpg', 'route': const CareerExpertsScreen()},
    {'label': 'Fashion & Beauty', 'image': 'assets/images/fashion.jpg', 'route': const FashionBeautyExpertsScreen()},
    {'label': 'Wellness', 'image': 'assets/images/wellness.jpg', 'route': const WellnessExpertsScreen()},
  ];

  List<ExpertModel> getFilteredExperts() {
    List<ExpertModel> experts = dummyExperts
    .where((expert) => expert.category.toLowerCase() == 'wellness')
    .toList();

    switch (selectedFilter) {
      case 'Price High - Low':
        experts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Price Low - High':
        experts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Highest Rating':
        experts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Most Reviewed':
        experts.sort((a, b) => b.reviews.length.compareTo(a.reviews.length));
        break;
    }

    return experts;
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Recommended'),
            _buildFilterOption('Price High - Low'),
            _buildFilterOption('Price Low - High'),
            _buildFilterOption('Highest Rating'),
            _buildFilterOption('Most Reviewed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title) {
    return RadioListTile<String>(
      title: Text(title),
      value: title,
      groupValue: selectedFilter,
      onChanged: (value) {
        setState(() {
          selectedFilter = value!;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final experts = getFilteredExperts();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Shourk", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        actions: const [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 8),
          Icon(Icons.filter_alt_outlined, color: Colors.black),
          SizedBox(width: 12),
          Icon(Icons.person_outline, color: Colors.black),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  "Find The Right Expert In Seconds!",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _openFilterDialog,
                  icon: const Icon(Icons.filter_alt_outlined, size: 18),
                  label: const Text("Filter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              ],
            ),
          ),

          // Category Tabs
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat['label'] == 'Wellness';

                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => cat['route']),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                      boxShadow: [
                        if (isSelected)
                          const BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          )
                      ],
                      image: DecorationImage(
                        image: AssetImage(cat['image']),
                        fit: BoxFit.cover,
                        colorFilter: const ColorFilter.mode(Colors.black38, BlendMode.darken),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat['label'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Page Heading
          const Center(
            child: Column(
              children: [
                Text("Wellness Experts",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("Physical & emotional wellness starts here",
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Expert Cards - Grid Layout (2 per row)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Adjust this ratio based on your ExpertCard height
              ),
              itemCount: experts.length,
              itemBuilder: (context, index) {
                return ExpertCard(expert: experts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}