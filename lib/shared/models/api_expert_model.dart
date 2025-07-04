class ApiExpertModel {
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

  ApiExpertModel({
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
  });

  factory ApiExpertModel.fromApiJson(Map<String, dynamic> json) {
    return ApiExpertModel(
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
    );
  }
}
