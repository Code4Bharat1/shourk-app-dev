import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File handling on mobile
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shourk_application/expert/navbar/expert_upper_navbar.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';
import 'package:shourk_application/shared/models/expert_model.dart';

class EditProfileScreen extends StatefulWidget {
  final ExpertModel? expert;

  const EditProfileScreen({super.key, this.expert});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController areaOfExpertiseController;
  late TextEditingController dateOfBirthController;
  late TextEditingController aboutMeController;
  late Map<String, TextEditingController> socialControllers;

  List<String> adviceList = [];
  bool notificationsEnabled = false;
  File? profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.expert?.firstName ?? '');
    lastNameController = TextEditingController(text: widget.expert?.lastName ?? '');
    phoneController = TextEditingController(text: widget.expert?.phone ?? '');
    emailController = TextEditingController(text: widget.expert?.email ?? '');
    areaOfExpertiseController = TextEditingController(text: widget.expert?.areaOfExpertise ?? '');
    dateOfBirthController = TextEditingController(text: widget.expert?.dateOfBirth ?? '');
    aboutMeController = TextEditingController(text: widget.expert?.experience ?? '');

    adviceList = List.from(widget.expert?.advice ?? []);
    notificationsEnabled = widget.expert?.notificationsEnabled ?? false;

    socialControllers = {
      'instagram': TextEditingController(text: widget.expert?.socialLinks?['instagram'] ?? ''),
      'twitter': TextEditingController(text: widget.expert?.socialLinks?['twitter'] ?? ''),
      'linkedin': TextEditingController(text: widget.expert?.socialLinks?['linkedin'] ?? ''),
      'youtube': TextEditingController(text: widget.expert?.socialLinks?['youtube'] ?? ''),
      'tiktok': TextEditingController(text: widget.expert?.socialLinks?['tiktok'] ?? ''),
    };
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path); // Use dart:io.File type for mobile
      });
    }
  }

  void saveProfile() {
    final updated = ExpertModel(
      id: widget.expert?.id ?? '',
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      title: widget.expert?.title,
      photoFile: widget.expert?.photoFile,
      averageRating: widget.expert?.averageRating ?? 0,
      experience: widget.expert?.experience,
      price: widget.expert?.price ?? 0,
      about: aboutMeController.text,
      strengths: widget.expert?.strengths ?? [],
      whatToExpect: widget.expert?.whatToExpect ?? {},
      reviews: widget.expert?.reviews ?? [],
      category: widget.expert?.category ?? '',
      freeSessionEnabled: widget.expert?.freeSessionEnabled ?? false,
      charityEnabled: widget.expert?.charityEnabled ?? false,
      charityPercentage: widget.expert?.charityPercentage ?? 0,
      designation: widget.expert?.designation,
      advice: adviceList,
      availability: widget.expert?.availability ?? [],
      monthsRange: widget.expert?.monthsRange ?? 1,
      notificationsEnabled: notificationsEnabled,
      socialLinks: {
        'instagram': socialControllers['instagram']?.text ?? '',
        'twitter': socialControllers['twitter']?.text ?? '',
        'linkedin': socialControllers['linkedin']?.text ?? '',
        'youtube': socialControllers['youtube']?.text ?? '',
        'tiktok': socialControllers['tiktok']?.text ?? '',
      },
      phone: phoneController.text,
      email: emailController.text,
      areaOfExpertise: areaOfExpertiseController.text,
      dateOfBirth: dateOfBirthController.text,
    );

    print("Updated Expert: ${updated.toJson()}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully')),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object> profileProvider;

    if (profileImage != null) {
      // Use FileImage with dart:io.File type for mobile
      profileProvider = FileImage(profileImage!);
    } else if (widget.expert?.photoFile != null && widget.expert!.photoFile!.isNotEmpty) {
      profileProvider = NetworkImage(widget.expert!.photoFile!);
    } else {
      profileProvider = const NetworkImage("https://via.placeholder.com/150");
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ExpertUpperNavbar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildTextField("First Name", firstNameController),
                  const SizedBox(height: 16),
                  _buildTextField("Last Name", lastNameController),
                  const SizedBox(height: 16),
                  _buildTextField("Mobile Number", phoneController),
                  const SizedBox(height: 16),
                  _buildTextField("Email", emailController),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Profile'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Things I Can Advise On', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...adviceList.asMap().entries.map((entry) {
                    int index = entry.key;
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: entry.value,
                            onChanged: (value) {
                              setState(() {
                                adviceList[index] = value;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              adviceList.removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        adviceList.add('');
                      });
                    },
                    child: const Text('+ Add Advice'),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: ExpertBottomNavbar(
        currentIndex: 3,
      ),
    );
  }
}
