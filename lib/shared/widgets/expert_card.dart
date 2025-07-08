import 'package:flutter/material.dart';
import '../models/expert_model.dart';
import '/features/expert_profile/expert_detail_screen.dart';

class ExpertCard extends StatelessWidget {
  final ExpertModel expert;

  const ExpertCard({super.key, required this.expert});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpertDetailScreen(expertId: expert.id),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.network(  // Changed from Image.asset to Image.network
                    expert.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(color: Colors.grey[300]), // Fallback for image error
                  ),
                ),

                // Top-right price tag
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SAR ${expert.rating >= 4.9 ? "950" : "600"}', 
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Bottom overlay with details
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                expert.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.amber, size: 16),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expert.experience ?? 'No description available', // Fixed null safety issue
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}