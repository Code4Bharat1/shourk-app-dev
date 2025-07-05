  class ExpertModel {
    final String name;
    final String title;
    final String imageUrl;
    final double rating;
    final String description;
    final double price;
    final String about;
    final List<String> strengths;
    final Map<String, List<String>> whatToExpect;
    final List<ReviewModel> reviews;

    final String category;

    ExpertModel({
      required this.name,
      required this.title,
      required this.imageUrl,
      required this.rating,
      required this.description,
      required this.about,
      required this.price,
      required this.strengths,
      required this.whatToExpect,
      required this.reviews,

      required this.category,
    });
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
  }

  List<ExpertModel> dummyExperts = [
    ExpertModel(
      name: 'Dr. Ahmed Al-Sayed',
      title: 'Psychologist',
      imageUrl: 'assets/images/img1.jpg',
      rating: 4.9,
      price: double.infinity,
      category: 'Home',
      description: 'hello this is short expert here and I hope that you connect with me.',
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
    ),
        ExpertModel(
      name: 'Dr. Ahmed Al-Sayed',
      title: 'Psychologist',
      imageUrl: 'assets/images/img1.jpg',
      rating: 4.9,
      price: double.infinity,
      category: 'Home',
      description: 'hello this is short expert here and I hope that you connect with me.',
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
    ),
        ExpertModel(
      name: 'Dr. Ahmed Al-Sayed',
      title: 'Psychologist',
      imageUrl: 'assets/images/img1.jpg',
      rating: 4.9,
      price: double.infinity,
      category: 'Home',
      description: 'hello this is short expert here and I hope that you connect with me.',
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
    ),
        ExpertModel(
      name: 'Dr. Ahmed Al-Sayed',
      title: 'Psychologist',
      imageUrl: 'assets/images/img1.jpg',
      rating: 4.9,
      price: double.infinity,
      category: 'Home',
      description: 'hello this is short expert here and I hope that you connect with me.',
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
    ),
        ExpertModel(
      name: 'Dr. Ahmed Al-Sayed',
      title: 'Psychologist',
      imageUrl: 'assets/images/img1.jpg',
      rating: 4.9,
      price: double.infinity,
      category: 'Home',
      description: 'hello this is short expert here and I hope that you connect with me.',
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
    ),
    ExpertModel(
      name: 'Amina Yusuf',
      title: 'Career Coach',
      imageUrl: 'assets/images/img2.jpg',
      rating: 4.7,
      category: 'Top',
      price: double.infinity,
      description: 'Helping professionals grow in their careers and achieve goals.',
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
    ),
    ExpertModel(
      name: 'Amina Yusuf',
      title: 'Career Coach',
      imageUrl: 'assets/images/img2.jpg',
      rating: 4.7,
      category: 'Top',
      price: double.infinity,
      description: 'Helping professionals grow in their careers and achieve goals.',
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
    ),
    ExpertModel(
      name: 'Amina Yusuf',
      title: 'Career Coach',
      imageUrl: 'assets/images/img2.jpg',
      rating: 4.7,
      category: 'Top',
      price: double.infinity,
      description: 'Helping professionals grow in their careers and achieve goals.',
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
    ),
    ExpertModel(
      name: 'Amina Yusuf',
      title: 'Career Coach',
      imageUrl: 'assets/images/img2.jpg',
      rating: 4.7,
      category: 'Top',
      price: double.infinity,
      description: 'Helping professionals grow in their careers and achieve goals.',
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
    ),
    ExpertModel(
      name: 'Dr. Sara Khan',
      title: 'Child Therapist',
      imageUrl: 'assets/images/img3.jpg',
      rating: 4.8,
      category: 'wellness',
      price: double.infinity,
      description: 'Expert in child psychology and behavior development support.',
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
    ),
    ExpertModel(
      name: 'Dr. Sara Khan',
      title: 'Child Therapist',
      imageUrl: 'assets/images/img3.jpg',
      rating: 4.8,
      category: 'wellness',
      price: double.infinity,
      description: 'Expert in child psychology and behavior development support.',
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
    ),
    ExpertModel(
      name: 'Dr. Sara Khan',
      title: 'Child Therapist',
      imageUrl: 'assets/images/img3.jpg',
      rating: 4.8,
      category: 'wellness',
      price: double.infinity,
      description: 'Expert in child psychology and behavior development support.',
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
    ),
    ExpertModel(
      name: 'Dr. Sara Khan',
      title: 'Child Therapist',
      imageUrl: 'assets/images/img3.jpg',
      rating: 4.8,
      category: 'wellness',
      price: double.infinity,
      description: 'Expert in child psychology and behavior development support.',
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
    ),
    ExpertModel(
      name: 'Dr. Sara Khan',
      title: 'Child Therapist',
      imageUrl: 'assets/images/img3.jpg',
      rating: 4.8,
      category: 'wellness',
      price: double.infinity,
      description: 'Expert in child psychology and behavior development support.',
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
    ),
    ExpertModel(
      name: 'Dr. Sara Khan',
      title: 'Child Therapist',
      imageUrl: 'assets/images/img3.jpg',
      rating: 4.8,
      category: 'wellness',
      price: double.infinity,
      description: 'Expert in child psychology and behavior development support.',
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
    ),

    // You can replicate this for the remaining 15 experts
    // Example for 4th:
    ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'career',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
      about: '10+ years of fashion consulting experience.', 
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
    ),
     ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'career',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
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
    ),
     ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'career',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
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
    ),
     ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'career',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
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
    ),
     ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'career',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
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
    ),
     ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'career',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
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
    ),
      ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'fashion',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
      about: '10+ years of fashion consulting experience.', 
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
    ),
    ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'fashion',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
      about: '10+ years of fashion consulting experience.', 
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
    ),
    ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'fashion',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
      about: '10+ years of fashion consulting experience.', 
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
    ),
    ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'fashion',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
      about: '10+ years of fashion consulting experience.', 
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
    ),
    ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'fashion',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
      about: '10+ years of fashion consulting experience.', 
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
    ),
    ExpertModel(
      name: 'Omar El-Sherif',
      title: 'Financial Advisor',
      imageUrl: 'assets/images/img4.jpg',
      rating: 4.6,
      category: 'fashion',
      price: double.infinity,
      description: 'Guiding smart investments and personal finance strategies.',
      about: '10+ years of fashion consulting experience.', 
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
    ),
    
    
  ];

