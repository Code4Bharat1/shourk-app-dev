
import 'package:flutter/material.dart';
import 'package:shourk_application/features/expert_profile/expert_detail_screen.dart';
// Screens
import 'package:shourk_application/login.dart';
import 'package:shourk_application/register_page.dart';
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
      initialRoute: '/home',

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),

        // Expert Routes
        '/home': (context) => const HomeScreen(),  // 👈 Default for now
        // '/search': (context) => const SearchExpertsPage(),
        // '/video-call': (context) => const VideoCallPage(),
        '/profile': (context) => const ExpertProfilePage(),
        // '/expert': (context) => const ExpertPage(),
        // '/dashboard': (context) => const DashboardPage(),
        '/edit-profile': (context) => const EditProfileScreen(),
        // '/expert-detail': (context) => const ExpertDetailScreen(expert:),

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





// import 'package:flutter/material.dart';
// import 'package:shourk_application/expert/home/expert_home_screen.dart';
// import 'package:shourk_application/login.dart';
// import 'register_page.dart'; // Make sure this matches your filename
// import 'login.dart';
// import 'expert/sessions/book_session.dart';
// import 'user/home/home_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
  
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Register Page',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }


