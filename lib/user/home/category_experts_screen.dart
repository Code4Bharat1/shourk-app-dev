import 'package:flutter/material.dart';
import '../../shared/models/expert_model.dart';
import '../../shared/widgets/expert_card.dart';

class CategoryExpertsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryExpertsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    // Filter experts by category if needed (currently just showing all)
    // You can add category to ExpertModel and filter here accordingly

    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryName Experts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: dummyExperts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            return ExpertCard(expert: dummyExperts[index]);
          },
        ),
      ),
    );
  }
}
