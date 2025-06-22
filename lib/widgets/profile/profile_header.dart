import 'package:bullbearnews/screens/profile/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader(ThemeData theme, {super.key});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    const defaultImageUrl =
        "https://isobarscience.com/wp-content/uploads/2020/09/default-profile-picture1.jpg";

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String? imageUrl;
        if (userDoc.exists &&
            userDoc.data()!.containsKey('profileImageUrl') &&
            userDoc.data()!['profileImageUrl'] != null &&
            userDoc.data()!['profileImageUrl'].toString().trim().isNotEmpty) {
          imageUrl = userDoc.data()!['profileImageUrl'];
        }

        if (imageUrl == null || imageUrl.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final savedImageUrl = prefs.getString('profileImageUrl');
          if (savedImageUrl != null && savedImageUrl.trim().isNotEmpty) {
            imageUrl = savedImageUrl;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'profileImageUrl': savedImageUrl});
          }
        }

        if (mounted) {
          setState(() {
            _profileImageUrl = (imageUrl != null && imageUrl.trim().isNotEmpty)
                ? imageUrl
                : defaultImageUrl;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _profileImageUrl = defaultImageUrl;
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
      if (mounted) {
        setState(() {
          _profileImageUrl = defaultImageUrl;
        });
      }
    }
  }

  Future<void> _seeFullSizeOfImage() async {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _profileImageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    width: 300,
                    height: 300,
                    child: Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // Configure Cloudinary
        final cloudinary = CloudinaryPublic(
            'dh7lpyg7t', // Your Cloudinary cloud name
            'upload_image', // Your upload preset
            cache: false);

        // Upload image to Cloudinary
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            pickedFile.path,
            folder: 'profile_images',
            publicId: 'profile_${FirebaseAuth.instance.currentUser!.uid}',
          ),
        );

        // Save image URL to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageUrl', response.secureUrl);

        // Update user's profile in Firebase Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profileImageUrl': response.secureUrl});
        }

        // Update local state
        setState(() {
          _profileImageUrl = response.secureUrl;
        });

        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: user != null
          ? FirebaseFirestore.instance.collection('users').doc(user.uid).get()
          : null,
      builder: (context, snapshot) {
        // Kullanıcı bilgilerini al
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final nickname = userData?['nickname'] as String?;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [const Color(0xFF393E46), const Color(0xFF393E46)]
                  : [const Color(0xFFF5F5F5), const Color(0xFFF5F5F5)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF393E46).withOpacity(0.3)
                  : const Color(0xFFE0E0E0).withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? const Color(0xFF222831).withOpacity(0.3)
                    : const Color(0xFFDFD0B8).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profil resmi ve add icon
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: () => _seeFullSizeOfImage(),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF948979).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _profileImageUrl != null
                            ? Image.network(
                                _profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.person,
                                  size: 40,
                                  color: isDarkMode
                                      ? const Color(0xFFDFD0B8)
                                      : const Color(0xFF222831),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 40,
                                color: isDarkMode
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                              ),
                      ),
                    ),
                  ),
                  // Add icon butonu
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: IconButton(
                      icon: Icon(
                        Icons.add_a_photo,
                        size: 24,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF393E46),
                      ),
                      onPressed: _uploadProfileImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Guest User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    Text(
                      nickname != null ? '@$nickname' : 'No nickname',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF948979),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   user?.email ?? 'Not logged in',
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     color: const Color(0xFF948979),
                    //     fontFamily: 'DMSerif',
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: const Color(0xFF948979).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
