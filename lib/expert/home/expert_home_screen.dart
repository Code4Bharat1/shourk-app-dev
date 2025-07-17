import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shourk_application/expert/expert_category/home_expert.dart';
import 'dart:convert';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';
import '../../features/expert_profile/expert_detail_screen.dart';
import '../../shared/widgets/expert_card.dart';
import '../../shared/models/expert_model.dart';
// import '../home/category_experts_screen.dart';

import '../../expert/expert_category/career_expert.dart';
import '../../expert/expert_category/top_expert.dart';
import '../../expert/expert_category/wellness_expert.dart';
import '../../expert/expert_category/career_expert.dart';
import '../../expert/expert_category/fashion_expert.dart';

// Moved CategoryChip to top level
class CategoryChip extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
    );
  }
}

class ExpertHomeScreen extends StatefulWidget {
  const ExpertHomeScreen({super.key});

  @override
  State<ExpertHomeScreen> createState() => _ExpertHomeScreenState();
}

class _ExpertHomeScreenState extends State<ExpertHomeScreen> {
  bool _isLoading = true;
  String _error = '';
  List<CategoryData> _categories = [];

  // FIXED: Updated API categories to match your database exactly
  final List<String> _apiCategories = [
   
    'Wellness',
    'Style and Beauty', // Changed from 'Fashion' to match database
    'Career and Business', // Changed from 'Business' to match database
    'Home',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllCategories();
  }

  Future<void> _fetchAllCategories() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      List<CategoryData> categories = [];

      // Fetch experts for each category
      for (String categoryName in _apiCategories) {
        print('Fetching category: $categoryName'); // Debug log
        final experts = await _fetchExpertsByCategory(categoryName);
        print('Found ${experts.length} experts for $categoryName'); // Debug log

        if (experts.isNotEmpty) {
          categories.add(
            CategoryData(
              name: _getCategoryDisplayName(categoryName),
              experts:
                  experts
                      .take(10)
                      .toList(), // FIXED: Show up to 10 experts instead of 3
            ),
          );
        }
      }

      // Add "Top Experts" category with highest rated experts from all categories
      final allExperts =
          categories.expand((category) => category.experts).toList();

      allExperts.sort((a, b) => b.rating.compareTo(a.rating));

