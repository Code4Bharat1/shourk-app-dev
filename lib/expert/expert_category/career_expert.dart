import 'package:flutter/material.dart';
import 'package:shourk_application/shared/models/expert_model.dart';
import 'package:shourk_application/shared/widgets/expert_card.dart';

class CareerExpertsScreen extends StatefulWidget {
  const CareerExpertsScreen({super.key});

  @override
  State<CareerExpertsScreen> createState() => _CareerExpertsScreenState();
}

class _CareerExpertsScreenState extends State<CareerExpertsScreen> {
  String selectedFilter = 'Recommended';

  List<ExpertModel> getFilteredExperts() {
    List<ExpertModel> experts =
        dummyExperts.where((expert) => expert.title.contains('Career')).toList();

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

  final categories = [
    {'label': 'Top Experts', 'route': '/top-experts', 'image': 'assets/images/top.jpg'},
    {'label': 'Home', 'route': '/home-experts', 'image': 'assets/images/home.jpg'},
    {'label': 'Career and Business', 'route': '/career-experts', 'image': 'assets/images/career.jpg'},
    {'label': 'Fashion & Beauty', 'route': '/fashion-experts', 'image': 'assets/images/fashion.jpg'},
    {'label': 'Wellness', 'route': '/wellness-experts', 'image': 'assets/images/wellness.jpg'},
  ];

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
          // Heading + Filter Button
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
                final isSelected = cat['label'] == 'Career and Business';
                return GestureDetector(
                  onTap: () {
                    if (!isSelected) Navigator.pushNamed(context, cat['route']!);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                      ),
                      image: DecorationImage(
                        image: AssetImage(cat['image']!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat['label']!,
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
          const Center(
            child: Column(
              children: [
                Text("Career & Business Experts", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("Advance your career with industry experts",
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Expert Carousel
          Expanded(
            child: PageView.builder(
              itemCount: experts.length,
              controller: PageController(viewportFraction: 0.8),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ExpertCard(expert: experts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
