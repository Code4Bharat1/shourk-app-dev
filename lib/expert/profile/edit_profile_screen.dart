import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shourk_application/shared/models/expert_model.dart';
import 'package:shourk_application/expert/navbar/expert_bottom_navbar.dart';

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
  // late TextEditingController countryController;
  late TextEditingController dateOfBirthController;
  late TextEditingController aboutMeController;
  late Map<String, TextEditingController> socialControllers;

  List<String> adviceList = [];
  bool notificationsEnabled = false;
  File? profileImage;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.expert?.firstName ?? '');
    lastNameController = TextEditingController(text: widget.expert?.lastName ?? '');
    phoneController = TextEditingController(text: widget.expert?.phone ?? '');
    emailController = TextEditingController(text: widget.expert?.email ?? '');
    areaOfExpertiseController = TextEditingController(text: widget.expert?.areaOfExpertise ?? '');
    // countryController = TextEditingController(text: widget.expert?.country ?? '');
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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
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
      // country: countryController.text,
      dateOfBirth: dateOfBirthController.text,
    );

    print("Updated Expert: ${updated.toJson()}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object> profileProvider;

    if (profileImage != null) {
      profileProvider = FileImage(profileImage!);
    } else if (widget.expert?.photoFile != null && widget.expert!.photoFile!.isNotEmpty) {
      profileProvider = NetworkImage(widget.expert!.photoFile!);
    } else {
      profileProvider = const NetworkImage("https://via.placeholder.com/150");
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickProfileImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: profileProvider,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    TextField(
                      controller: areaOfExpertiseController,
                      decoration: const InputDecoration(labelText: 'Area of Expertise'),
                    ),
                    // TextField(
                    //   controller: countryController,
                    //   decoration: const InputDecoration(labelText: 'Country'),
                    // ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: dateOfBirthController,
                      decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: aboutMeController,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'About'),
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
                          )
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
            ),
            // SwitchListTile(
            //   title: const Text('Enable Notifications'),
            //   value: notificationsEnabled,
            //   onChanged: (val) {
            //     setState(() {
            //       notificationsEnabled = val;
            //     });
            //   },
            // ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: socialControllers.keys.map((key) {
                    return TextField(
                      controller: socialControllers[key],
                      decoration: InputDecoration(labelText: '$key Username'),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveProfile,
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
          bottomNavigationBar: ExpertBottomNavbar(
        currentIndex: 3,
        // onTap: (index) {
        //   // TODO: Implement navigation
        // },
      ),
    );
  }
}
