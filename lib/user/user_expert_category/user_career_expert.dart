import 'package:flutter/material.dart';
// import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'package:shourk_application/features/expert_profile/expert_detail_screen.dart';
import 'package:shourk_application/shared/models/expert_model.dart' as shared;
import 'package:shourk_application/shared/widgets/expert_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart'; // For firstOrNull


import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
// import 'package:shourk_application/user/home/user_expert_detailscreen.dart';


import 'package:shourk_application/user/user_expert_category/user_wellness_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_fashion_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_home_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_top_expert.dart';
import '../home/user_expert_detailscreen.dart';

class UserCareerExpertsScreen extends StatefulWidget {
  const UserCareerExpertsScreen({super.key});

  @override
  State<UserCareerExpertsScreen> createState() => _UserCareerExpertsScreenState();
}

class _UserCareerExpertsScreenState extends State<UserCareerExpertsScreen> {
  String selectedFilter = 'Recommended';
  List<shared.ExpertModel> experts = [];
  bool isLoading = true;
  String errorMessage = '';

  final List<Map<String, dynamic>> categories = [
    {'label': 'Top Experts', 'image': 'assets/images/img2.jpg', 'route': const UserTopExpertsScreen()},
    {'label': 'Home', 'image': 'assets/images/home.jpg', 'route': const UserHomeExpertsScreen()},
    {'label': 'Career and Business', 'image': 'assets/images/career.jpg', 'route': const UserCareerExpertsScreen()},
    {'label': 'Fashion & Beauty', 'image': 'assets/images/fashion.jpg', 'route': const UserFashionBeautyExpertsScreen()},
    {'label': 'Wellness', 'image': 'assets/images/wellness.jpg', 'route': const UserWellnessExpertsScreen()},
  ];

  @override
  void initState() {
    super.initState();
    fetchExperts();
  }

  Future<void> fetchExperts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/expertauth/area/Career%20and%20Business'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List fetchedExperts = data['data'];

        final approvedExperts = fetchedExperts
            .where((expert) => expert['status'] == 'Approved')
            .map<shared.ExpertModel>((json) => shared.ExpertModel.fromJson(json)) // Fixed: Use fromJson
            .toList();

        setState(() {
          experts = approvedExperts;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch experts. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  List<shared.ExpertModel> getFilteredExperts() {
    List<shared.ExpertModel> filteredExperts = [...experts];

    switch (selectedFilter) {
      case 'Price High - Low':
        filteredExperts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Price Low - High':
        filteredExperts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Highest Rating':
        filteredExperts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Most Reviewed':
        // Use reviews.length instead of reviewCount
        filteredExperts.sort((a, b) => b.reviews.length.compareTo(a.reviews.length));
        break;
    }

    return filteredExperts;
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
            child: const Text('Close'),
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
    final filteredExperts = getFilteredExperts();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: UserUpperNavbar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Find The Right Expert In Seconds!",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey.shade300,
                                ),
                                image: DecorationImage(
                                  image: AssetImage(cat['image']),
                                  fit: BoxFit.cover,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.black38,
                                    BlendMode.darken,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  cat['label'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                          Text(
                            "Career & Business Experts",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Grow your business, career and confidence",
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filteredExperts.length,
                        itemBuilder: (context, index) {
                          return ModernExpertCard(expert: filteredExperts[index]);
                        },
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: UserBottomNavbar(currentIndex: 0),
    );
  }
}

class ModernExpertCard extends StatelessWidget {
  final shared.ExpertModel expert;

  const ModernExpertCard({super.key, required this.expert});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserExpertDetailscreen(expertId: expert.id)
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Expert Image Section (unchanged)
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: expert.imageUrl.isNotEmpty
                    ? Image.network(
                        expert.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
            ),

            // Gradient overlay (unchanged)
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.01),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.4, 0.5, 0.7, 0.85, 1.0],
                ),
              ),
            ),

            // TOP BADGES (unchanged position)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Free Session Badge
                  if (expert.freeSessionEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'First Session Free',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Price Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'SAR ${expert.price.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // RATING BADGE (unchanged position)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      expert.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // NAME AND DESCRIPTION (MOVED TO BOTTOM)
            Positioned(
              bottom: 35,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Verified Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expert.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.verified, 
                          size: 16, 
                          color: Colors.orange
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      (expert.experience != null && expert.experience!.isNotEmpty)
                          ? expert.experience!
                          : "My name is ${expert.name.split(' ').firstOrNull ?? 'Unknown'}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: const Icon(Icons.person, size: 50, color: Colors.grey),
    );
  }
}