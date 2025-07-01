import 'package:flutter/material.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import '../../shared/models/expert_model.dart';

class ExpertDetailScreen extends StatefulWidget {
  final ExpertModel expert;
  const ExpertDetailScreen({super.key, required this.expert});

  @override
  State<ExpertDetailScreen> createState() => _ExpertDetailScreenState();
}

class _ExpertDetailScreenState extends State<ExpertDetailScreen> {
  String selectedDuration = 'Quick - 15min';
  bool isPlanSelected = false;

  @override
  Widget build(BuildContext context) {
    final expert = widget.expert;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const ExpertUpperNavbar(),
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
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      expert.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(expert.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(expert.title, style: const TextStyle(color: Colors.black54)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange),
                    Text(expert.rating.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("About Me", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(expert.about),
                const SizedBox(height: 12),
                const Text("Strengths", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: expert.strengths
                      .map((s) => Chip(
                            label: Text(s),
                            backgroundColor: Colors.grey[300],
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Book a Video Call"),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.expert.whatToExpect.keys.map((duration) {
                final isSelected = duration == selectedDuration;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDuration = duration;
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.42,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(2, 2))
                      ],
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      duration,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("What To Expect", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: expert.whatToExpect[selectedDuration]!
                        .map((item) => Row(
                              children: [
                                const Text("• ", style: TextStyle(fontSize: 18)),
                                Expanded(child: Text(item)),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("1:1 Consultation Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
                        SizedBox(height: 6),
                        Text("Get a personalized 1:1 session with this expert to dive deep into your goals.", style: TextStyle(fontSize: 13.5, color: Colors.black54)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text("Explore"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Gift a Session", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
                        SizedBox(height: 6),
                        Text("Give the gift of insight. Book a session for your friend or loved one.", style: TextStyle(fontSize: 13.5, color: Colors.black54)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text("Gift"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Reviews", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...expert.reviews.map((review) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(review.reviewerImage),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(review.reviewerTitle, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(review.rating.toInt(), (index) => const Icon(Icons.star, size: 16, color: Colors.orange)),
                          ),
                          const SizedBox(height: 6),
                          Text(review.comment),
                        ],
                      ),
                    )),
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
                        const Text("\$49 / session", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.orange, size: 18)),
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
                      backgroundColor: isPlanSelected ? Colors.blue : Colors.white,
                      foregroundColor: isPlanSelected ? Colors.white : Colors.black,
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
      bottomNavigationBar: ExpertBottomNavbar(
        currentIndex: 2,
        onTap: (index) {},
      ),
    );
  }
}
