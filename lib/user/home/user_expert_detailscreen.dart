import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shourk_application/expert/Book_Video_Call/expert_schedule_videocall.dart';
import 'package:shourk_application/expert/profile/giftcard_selection_option.dart';
import 'package:shourk_application/user/navbar/user_upper_navbar.dart';
import 'package:shourk_application/user/navbar/user_bottom_navbar.dart';
import 'package:shourk_application/user/profile/user_giftcard.dart';
import 'package:shourk_application/user/Book_VideoCall/user_schedule_videocall.dart';

class UserExpertDetailscreen extends StatefulWidget {
  final String expertId;
  const UserExpertDetailscreen({super.key, required this.expertId});

  @override
  State<UserExpertDetailscreen> createState() => _UserExpertDetailscreenState();
}

class _UserExpertDetailscreenState extends State<UserExpertDetailscreen> {
  ExpertModel? _expert;
  bool _isLoading = true;
  String _error = '';
  String selectedDuration = 'Quick - 15min';
  bool isPlanSelected = false;

  @override
  void initState() {
    super.initState();
    _fetchExpertData();
  }

  Widget _buildDurationOption(BuildContext context, String duration) {
    final isSelected = duration == selectedDuration;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDuration = duration;
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          duration,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpectationsList(String duration) {
    String durationTitle;
    switch (duration) {
      case "Quick - 15min":
        durationTitle = "15 Minutes Session";
        return [
          Text(
            durationTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildExpectationItem("Ask Three Or More Questions"),
          _buildExpectationItem("Tips On How To Start A Successful Company"),
          _buildExpectationItem(
            "Advice On Getting Your First 10,000 Customers",
          ),
          _buildExpectationItem("Growth Hacks & Jumpstarting Growth"),
        ];
      case "Regular - 30min":
        durationTitle = "30 Minutes Session";
        return [
          Text(
            durationTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildExpectationItem("All Quick session benefits"),
          _buildExpectationItem("Detailed business strategy review"),
          _buildExpectationItem("Competitor analysis"),
          _buildExpectationItem("Customized action plan"),
        ];
      case "Extra - 45min":
        durationTitle = "45 Minutes Session";
        return [
          Text(
            durationTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildExpectationItem("All Regular session benefits"),
          _buildExpectationItem("In-depth financial planning"),
          _buildExpectationItem("Team building advice"),
          _buildExpectationItem("Long-term growth strategy"),
        ];
      case "All Access - 60min":
        durationTitle = "60 Minutes Session";
        return [
          Text(
            durationTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildExpectationItem("All Extra session benefits"),
          _buildExpectationItem("Comprehensive business audit"),
          _buildExpectationItem("One-on-one mentoring"),
          _buildExpectationItem("Unlimited Q&A"),
        ];
      default:
        durationTitle = "Select a Duration";
        return [
          Text(
            durationTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildExpectationItem("Select a duration to see expectations"),
        ];
    }
  }

  Widget _buildExpectationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 18)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _fetchExpertData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5070/api/expertauth/${widget.expertId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _expert = ExpertModel.fromJson(data['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load expert: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error.isNotEmpty) {
      return Scaffold(body: Center(child: Text(_error)));
    }

    final expert = _expert!;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const UserUpperNavbar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Shourk/Top Expert/${expert.name}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 150,
                      maxHeight: 250,
                    ),
                    child: expert.imageUrl.isNotEmpty
                        ? Image.network(
                            expert.imageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.person, size: 100),
                            ),
                          )
                        : Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.person, size: 100)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  expert.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  expert.title ?? '',
                  style: const TextStyle(color: Colors.black54),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange),
                    Text(expert.rating.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "About Me",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(expert.experience ?? 'No description available'),
                const SizedBox(height: 12),
                const Text(
                  "Strengths",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: expert.strengths
                      .map(
                        (s) => Chip(
                          label: Text(s),
                          backgroundColor: Colors.grey[300],
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 1:1 Video Call Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "1:1 Video Call",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Personalized 1:1 Session",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Get dedicated one-on-one expert guidance",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Starting at SAR 950",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const UserGiftCardSelectPage()),
                          );
                        },
                      ),
                      SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserScheduleVideocall(
                                  expertId: expert.id,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text("See Time"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Gift Card Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Send a Gift Card",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Share an experience",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Gift a session or membership to friends, family, or coworkers",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: Colors.blue,
                        size: 30,
                      ),
                      SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GiftCardSelectPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text("Select"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildDurationOption(context, "Quick - 15min"),
                    _buildDurationOption(context, "Regular - 30min"),
                    _buildDurationOption(context, "Extra - 45min"),
                    _buildDurationOption(context, "All Access - 60min"),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "What To Expect",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildExpectationsList(selectedDuration),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "\$${expert.price ?? 49} / session",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            5,
                            (index) => const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isPlanSelected = !isPlanSelected;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPlanSelected ? Colors.blue : Colors.white,
                      foregroundColor:
                          isPlanSelected ? Colors.white : Colors.black,
                      side: const BorderSide(color: Colors.blue),
                    ),
                    child: const Text("See Plan"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: UserBottomNavbar(currentIndex: 0),
    );
  }
}

// Expert Model with additional fields for detail screen
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
  final String experience;
  final bool charityEnabled;
  final int charityPercentage;
  final bool freeSessionEnabled;
  final String charityCause;
  final int sessionCount;
  final List<String> strengths;
  final List<Review> reviews;
  final Map<String, List<String>> whatToExpect;

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
    this.charityCause = 'Charity',
    this.sessionCount = 0,
    this.strengths = const [],
    this.reviews = const [],
    this.whatToExpect = const {},
  });

  factory ExpertModel.fromJson(Map<String, dynamic> json) {
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
      experience: json['experience'] ?? '',
      charityEnabled: json['charityEnabled'] ?? false,
      charityPercentage: json['charityPercentage'] ?? 0,
      freeSessionEnabled: json['freeSessionEnabled'] ?? false,
      charityCause: json['charityCause'] ?? 'Charity',
      sessionCount: json['sessionCount'] ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((review) => Review.fromJson(review))
              .toList() ??
          [],
      whatToExpect: (json['whatToExpect'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
                key, List<String>.from(value as List<dynamic>? ?? [])),
          ) ??
          {},
    );
  }
}

class Review {
  final String reviewerName;
  final String reviewerTitle;
  final String reviewerImage;
  final double rating;
  final String comment;

  Review({
    required this.reviewerName,
    required this.reviewerTitle,
    required this.reviewerImage,
    required this.rating,
    required this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewerName: json['reviewerName'] ?? '',
      reviewerTitle: json['reviewerTitle'] ?? '',
      reviewerImage: json['reviewerImage'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
    );
  }
}