// Updated Expert Model
class ExpertModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? title;
  final String? photoFile;
  final double averageRating;
  final String? experience;
  final double price;
  final String? about;
  final List<String> strengths;
  final Map<String, List<String>> whatToExpect;
  final List<ReviewModel> reviews;
  final String category;
  final bool freeSessionEnabled;
  final bool charityEnabled;
  final int charityPercentage;
  final String? designation;
  final List<String>? advice;
  final List<DayAvailability> availability;  // New field
  final int monthsRange;  // New field

  ExpertModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.title,
    this.photoFile,
    required this.averageRating,
    this.experience,
    required this.price,
    this.about,
    required this.strengths,
    required this.whatToExpect,
    required this.reviews,
    required this.category,
    required this.freeSessionEnabled,
    required this.charityEnabled,
    required this.charityPercentage,
    this.designation,
    this.advice,
    required this.availability,  // New required parameter
    required this.monthsRange,  // New required parameter
  });

  String get name => '$firstName $lastName';
  double get rating => averageRating;
  
  String get imageUrl {
    if (photoFile == null) return '';
    if (photoFile!.startsWith('http')) return photoFile!;
    return 'http://localhost:5070$photoFile';
  }

  factory ExpertModel.fromJson(Map<String, dynamic> json) {
    return ExpertModel(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      title: json['title'] ?? json['profession'],
      photoFile: json['photoFile'],
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      experience: json['experience'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      about: json['about'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      whatToExpect: _parseWhatToExpect(json['whatToExpect']),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((review) => ReviewModel.fromJson(review))
          .toList() ?? [],
      category: json['category'] ?? '',
      freeSessionEnabled: json['freeSessionEnabled'] ?? false,
      charityEnabled: json['charityEnabled'] ?? false,
      charityPercentage: json['charityPercentage'] ?? 0,
      designation: json['designation'],
      advice: List<String>.from(json['advice'] ?? []),
      availability: (json['availability'] as List<dynamic>?)
          ?.map((avail) => DayAvailability.fromJson(avail))
          .toList() ?? [],
      monthsRange: json['monthsRange'] ?? 1,
    );
  }

  static Map<String, List<String>> _parseWhatToExpect(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is List) {
          return MapEntry(key, List<String>.from(value));
        }
        return MapEntry(key, <String>[]);
      });
    }
    return {};
  }
}

class ReviewModel {
  final String reviewerName;
  final String reviewerTitle;
  final String reviewerImage;
  final double rating;
  final String comment;

  ReviewModel({
    required this.reviewerName,
    required this.reviewerTitle,
    required this.reviewerImage,
    required this.rating,
    required this.comment,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewerName: json['reviewerName'] ?? '',
      reviewerTitle: json['reviewerTitle'] ?? '',
      reviewerImage: json['reviewerImage'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
    );
  }
}

class DayAvailability {
  final String date;
  final List<String> slots;

  DayAvailability({required this.date, required this.slots});

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    return DayAvailability(
      date: json['date'] ?? '',
      slots: List<String>.from(json['slots'] ?? []),
    );
  }
}

