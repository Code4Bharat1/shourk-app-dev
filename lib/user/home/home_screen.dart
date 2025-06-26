// // 📁 lib/user/home/home_screen.dart
// import 'package:flutter/material.dart';
// import '../../shared/widgets/expert_card.dart';
// import '../../shared/models/expert_model.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final categories = [
//       'Top Experts',
//       'Home',
//       'Beauty & Fashion',
//       'Career & Business',
//       'Wellness',
//       'Education',
//       'Finance',
//       'Tech',
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('SHOURK'),
//         actions: [
//           IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
//           IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(12),
//         children: [
//           SizedBox(
//             height: 80,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: categories.length,
//               itemBuilder: (context, index) {
//                 return GestureDetector(
//                   onTap: () {
//                     // TODO: Navigate to filtered category
//                   },
//                   child: Container(
//                     margin: const EdgeInsets.only(right: 10),
//                     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(14),
//                       color: Colors.grey[200],
//                     ),
//                     child: Center(
//                       child: Text(
//                         categories[index],
//                         style: const TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           const SizedBox(height: 20),
//           ...categories.map((category) => Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 8, top: 16, right: 8),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           category,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             // TODO: Navigate to see all
//                           },
//                           child: const Text("See all →"),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(
//                     height: 220,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: dummyExperts.length + 1, // extra card
//                       itemBuilder: (context, index) {
//                         if (index < dummyExperts.length) {
//                           return Padding(
//                             padding: const EdgeInsets.only(right: 12),
//                             child: ExpertCard(expert: dummyExperts[index]),
//                           );
//                         } else {
//                           return Opacity(
//                             opacity: 0.3,
//                             child: Container(
//                               width: 160,
//                               margin: const EdgeInsets.only(right: 12),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                             ),
//                           );
//                         }
//                       },
//                     ),
//                   ),
//                 ],
//               )),
//           const SizedBox(height: 20),
//           const Center(
//             child: Text(
//               '✅ You are connected to the fastest server',
//               style: TextStyle(color: Colors.green),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: 0,
//         selectedItemColor: Colors.black,
//         unselectedItemColor: Colors.black54,
//         backgroundColor: Colors.white,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.video_call), label: 'Calls'),
//           BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Gift'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import '../../shared/widgets/expert_card.dart';
import '../../shared/models/expert_model.dart';
import '../home/category_experts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 3; // fits ~3 cards

    final categories = [
      'Top Experts',
      'Home',
      'Beauty & Fashion',
      'Career and Business',
      'Finance',
      'Health',
      'Technology',
      'Relationships',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SHOURK'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((cat) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryExpertsScreen(categoryName: cat),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: Center(child: Text(cat)),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),
          ...categories.map((category) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(category,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CategoryExpertsScreen(categoryName: category),
                          ),
                        );
                      },
                      child: const Text('See all →'),
                    ),
                  ],
                ),
              ),
              SizedBox(
  height: cardWidth * 4 / 3, // keep the 3:4 aspect ratio
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: dummyExperts.length,
    itemBuilder: (context, index) {
      return Container(
        margin: const EdgeInsets.only(right: 12),
        width: cardWidth,
        child: ExpertCard(expert: dummyExperts[index]),
      );
    },
  ),
),

            ],
          )),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              '✅ You are connected to the fastest server',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.video_call), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Gift'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

