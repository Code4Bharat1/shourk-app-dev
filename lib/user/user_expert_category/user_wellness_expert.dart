import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shourk_application/shared/models/expert_model.dart'as shared;

import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:shourk_application/user/home/user_expert_detailscreen.dart';

import 'package:shourk_application/user/user_expert_category/user_career_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_fashion_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_home_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_top_expert.dart';

class UserWellnessExpertsScreen extends StatefulWidget {
  const UserWellnessExpertsScreen({super.key});

  @override
  State<UserWellnessExpertsScreen> createState() => _UserWellnessExpertsScreenState();
}

class _UserWellnessExpertsScreenState extends State<UserWellnessExpertsScreen> {
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
    fetchWellnessExperts();
  }

  Future<void> fetchWellnessExperts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/expertauth/area/Wellness'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> expertsData = data['data'] ?? [];
        
        final List<shared.ExpertModel> wellnessExperts = expertsData
            .where((expert) => expert['status'] == 'Approved')
            .map<shared.ExpertModel>((json) => shared.ExpertModel.fromJson(json))
            .toList();

        setState(() {
          experts = wellnessExperts;
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              onPressed: fetchWellnessExperts,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final categoryWidth = screenWidth * 0.22;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: UserUpperNavbar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Find The Right Expert In Seconds!",
                    style: TextStyle(
                      fontSize: screenWidth > 400 ? 15 : 13, 
                      fontWeight: FontWeight.bold
                    ),
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

          // Category Navigation
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
                        MaterialPageRoute(
                          builder: (_) => cat['widget'] as Widget,
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: categoryWidth.clamp(80, 100),
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
                            fontSize: screenWidth > 400 ? 12 : 10,
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

          // Page Title and Subtitle
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    "Wellness Experts",
                    style: TextStyle(
                      fontSize: screenWidth > 400 ? 22 : 18, 
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Physical & emotional wellness starts here",
                    style: TextStyle(
                      fontSize: screenWidth > 400 ? 13 : 11, 
                      color: Colors.black54
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Main Content Area
          Expanded(
            child: isLoading
                ? _buildLoadingWidget()
                : errorMessage.isNotEmpty
                    ? _buildErrorWidget()
                    : experts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No wellness experts found',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchWellnessExperts,
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: getFilteredExperts().length,
                              itemBuilder: (context, index) {
                                final filteredExperts = getFilteredExperts();
                                return ModernExpertCard(expert: filteredExperts[index]);
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

  const ModernExpertCard({super.key, required this.expert});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
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
            // Expert Image Section
            Container(
              width: double.infinity,
              height: double.infinity,
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

            // Gradient overlay for text readability
            Container(
              width: double.infinity,
              height: double.infinity,
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

            // Content overlay
            Positioned(
              left: isSmallScreen ? 8 : 12,
              right: isSmallScreen ? 8 : 12,
              top: isSmallScreen ? 6 : 8,
              bottom: isSmallScreen ? 8 : 12,
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
                              horizontal: isSmallScreen ? 6 : 8,
                              vertical: isSmallScreen ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'First Session Free',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 8 : 10,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                      const SizedBox(width: 4),

                      // Price Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'SAR ${expert.price.toInt()}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 9 : 11,
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
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.verified, 
                        size: isSmallScreen ? 14 : 16, 
                        color: Colors.orange[600]
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Expert experience with semi-transparent background
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 25 : 35),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (expert.experience != null && expert.experience!.isNotEmpty)
                          ? expert.experience!
                          : "My name is ${expert.name.split(' ')[0]}, and I'm passionate about wellness and health.",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Rating badge
            Positioned(
              bottom: isSmallScreen ? 8 : 12,
              right: isSmallScreen ? 8 : 12,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8, 
                  vertical: isSmallScreen ? 3 : 4
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
                      size: isSmallScreen ? 12 : 14, 
                      color: Colors.orange
                    ),
                    const SizedBox(width: 4),
                    Text(
                      expert.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 10 : 12,
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
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
    );
  }
}