      if (allExperts.isNotEmpty) {
        categories.insert(
          0,
          CategoryData(
            name: 'Top Experts',
            experts:
                allExperts
                    .take(10)
                    .toList(), // FIXED: Show up to 10 top experts
          ),
        );
      }

      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      print('Total categories loaded: ${_categories.length}'); // Debug log
    } catch (e) {
      print('Error in _fetchAllCategories: $e'); // Debug log
      setState(() {
        _error = 'Error fetching expert data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<List<ExpertModel>> _fetchExpertsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('https://amd-api.code4bharat.com/api/expertauth/area/$category'),
        headers: {'Content-Type': 'application/json'},
      );

      print('API Response for $category: ${response.statusCode}'); // Debug log
      print('API Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> expertsJson = data['data'] ?? [];

        print(
          'Raw experts count for $category: ${expertsJson.length}',
        ); // Debug log

        // Filter only approved experts and convert to ExpertModel
        final List<ExpertModel> experts =
            expertsJson
                .where((expert) {
                  final status = expert['status'];
                  print('Expert status: $status'); // Debug log
                  return status == 'Approved';
                })
                .map((expert) => ExpertModel.fromApiJson(expert))
                .toList();

        print(
          'Approved experts count for $category: ${experts.length}',
        ); // Debug log
        return experts;
      } else {
        print(
          'API Error for $category: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to load experts for $category: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching experts for $category: $e');
      return [];
    }
  }

  String _getCategoryDisplayName(String apiCategory) {
    switch (apiCategory) {
      case 'Wellness':
        return 'Wellness';
      case 'Style and Beauty':
        return 'Fashion & Beauty';
      case 'Career and Business':
        return 'Career and Business';
      case 'Home':
        return 'Home';
      default:
        return apiCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ExpertUpperNavbar(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorWidget()
              : _categories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _fetchAllCategories,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // NEW: "Find The Right Expert" section
                      _buildCategorySelectorSection(),

                      // All Categories in Vertical List
                      ..._categories.map(
                        (category) => _buildCategorySection(category),
                      ),

                      // Feature Text Section
                      _buildFeatureTextSection(),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: ExpertBottomNavbar(
        currentIndex: 0,
        // onTap: (index) {
        //   // TODO: Implement navigation
        // },
      ),
    );
  }

  // NEW: Category selector section widget
  Widget _buildCategorySelectorSection() {
    final List<Map<String, dynamic>> categories = [
      {'label': 'Top Experts', 'image': 'assets/images/img2.jpg'},
      {'label': 'Home', 'image': 'assets/images/home.jpg'},
      {'label': 'Career and Business', 'image': 'assets/images/career.jpg'},
      {'label': 'Fashion & Beauty', 'image': 'assets/images/fashion.jpg'},
      {'label': 'Wellness', 'image': 'assets/images/wellness.jpg'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find The Right Expert In Seconds!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return GestureDetector(
                  onTap: () => _navigateToCategory(category['label']),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: AssetImage(category['image']),
                        fit: BoxFit.cover,
                        colorFilter: const ColorFilter.mode(
                          Colors.black38,
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category['label'],
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
        ],
      ),
    );
  }

  Widget _buildFeatureTextSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFeatureItem(
            icon: Icons.schedule,
            title: 'Save time and money, guaranteed',
            subtitle:
                'Our guarantee - find value in your first session or your money back',
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.workspace_premium,
            title: 'Get access to the world\'s best',
            subtitle:
                'Choose from our list of the top experts in a variety of topics',
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.person,
            title: 'Personalized advice just for you',
            subtitle:
                'Book a 1-on-1 and group virtual session & get advice that is tailored to you',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchAllCategories,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No experts found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any experts at the moment. Please try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchAllCategories,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // Updated Category Section Widget with proper horizontal scrolling
  Widget _buildCategorySection(CategoryData category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToCategory(category.name),
                  child: const Text(
                    'See all',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Expert List - Updated for better scrolling
          SizedBox(
            height: 300, // Increased height to accommodate fixed layout
            child:
                category.experts.isEmpty
                    ? Center(
                      child: Text(
                        'No experts available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics:
                          const BouncingScrollPhysics(), // Smooth scrolling
                      itemCount: category.experts.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200, // Fixed width for consistent cards
                          margin: const EdgeInsets.only(
                            right: 16,
                          ), // Increased spacing
                          child: ModernExpertCard(
                            expert: category.experts[index],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void _navigateToCategory(String categoryName) {
    Widget screen;

    switch (categoryName.toLowerCase()) {
      case 'top experts':
        screen = const TopExpertsScreen();
        break;
      case 'wellness':
        screen = const WellnessExpertsScreen();
        break;
      case 'home':
        screen = const HomeExpertsScreen();
        break;
      case 'fashion & beauty':
        screen = const FashionBeautyExpertsScreen();
        break;
      case 'career and business':
        screen = const CareerExpertsScreen();
        break;
      default:
        screen = const TopExpertsScreen(); // fallback
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

// Enhanced Expert Model with API integration
class ExpertModel {
  final String id;
  final String name;
  final String title;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String category;
  final bool isOnline;
  final double price;
  final String experience; // Used for expert bio/description
  final bool charityEnabled;
  final int charityPercentage;
  final bool freeSessionEnabled;
  final String charityCause; // New field for charity cause
  final int sessionCount; // New field for session count

  ExpertModel({
    required this.id,
    required this.name,
    required this.title,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.category,
    required this.isOnline,
    this.price = 0.0,
    this.experience = '',
    this.charityEnabled = false,
    this.charityPercentage = 0,
    this.freeSessionEnabled = false,
    this.charityCause = 'Charity', // Default cause
    this.sessionCount = 0, // Default session count
  });

  // Factory constructor for API JSON parsing
  factory ExpertModel.fromApiJson(Map<String, dynamic> json) {
    return ExpertModel(
      id: json['_id'] ?? '',
      name: json['firstName'] ?? 'Unknown Expert',
      title: json['profession'] ?? json['category'] ?? 'Expert',
      rating: (json['averageRating'] ?? 0.0).toDouble(),
      reviewCount: json['numberOfRatings'] ?? 0,
      imageUrl: json['photoFile'] ?? '',
      category: json['category'] ?? '',
      isOnline: json['isOnline'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      experience: json['experience'] ?? '', // Using experience field
      charityEnabled: json['charityEnabled'] ?? false,
      charityPercentage: json['charityPercentage'] ?? 0,
      freeSessionEnabled: json['freeSessionEnabled'] ?? false,
      charityCause: json['charityCause'] ?? 'Charity',
      sessionCount: json['sessionCount'] ?? 0,
    );
  }

  // Factory constructor for local JSON parsing (backward compatibility)
  factory ExpertModel.fromJson(Map<String, dynamic> json) {
    return ExpertModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      isOnline: json['isOnline'] ?? false,
      price: (json['price'] ?? 0.0).toDouble(),
      experience: json['experience'] ?? '',
      charityEnabled: json['charityEnabled'] ?? false,
      charityPercentage: json['charityPercentage'] ?? 0,
      freeSessionEnabled: json['freeSessionEnabled'] ?? false,
      charityCause: json['charityCause'] ?? 'Charity',
      sessionCount: json['sessionCount'] ?? 0,
    );
  }

  // Method to convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'category': category,
      'isOnline': isOnline,
      'price': price,
      'experience': experience,
      'charityEnabled': charityEnabled,
      'charityPercentage': charityPercentage,
      'freeSessionEnabled': freeSessionEnabled,
      'charityCause': charityCause,
      'sessionCount': sessionCount,
    };
  }
}

// FIXED: Updated Modern Expert Card Widget - Proper spacing for charity badge
class ModernExpertCard extends StatelessWidget {
  final ExpertModel expert;

  const ModernExpertCard({super.key, required this.expert});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to Expert Detail Screen with expert ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpertDetailScreen(expertId: expert.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        height: 300, // Fixed height
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

            // Gradient overlay for text readability
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

            // Content overlay - FIXED: Better spacing and positioning
            Positioned(
              left: 12,
              right: 12,
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

                  const Spacer(),

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
                      Icon(Icons.verified, size: 16, color: Colors.orange[600]),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Expert experience with semi-transparent background
                  // FIXED: Dynamic bottom margin based on charity enabled status
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: EdgeInsets.only(
                      bottom: expert.charityEnabled ? 8 : 35, // FIXED: Less margin when charity is enabled
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      expert.experience.isNotEmpty
                          ? expert.experience
                          : "My name is ${expert.name.split(' ')[0]}, and I'm passionate about growth and making an impact.",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Charity Badge - FIXED: Positioned with minimal spacing
                  if (expert.charityEnabled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8), // FIXED: Minimal margin
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 10,
                            color: Colors.pink[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${expert.charityPercentage}% to ${expert.charityCause}',
                            style: TextStyle(
                              color: Colors.pink[600],
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // FIXED: Rating badge - positioned separately to avoid overlap
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

// Category Data Model
class CategoryData {
  final String name;
  List<ExpertModel> experts;

  CategoryData({required this.name, required this.experts});
}