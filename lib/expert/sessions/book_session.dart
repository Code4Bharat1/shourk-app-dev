import 'package:flutter/material.dart';
// import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {   
    return MaterialApp(
      title: 'AMD Consultation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ConsultationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ConsultationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Import your custom AppBar here: appBar: CustomAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            
            // Book a Video Call Section 1
            _buildVideoCallCard(
              title: '1:1 Video Consultation',
              subtitle: 'Book a 1:1 video consultation to get personalized advice',
              price: 'Starting at ₹555',
              rating: '4.9',
              users: '1M+',
            ),        
            SizedBox(height: 16),
            
            // Select Plan #1
            _buildPlanCard(
              planNumber: '1',
              title: 'Growing & Successful Business - 1:1 Mentoring (Viral Growth)',
              price: '₹5999 / month',
              features: [
                '• Virtual Mentorship',
                '• 1-3 Days Call (45 Min) (Weekly)',
                '• 24/7 Support Via Call & Chat',
                '• Session Recording, Feedback, Goal Mentorship and Guidance All Year',
                '• Free',
                '• How To Launch Start From A Successful Product Launch',
                '• Live Session Recording So that You Continue Practicing and Many More...',
              ],
            ),
            
            SizedBox(height: 16),
            
            // Select Plan #2
            _buildPlanCard(
              planNumber: '2',
              title: 'Growing & Successful Business - 1:1 Mentoring (Viral Growth)',
              price: '₹3999 / month',
              features: [
                '• Virtual Mentorship',
                '• 1-3 Days Call (45 Min) (Weekly)',
                '• 24/7 Support Via Call & Chat',
                '• Session Recording, Feedback, Goal Mentorship and Guidance All Year',
                '• Free',
                '• How To Launch Start From A Successful Product Launch',
                '• Live Session Recording So that You Continue Practicing and Many More...',
              ],
            ),
            
            SizedBox(height: 16),
            
            // Send a Gift Card Section
            _buildGiftCardSection(),
            
            SizedBox(height: 20),
          ],
        ),
      ),
      // bottomNavigationBar: ExpertBottomNavbar(),
    );
  }
  
  Widget _buildVideoCallCard({
    required String title,
    required String subtitle,
    String? price,
    String? rating,
    String? users,
    bool showPrice = true,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book a Video Call',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
          if (showPrice && price != null) ...[
            SizedBox(height: 10),
            Text(
              price,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (rating != null) ...[
            SizedBox(height: 10),
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
                SizedBox(width: 8),
                Text(
                  rating,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
          if (users != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                SizedBox(width: 6),
                Text(
                  users,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Book Slots',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlanCard({
    required String planNumber,
    required String title,
    required String price,
    required List<String> features,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Select Plan #$planNumber',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          SizedBox(height: 12),
          ...features.map((feature) => Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          )).toList(),
          SizedBox(height: 12),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
              SizedBox(width: 8),
              Text(
                '4.9',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Select',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGiftCardSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send a Gift Card',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Gift an Card',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Send a gift card to someone by inviting friends & family',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Select',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}