List<ExpertModel> dummyExperts = [
  ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
    availability: [],  // Added new field
    monthsRange: 1,   // Added new field
  ),
  ExpertModel(
    id: '2',
    firstName: 'Amina',
    lastName: 'Yusuf',
    title: 'Career Coach',
    photoFile: 'assets/images/img2.jpg',
    averageRating: 4.7,
    experience: 'Helping professionals grow in their careers and achieve goals.',
    price: double.infinity,
    about: 'Certified career coach with expertise in job search and interview prep.',
    strengths: ['CV Review', 'Career Transition', 'Interview Coaching'],
    whatToExpect: {
      'Quick - 15min': ['Discuss career goals', 'Resume tips'],
      'Regular - 30min': ['Personalized career advice'],
      'Extra - 45min': ['Mock interviews + Q&A'],
      'All Access - 60min': ['Full career planning session'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Sarah Ahmed',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/women/32.jpg',
        rating: 4.8,
        comment: 'She helped me land my dream job!',
      ),
    ],
    category: 'Top',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
    availability: [],  // Added new field
    monthsRange: 1,   // Added new field
  ),
  // Continue adding availability and monthsRange to all other entries...
  ExpertModel(
    id: '3',
    firstName: 'Dr. Sara',
    lastName: 'Khan',
    title: 'Child Therapist',
    photoFile: 'assets/images/img3.jpg',
    averageRating: 4.8,
    experience: 'Expert in child psychology and behavior development support.',
    price: double.infinity,
    about: '10+ years helping kids and parents manage behavioral challenges.',
    strengths: ['Child Behavior', 'Parent Coaching', 'Emotional Growth'],
    whatToExpect: {
      'Quick - 15min': ['Short consultation for concerns'],
      'Regular - 30min': ['Child behavior assessment'],
      'Extra - 45min': ['Parent-child counseling'],
      'All Access - 60min': ['Full development strategy'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Ola Youssef',
        reviewerTitle: 'Parent',
        reviewerImage: 'https://randomuser.me/api/portraits/women/12.jpg',
        rating: 4.9,
        comment: 'Great advice for my child’s anxiety.',
      ),
    ],
    category: 'wellness',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
    availability: [],  // Added new field
    monthsRange: 1,   // Added new field
  ),
  ExpertModel(
    id: '4',
    firstName: 'Omar',
    lastName: 'El-Sherif',
    title: 'Financial Advisor',
    photoFile: 'assets/images/img4.jpg',
    averageRating: 4.6,
    experience: 'Guiding smart investments and personal finance strategies.',
    price: double.infinity,
    about: 'Finance expert helping individuals plan their wealth and savings.',
    strengths: ['Investments', 'Budgeting', 'Retirement Planning'],
    whatToExpect: {
      'Quick - 15min': ['Assess your financial goals'],
      'Regular - 30min': ['Review your portfolio'],
      'Extra - 45min': ['Investment strategy session'],
      'All Access - 60min': ['Complete financial roadmap'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Ali Khan',
        reviewerTitle: 'Entrepreneur',
        reviewerImage: 'https://randomuser.me/api/portraits/men/20.jpg',
        rating: 4.6,
        comment: 'Very professional and clear with advice.',
      ),
    ],
    category: 'career',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
    availability: [],  // Added new field
    monthsRange: 1,   // Added new field
  ),
  // Add remaining experts with availability and monthsRange...
  // (Repeat pattern for all other entries)

  // Continue converting all other entries...
  ExpertModel(
    id: '3',
    firstName: 'Dr. Sara',
    lastName: 'Khan',
    title: 'Child Therapist',
    photoFile: 'assets/images/img3.jpg',
    averageRating: 4.8,
    experience: 'Expert in child psychology and behavior development support.',
    price: double.infinity,
    about: '10+ years helping kids and parents manage behavioral challenges.',
    strengths: ['Child Behavior', 'Parent Coaching', 'Emotional Growth'],
    whatToExpect: {
      'Quick - 15min': ['Short consultation for concerns'],
      'Regular - 30min': ['Child behavior assessment'],
      'Extra - 45min': ['Parent-child counseling'],
      'All Access - 60min': ['Full development strategy'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Ola Youssef',
        reviewerTitle: 'Parent',
        reviewerImage: 'https://randomuser.me/api/portraits/women/12.jpg',
        rating: 4.9,
        comment: 'Great advice for my child’s anxiety.',
      ),
    ],
    category: 'wellness',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
  ExpertModel(
    id: '4',
    firstName: 'Omar',
    lastName: 'El-Sherif',
    title: 'Financial Advisor',
    photoFile: 'assets/images/img4.jpg',
    averageRating: 4.6,
    experience: 'Guiding smart investments and personal finance strategies.',
    price: double.infinity,
    about: 'Finance expert helping individuals plan their wealth and savings.',
    strengths: ['Investments', 'Budgeting', 'Retirement Planning'],
    whatToExpect: {
      'Quick - 15min': ['Assess your financial goals'],
      'Regular - 30min': ['Review your portfolio'],
      'Extra - 45min': ['Investment strategy session'],
      'All Access - 60min': ['Complete financial roadmap'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Ali Khan',
        reviewerTitle: 'Entrepreneur',
        reviewerImage: 'https://randomuser.me/api/portraits/men/20.jpg',
        rating: 4.6,
        comment: 'Very professional and clear with advice.',
      ),
    ],
    category: 'career',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),
   ExpertModel(
    id: '1',
    firstName: 'Dr. Ahmed',
    lastName: 'Al-Sayed',
    title: 'Psychologist',
    photoFile: 'assets/images/img1.jpg',
    averageRating: 4.9,
    experience: 'hello this is short expert here and I hope that you connect with me.',
    price: double.infinity,
    about: 'Experienced psychologist with 15+ years in clinical therapy.',
    strengths: ['Mental Health', 'Therapy', 'Family Counseling'],
    whatToExpect: {
      'Quick - 15min': ['Introduction & 2 quick tips', 'Discuss primary concern'],
      'Regular - 30min': ['Explore your issues in more depth'],
      'Extra - 45min': ['In-depth mental wellness session'],
      'All Access - 60min': ['Comprehensive wellness planning'],
    },
    reviews: [
      ReviewModel(
        reviewerName: 'Cameron Williamson',
        reviewerTitle: 'Client',
        reviewerImage: 'https://randomuser.me/api/portraits/men/11.jpg',
        rating: 5.0,
        comment: 'Super insightful session!',
      ),
    ],
    category: 'Home',
    freeSessionEnabled: false,
    charityEnabled: false,
    charityPercentage: 0,
     availability: [],  // Added new field
    monthsRange: 1, 
  ),

 
];