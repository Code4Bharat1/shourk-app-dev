import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'dart:convert';
import 'package:shourk_application/shared/models/expert_model.dart';
import 'package:shourk_application/shared/widgets/expert_card.dart';
import 'package:shourk_application/expert/expert_category/top_expert.dart';
import 'package:shourk_application/expert/expert_category/home_expert.dart';
import 'package:shourk_application/expert/expert_category/career_expert.dart';
import 'package:shourk_application/expert/expert_category/wellness_expert.dart';
import 'package:shourk_application/features/expert_profile/expert_detail_screen.dart';
import '../navbar/expert_bottom_navbar.dart'; // Added import

class FashionBeautyExpertsScreen extends StatefulWidget {
  const FashionBeautyExpertsScreen({super.key});

  @override
  State<FashionBeautyExpertsScreen> createState() => _FashionBeautyExpertsScreenState();
}

class _FashionBeautyExpertsScreenState extends State<FashionBeautyExpertsScreen> {
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
        final List<ExpertModel> fashionExperts = expertsData
            .where((expert) => expert['status'] == 'Approved')
            .map((expertJson) => ExpertModel.fromJson(expertJson))
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
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ExpertUpperNavbar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Find The Right Expert In Seconds!",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
              padding: const EdgeInsets.only(left: 12, right: 12),
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
                    margin: EdgeInsets.only(right: index == categories.length - 1 ? 0 : 8),
                    width: screenWidth * 0.22, // Responsive width
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
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
          const Center(
            child: Column(
              children: [
                Text("Fashion & Beauty Experts",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("Get styling tips, beauty help, grooming & more",
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
              ],
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
                            child: Text(
                              'No fashion & beauty experts found',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchFashionBeautyExperts,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Calculate responsive grid parameters
                                int crossAxisCount = 2;
                                double itemWidth = (constraints.maxWidth - 32 - 12) / crossAxisCount; // Total padding and spacing
                                double childAspectRatio = itemWidth / (itemWidth * 1.33); // Maintain aspect ratio
                                
                                return GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: childAspectRatio,
                                  ),
                                  itemCount: getFilteredExperts().length,
                                  itemBuilder: (context, index) {
                                    final filteredExperts = getFilteredExperts();
                                    return ModernExpertCard(
                                      expert: filteredExperts[index],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ExpertDetailScreen(
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
      bottomNavigationBar: ExpertBottomNavbar(currentIndex: 0),
    );
  }
}

class ModernExpertCard extends StatelessWidget {
  final ExpertModel expert;
  final VoidCallback onTap;

  const ModernExpertCard({
    super.key, 
    required this.expert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // Use the provided onTap callback
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Expert Image Section
                Container(
                  height: constraints.maxHeight,
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
                  height: constraints.maxHeight,
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
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: 8,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[600],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'First Session Free',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                          // Price Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'SAR ${expert.price.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.verified, size: 14, color: Colors.orange[600]),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Expert experience with semi-transparent background
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(bottom: 25),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (expert.experience != null && expert.experience!.isNotEmpty)
                              ? expert.experience!
                              : "My name is ${expert.name.split(' ')[0]}, and I'm passionate about fashion and beauty.",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            height: 1.2,
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
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.orange),
                        const SizedBox(width: 3),
                        Text(
                          expert.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
    );
  }
}