import 'package:flutter/material.dart';
import 'package:shourk_application/features/expert_profile/expert_detail_screen.dart';
// Screens
import 'package:shourk_application/user/user_login.dart';
import 'package:shourk_application/user/user_register.dart';
import 'package:shourk_application/expert/home/expert_home_screen.dart';
import 'package:shourk_application/expert/profile/expert_profile_screen.dart';
import 'package:shourk_application/user/home/home_screen.dart';

import 'expert/profile/edit_profile_screen.dart';
import 'expert/profile/code_option.dart';
import 'expert/profile/giftcard_form_option.dart';
import 'expert/profile/giftcard_selection_option.dart';
import 'expert/profile/payment_option.dart';

// import 'package:shourk_application/expert/screens/search_experts_screen.dart';
// import 'package:shourk_application/expert/screens/video_call_screen.dart';
// import 'package:shourk_application/expert/screens/expert_screen.dart';
// import 'package:shourk_application/expert/screens/dashboard_screen.dart';

import 'package:shourk_application/expert/expert_category/top_expert.dart';
import 'package:shourk_application/expert/expert_category/home_expert.dart';
import 'package:shourk_application/expert/expert_category/career_expert.dart';
import 'package:shourk_application/expert/expert_category/fashion_expert.dart';
import 'package:shourk_application/expert/expert_category/wellness_expert.dart';

import 'start_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shourk Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      /// 👇 Temporary Home Screen (will be changed later with auth logic)
      initialRoute: '/expert-home',

      routes: {
        '/start': (context) => const StartPage(),

        '/user-login': (context) => const UserLogin(),
        '/user-register': (context) => const RegisterPage(),

        // Expert Routes
        '/home': (context) => const HomeScreen(), 
        'expert-home': (context) => const ExpertHomeScreen(), // 👈 Default for now
        // '/search': (context) => const SearchExpertsPage(),
        // '/video-call': (context) => const VideoCallPage(),
        '/profile': (context) => const ExpertProfilePage(),
        // '/expert': (context) => const ExpertPage(),
        // '/dashboard': (context) => const DashboardPage(),
        '/edit-profile': (context) => const EditProfileScreen(),
        // '/expert-detail': (context) => const ExpertDetailScreen(),

        // Profile pages option pages routes !!
          '/payment-method': (context) => const PaymentMethodPage(),
          '/have-code': (context) => const HaveCodePage(),
          '/gift-card-select': (context) => const GiftCardSelectPage(),
          '/gift-card-form': (context) => const GiftCardFormPage(),


        //Expert Category screens !!
          '/top-experts': (context) => TopExpertsScreen(),
          '/home-experts': (context) => HomeExpertsScreen(),
          '/career-experts': (context) => CareerExpertsScreen(),
          '/fashion-experts': (context) => FashionBeautyExpertsScreen(),
         '/wellness-experts': (context) => WellnessExpertsScreen(),
      },
    );
  }
}




