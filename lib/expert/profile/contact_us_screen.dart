import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Container(
            margin: const EdgeInsets.only(top: 40),
            padding: const EdgeInsets.only(bottom: 32),
            child: _buildGrid(constraints),
          ),
        );
      },
    );
  }

  Widget _buildGrid(BoxConstraints constraints) {
    // Determine grid columns based on screen width
    int crossAxisCount = 1;
    if (constraints.maxWidth >= 1024) {
      crossAxisCount = 3; // lg:grid-cols-3
    } else if (constraints.maxWidth >= 768) {
      crossAxisCount = 2; // md:grid-cols-2
    } else {
      crossAxisCount = 1; // sm:grid-cols-1
    }

    // Determine gap based on screen width
    double gap = constraints.maxWidth >= 1024 ? 40 : 24; // lg:gap-10 : gap-6

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      childAspectRatio: 1.2,
      children: [
        _buildSocialMediaCard(),
        _buildChatSupportCard(),
        _buildEmailCard(),
      ],
    );
  }

  Widget _buildSocialMediaCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 384), // max-w-md
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(
          color: const Color(0xFFA6A6A6), // border-[#A6A6A6]
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // text-start
        children: [
          // Icon container
          Container(
            margin: const EdgeInsets.only(bottom: 16), // mb-4
            child: Image.asset(
              'assets/images/socialmediaicon.png',
              width: 40, // w-10
              height: 40, // h-10
            ),
          ),
          
          // Title
          const Text(
            'Our Social Media',
            style: TextStyle(
              fontSize: 20, // text-xl
              fontWeight: FontWeight.w600, // font-semibold
              color: Colors.black,
            ),
          ),
          
          // Description
          Container(
            margin: const EdgeInsets.only(top: 8), // mt-2
            child: const Text(
              'We\'d love to hear from you.',
              style: TextStyle(
                color: Color(0xFF374151), // text-gray-700
              ),
            ),
          ),
          
          // Social Icons
          Container(
            margin: const EdgeInsets.only(top: 16), // mt-4
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _launchSocialMedia('instagram'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8), // mx-2
                    child: const Icon(
                      Icons.camera_alt, // Instagram icon alternative
                      color: Colors.black,
                      size: 24, // text-3xl equivalent
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _launchSocialMedia('twitter'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8), // mx-2
                    child: const Icon(
                      Icons.chat_bubble, // Twitter icon alternative
                      color: Colors.black,
                      size: 24, // text-3xl equivalent
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSupportCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 384), // max-w-md
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(
          color: const Color(0xFFA6A6A6), // border-[#A6A6A6]
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // text-left
        children: [
          // Icon container
          Container(
            margin: const EdgeInsets.only(bottom: 16), // mb-4
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive icon size: w-8 h-8 md:w-10 md:h-10
                double iconSize = constraints.maxWidth >= 768 ? 40 : 32;
                return Image.asset(
                  'assets/images/chaticon.png',
                  width: iconSize,
                  height: iconSize,
                );
              },
            ),
          ),
          
          // Title
          const Text(
            'Chat to Support',
            style: TextStyle(
              fontSize: 20, // text-xl
              fontWeight: FontWeight.w600, // font-semibold
              color: Colors.black,
            ),
          ),
          
          // Description
          Container(
            margin: const EdgeInsets.only(top: 8), // mt-2
            child: const Text(
              'We\'re here to help',
              style: TextStyle(
                color: Color(0xFF374151), // text-gray-700
              ),
            ),
          ),
          
          // Button
          Container(
            margin: const EdgeInsets.only(top: 12), // mt-3
            child: OutlinedButton(
              onPressed: () => _launchChatSupport(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // rounded-xl
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, // px-4
                  vertical: 8, // py-2
                ),
              ),
              child: const Text('Chat to Support'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 384), // max-w-md
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(
          color: const Color(0xFFA6A6A6), // border-[#A6A6A6]
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // text-left
        children: [
          // Icon container
          Container(
            margin: const EdgeInsets.only(bottom: 16), // mb-4
            child: const Icon(
              Icons.alternate_email, // MdAlternateEmail equivalent
              color: Colors.black,
              size: 32, // text-4xl equivalent
            ),
          ),
          
          // Title
          const Text(
            'Leave us a Mail',
            style: TextStyle(
              fontSize: 20, // text-xl
              fontWeight: FontWeight.w600, // font-semibold
              color: Colors.black,
            ),
          ),
          
          // Description
          Container(
            margin: const EdgeInsets.only(top: 8), // mt-2
            child: const Text(
              'If not available, you can send us an email at',
              style: TextStyle(
                color: Color(0xFF374151), // text-gray-700
                fontSize: 14, // text-sm
              ),
            ),
          ),
          
          // Email
          Container(
            margin: const EdgeInsets.only(top: 8), // mt-2
            child: const Text(
              'hi@amd.com',
              style: TextStyle(
                fontWeight: FontWeight.w600, // font-semibold
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchSocialMedia(String platform) async {
    final urls = {
      'instagram': 'https://instagram.com',
      'twitter': 'https://twitter.com',
    };

    if (urls.containsKey(platform)) {
      final uri = Uri.parse(urls[platform]!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _launchChatSupport() {
    // Implement chat support functionality
    // This could open a chat widget, navigate to a chat screen, etc.
    print('Opening chat support...');
  }
}