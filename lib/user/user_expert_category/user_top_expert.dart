import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:shourk_application/user/home/user_expert_detailscreen.dart';
import 'package:shourk_application/user/user_expert_category/user_wellness_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_career_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_fashion_expert.dart';
import 'package:shourk_application/user/user_expert_category/user_home_expert.dart';
// import 'package:shourk_application/user/user_expert_category/user_top_expert.dart';
import 'dart:convert';
import 'package:shourk_application/shared/models/expert_model.dart' as shared;
// import 'package:shourk_application/shared/widgets/expert_card.dart';
// import 'package:shourk_application/shared/models/expert_model.dart';
// import 'package:shourk_application/features/expert_profile/expert_detail_screen.dart';
// import 'package:shourk_application/user/home/user_expert_detailscreen.dart';

class UserTopExpertsScreen extends StatefulWidget {
  const UserTopExpertsScreen({super.key});

  @override
  State<UserTopExpertsScreen> createState() => _UserTopExpertsScreenState();
}

class _UserTopExpertsScreenState extends State<UserTopExpertsScreen> {
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
    fetchExperts();
  }

  Future<void> fetchExperts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/expertauth/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> expertsData = data['data'] ?? [];

        // Filter experts with rating >= 4
        final List<shared.ExpertModel> filteredExperts =
            expertsData
                .where((expert) => expert['status'] == 'Approved')
                .map((expertJson) => shared.ExpertModel.fromJson(expertJson))
                .where((expert) => expert.rating >= 4.0)
                .toList();

        setState(() {
          experts = filteredExperts;
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
        // Use null-safe access for reviews
        filteredExperts.sort(
          (a, b) => (b.reviews?.length ?? 0).compareTo(a.reviews?.length ?? 0),
        );
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
      builder:
          (ctx) => AlertDialog(
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
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: fetchExperts, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 4; // Large screens
    } else if (screenWidth > 600) {
      return 3; // Tablets
    } else {
      return 2; // Mobile
    }
  }

  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 0.75; // Large screens
    } else if (screenWidth > 600) {
      return 0.7; // Tablets
    } else {
      return 0.75; // Mobile
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: UserUpperNavbar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Filter Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Find The Right Expert In Seconds!",
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 15,
                      fontWeight: FontWeight.bold,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Navigation
          SizedBox(
            height: isTablet ? 80 : 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: isTablet ? 24 : 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat['label'] == 'Top Experts';

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
                    width: isTablet ? 110 : 90,
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
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          cat['label'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: isTablet ? 14 : 12,
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
            child: Column(
              children: [
                Text(
                  "Top Experts",
                  style: TextStyle(
                    fontSize: isTablet ? 26 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Access to the best has never been easier",
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Main Content Area
          Expanded(
            child:
                isLoading
                    ? _buildLoadingWidget()
                    : errorMessage.isNotEmpty
                    ? _buildErrorWidget()
                    : experts.isEmpty
                    ? const Center(
                      child: Text(
                        'No experts found',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: fetchExperts,
                      child: GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          crossAxisSpacing: isTablet ? 16 : 12,
                          mainAxisSpacing: isTablet ? 20 : 16,
                          childAspectRatio: _getChildAspectRatio(context),
                        ),
                        itemCount: getFilteredExperts().length,
                        itemBuilder: (context, index) {
                          final filteredExperts = getFilteredExperts();
                          return ModernExpertCard(
                            expert: filteredExperts[index],
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

// Responsive ModernExpertCard
class ModernExpertCard extends StatelessWidget {
  final shared.ExpertModel expert;

  const ModernExpertCard({super.key, required this.expert});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserExpertDetailscreen(expertId: expert.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          final cardHeight = constraints.maxHeight;

          return Container(
            width: cardWidth,
            height: cardHeight,
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
                  height: cardHeight,
                  width: cardWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        expert.imageUrl.isNotEmpty
                            ? Image.network(
                              expert.imageUrl,
                              width: cardWidth,
                              height: cardHeight,
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
                  height: cardHeight,
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
                  top: isTablet ? 16 : 12,
                  right: isTablet ? 16 : 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 10 : 8,
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
                          size: isTablet ? 16 : 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expert.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 13 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Name & expertise (bottom)
                Positioned(
                  bottom: 35,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
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
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.verified,
                              size: isTablet ? 18 : 16,
                              color: Colors.orange[600],
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 8 : 6),
                        // Expertise text
                        Text(
                          (expert.experience != null &&
                                  expert.experience!.isNotEmpty)
                              ? expert.experience!
                              : "My name is ${expert.name.split(' ')[0]}, and I'm passionate about growth and making an impact.",
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 12,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: isTablet ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Rating badge
                Positioned(
                  bottom: isTablet ? 16 : 12,
                  right: isTablet ? 16 : 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 10 : 8,
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
                          size: isTablet ? 16 : 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expert.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 13 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
