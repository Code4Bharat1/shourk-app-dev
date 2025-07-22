import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shourk_application/shared/models/expert_model.dart' as shared;
import 'package:shourk_application/shared/widgets/expert_card.dart';
import 'package:shourk_application/features/expert_profile/expert_detail_screen.dart';
import 'package:shourk_application/user/home/user_expert_detailscreen.dart';

import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:shourk_application/user/home/user_expert_detailscreen.dart';

import 'package:shourk_application/user/user_expert_category/user_wellness_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_career_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_home_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_top_expert.dart';
import '../home/user_expert_detailscreen.dart';

class UserFashionBeautyExpertsScreen extends StatefulWidget {
  const UserFashionBeautyExpertsScreen({super.key});

  @override
  State<UserFashionBeautyExpertsScreen> createState() => _UserFashionBeautyExpertsScreenState();
}

class _UserFashionBeautyExpertsScreenState extends State<UserFashionBeautyExpertsScreen> {
  String selectedFilter = 'Recommended';
  List<shared.ExpertModel> experts = [];
  bool isLoading = true;
  String errorMessage = '';

  final List<Map<String, dynamic>> categories = [
    {
      'label': 'Top Experts',
      'image': 'assets/images/img2.jpg',
      'widget': const UserTopExpertsScreen(),
    },
    {
      'label': 'Home',
      'image': 'assets/images/home.jpg',
      'widget': const UserHomeExpertsScreen(),
    },
    {
      'label': 'Career and Business',
      'image': 'assets/images/career.jpg',
      'widget': const UserCareerExpertsScreen(),
    },
    {
      'label': 'Fashion & Beauty',
      'image': 'assets/images/fashion.jpg',
      'widget': const UserFashionBeautyExpertsScreen(),
    },
    {
      'label': 'Wellness',
      'image': 'assets/images/wellness.jpg',
      'widget': const UserWellnessExpertsScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchFashionBeautyExperts();
  }

  Future<void> fetchFashionBeautyExperts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Encode the area parameter to handle spaces
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/expertauth/area/Style%20and%20Beauty'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> expertsData = data['data'] ?? [];
        
        // Filter only approved experts
        final List<shared.ExpertModel> fashionExperts = expertsData
            .where((expert) => expert['status'] == 'Approved')
            .map((expertJson) => shared.ExpertModel.fromJson(expertJson))
            .toList();

        setState(() {
          experts = fashionExperts;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load experts. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching expert data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  List<shared.ExpertModel> getFilteredExperts() {
    List<shared.ExpertModel> filteredExperts = List.from(experts);

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
        filteredExperts.sort((a, b) => 
            (b.reviews?.length ?? 0).compareTo(a.reviews?.length ?? 0));
        break;
      default:
        // Keep recommended order (default API order)
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

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading experts...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchFashionBeautyExperts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final filteredExperts = getFilteredExperts();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: UserUpperNavbar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Filter Button with responsive padding
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04, // 4% of screen width
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Find The Right Expert In Seconds!",
                    style: TextStyle(
                      fontSize: screenWidth < 350 ? 13 : 15,
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

          // Category Navigation with responsive sizing
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: screenWidth * 0.04),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat['label'] == 'Fashion & Beauty';

                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => cat['widget'] as Widget,
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: screenWidth < 350 ? 80 : 90,
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
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          cat['label'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: screenWidth < 350 ? 10 : 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Page Title and Subtitle with responsive text
          Center(
            child: Column(
              children: [
                Text(
                  "Fashion & Beauty Experts",
                  style: TextStyle(
                    fontSize: screenWidth < 350 ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Text(
                    "Get styling tips, beauty help, grooming & more",
                    style: TextStyle(
                      fontSize: screenWidth < 350 ? 11 : 13,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Main Content Area with responsive grid
          Expanded(
            child: isLoading
                ? _buildLoadingWidget()
                : errorMessage.isNotEmpty
                    ? _buildErrorWidget()
                    : experts.isEmpty
                        ? const Center(
                            child: Text(
                              'No fashion & beauty experts found',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchFashionBeautyExperts,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Calculate cross axis count based on screen width
                                int crossAxisCount = 2;
                                if (constraints.maxWidth > 600) {
                                  crossAxisCount = 3;
                                } else if (constraints.maxWidth < 350) {
                                  crossAxisCount = 1;
                                }
                                
                                // Calculate aspect ratio based on screen size
                                double aspectRatio = constraints.maxWidth < 350 ? 1.2 : 0.75;
                                
                                return GridView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                  ),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: screenWidth * 0.03,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: aspectRatio,
                                  ),
                                  itemCount: filteredExperts.length,
                                  itemBuilder: (context, index) {
                                    return ModernExpertCard(
                                      expert: filteredExperts[index],
                                      screenWidth: screenWidth,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UserExpertDetailscreen(
                                              expertId: filteredExperts[index].id,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
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
  final double screenWidth;
  final VoidCallback onTap;

  const ModernExpertCard({
    super.key, 
    required this.expert,
    required this.screenWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Expert Image Section
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
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

              // Gradient overlay for text readability
              Container(
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

              // Content overlay with responsive sizing
              Positioned(
                left: screenWidth * 0.02,
                right: screenWidth * 0.02,
                top: 8,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Free Session Badge
                        if (expert.freeSessionEnabled)
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.015,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'First Session Free',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth < 350 ? 8 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                        // Spacer
                        if (expert.freeSessionEnabled) const SizedBox(width: 4),

                        // Price Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.015,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'SAR ${expert.price.toInt()}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth < 350 ? 9 : 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Name and Verified Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expert.name,
                            style: TextStyle(
                              fontSize: screenWidth < 350 ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.verified,
                          size: screenWidth < 350 ? 14 : 16,
                          color: Colors.orange[600],
                        ),
                      ],
                    ),

                    SizedBox(height: screenWidth < 350 ? 6 : 8),

                    // Expert experience with semi-transparent background
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      margin: EdgeInsets.only(bottom: screenWidth < 350 ? 25 : 35),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (expert.experience != null && expert.experience!.isNotEmpty)
                            ? expert.experience!
                            : "My name is ${expert.name.split(' ')[0]}, and I'm passionate about fashion and beauty.",
                        style: TextStyle(
                          fontSize: screenWidth < 350 ? 10 : 12,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: screenWidth < 350 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating badge
              Positioned(
                bottom: 12,
                right: screenWidth * 0.02,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.015,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: screenWidth < 350 ? 12 : 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expert.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth < 350 ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: screenWidth < 350 ? 40 : 50,
        color: Colors.grey[600],
      ),
    );
  }
}