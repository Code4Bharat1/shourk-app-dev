import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'dart:convert';
import 'package:shourk_application/shared/models/expert_model.dart';
import 'package:shourk_application/expert/expert_category/top_expert.dart';
import 'package:shourk_application/expert/expert_category/home_expert.dart';
import 'package:shourk_application/expert/expert_category/career_expert.dart';
import 'package:shourk_application/expert/expert_category/fashion_expert.dart';
import 'package:shourk_application/features/expert_profile/expert_detail_screen.dart';
import '../navbar/expert_bottom_navbar.dart';

class WellnessExpertsScreen extends StatefulWidget {
  const WellnessExpertsScreen({super.key});

  @override
  State<WellnessExpertsScreen> createState() => _WellnessExpertsScreenState();
}

class _WellnessExpertsScreenState extends State<WellnessExpertsScreen> {
  String selectedFilter = 'Recommended';
  List<ExpertModel> experts = [];
  bool isLoading = true;
  String errorMessage = '';

  final List<Map<String, dynamic>> categories = [
    {
      'label': 'Top Experts',
      'image': 'assets/images/img2.jpg',
      'widget': const TopExpertsScreen(),
    },
    {
      'label': 'Home',
      'image': 'assets/images/home.jpg',
      'widget': const HomeExpertsScreen(),
    },
    {
      'label': 'Career and Business',
      'image': 'assets/images/career.jpg',
      'widget': const CareerExpertsScreen(),
    },
    {
      'label': 'Fashion & Beauty',
      'image': 'assets/images/fashion.jpg',
      'widget': const FashionBeautyExpertsScreen(),
    },
    {
      'label': 'Wellness',
      'image': 'assets/images/wellness.jpg',
      'widget': const WellnessExpertsScreen(),
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

      // Corrected endpoint to match React implementation
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/expertauth/area/Wellness'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> expertsData = data['data'] ?? [];
        
        // Filter only approved experts (no category filter needed)
        final List<ExpertModel> wellnessExperts = expertsData
            .where((expert) => expert['status'] == 'Approved')
            .map((expertJson) => ExpertModel.fromJson(expertJson))
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

  List<ExpertModel> getFilteredExperts() {
    List<ExpertModel> filteredExperts = List.from(experts);

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchWellnessExperts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ExpertUpperNavbar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Filter Button - Made Responsive
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: isSmallScreen ? 2 : 3,
                      child: Text(
                        "Find The Right Expert In Seconds!",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15, 
                          fontWeight: FontWeight.bold
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: _openFilterDialog,
                        icon: const Icon(Icons.filter_alt_outlined, size: 16),
                        label: Text(
                          "Filter",
                          style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12, 
                            vertical: isSmallScreen ? 8 : 10
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Navigation - Made Responsive
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat['label'] == 'Wellness';
                final categoryWidth = isSmallScreen ? 75.0 : 90.0;

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
                    width: categoryWidth,
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
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          cat['label'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Page Title and Subtitle - Made Responsive
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    "Wellness Experts",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 22, 
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Physical & emotional wellness starts here",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13, 
                      color: Colors.black54
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Main Content Area - Made Responsive Grid
          Expanded(
            child: isLoading
                ? _buildLoadingWidget()
                : errorMessage.isNotEmpty
                    ? _buildErrorWidget()
                    : experts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
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
                                crossAxisCount: screenWidth < 400 ? 1 : 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: screenWidth < 400 ? 1.2 : 0.75,
                              ),
                              itemCount: getFilteredExperts().length,
                              itemBuilder: (context, index) {
                                final filteredExperts = getFilteredExperts();
                                return ModernExpertCard(
                                  expert: filteredExperts[index],
                                  isSmallScreen: isSmallScreen,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: ExpertBottomNavbar(currentIndex: 0),
    );
  }
}

class ModernExpertCard extends StatelessWidget {
  final ExpertModel expert;
  final bool isSmallScreen;

  const ModernExpertCard({
    super.key, 
    required this.expert,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = isSmallScreen ? 250.0 : 300.0;
    
    return InkWell(
      onTap: () {
        // Navigate to expert details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpertDetailScreen(expertId: expert.id)
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
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

            // Content overlay - Made Responsive
            Positioned(
              left: isSmallScreen ? 8 : 12,
              right: isSmallScreen ? 8 : 12,
              top: 8,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top badges - Made Responsive
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Free Session Badge
                      if (expert.freeSessionEnabled)
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8,
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
                                fontSize: isSmallScreen ? 8 : 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(width: 4),

                      // Price Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
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
                            fontSize: isSmallScreen ? 9 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Name and Verified Badge - Made Responsive
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

                  // Expert experience with semi-transparent background - Made Responsive
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
                      maxLines: isSmallScreen ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Rating badge - Made Responsive
            Positioned(
              bottom: 12,
              right: isSmallScreen ? 8 : 12,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8, 
                  vertical: 4
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
      child: Icon(
        Icons.person, 
        size: isSmallScreen ? 40 : 50, 
        color: Colors.grey[600]
      ),
    );
  }
}