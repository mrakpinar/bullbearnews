// import 'package:bullbearnews/screens/profile/edit_profile_screen.dart';
import 'package:bullbearnews/widgets/profile/bio_edit_dialog.dart';
import 'package:bullbearnews/widgets/profile/profile_header_stat_item.dart';
import 'package:bullbearnews/widgets/profile/profile_header_user_list.dart';
import 'package:bullbearnews/widgets/profile/profile_picture_add_icon_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader(ThemeData theme, {super.key});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  String? _profileImageUrl;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoadingStats = true;

  // Local default image path
  static const String _defaultImagePath =
      'assets/image/default_profile_image.png';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        setState(() {
          _followersCount = (userData['followers'] as List?)?.length ?? 0;
          _followingCount = (userData['following'] as List?)?.length ?? 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadProfileImage() async {
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

        if (mounted) {
          setState(() {
            _profileImageUrl = (imageUrl != null && imageUrl.trim().isNotEmpty)
                ? imageUrl
                : null; // null olarak ayarlıyoruz ki default image asset'i kullanılsın
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _profileImageUrl = null; // Default asset image kullanılacak
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
      if (mounted) {
        setState(() {
          _profileImageUrl = null; // Default asset image kullanılacak
        });
      }
    }
  }

  Future<void> _seeFullSizeOfImage() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? Image.network(
                      _profileImageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        _defaultImagePath,
                        fit: BoxFit.contain,
                        width: 300,
                        height: 300,
                      ),
                    )
                  : Image.asset(
                      _defaultImagePath,
                      fit: BoxFit.contain,
                      width: 300,
                      height: 300,
                    ),
            ),
          ),
        ),
      ),
    );
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

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          Navigator.of(context).pop();
          return;
        }

        // Configure Cloudinary
        final cloudinary = CloudinaryPublic(
            'dh7lpyg7t', // Your Cloudinary cloud name
            'upload_image', // Your upload preset
            cache: false);

        // Benzersiz publicId oluştur (timestamp ekleyerek)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final publicId = 'profile_${user.uid}_$timestamp';

        // Upload image to Cloudinary
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            pickedFile.path,
            folder: 'profile_images',
            publicId: publicId,
          ),
        );

        // Firebase'e yeni URL'i kaydet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'profileImageUrl': response.secureUrl,
          'profileImageUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Update local state
        if (mounted) {
          setState(() {
            _profileImageUrl = response.secureUrl;
          });
        }

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated successfully')),
          );
        }
      } catch (e) {
        print('Error uploading image: $e');

        // Close loading dialog
        if (mounted) {
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
  }

  // Takipçiler listesini göster
  void _showFollowersList() {
    _showUsersList(
      title: 'Followers',
      icon: Icons.people,
      isFollowersList: true,
    );
  }

  // Takip edilenler listesini göster
  void _showFollowingList() {
    _showUsersList(
      title: 'Following',
      icon: Icons.person_add,
      isFollowersList: false,
    );
  }

  // Kullanıcı listesi bottom sheet'i
  void _showUsersList({
    required String title,
    required IconData icon,
    required bool isFollowersList,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return ProfileHeaderUserList(
            isDark: isDark,
            title: title,
            icon: icon,
            isFollowersList: isFollowersList,
            scrollController: scrollController,
            defaultImagePath: _defaultImagePath,
          );
        },
      ),
    );
  }

  // Bio Edit Dialog'unu göster
  void _showBioEditDialog(String currentBio) {
    showDialog(
      context: context,
      builder: (context) => BioEditDialog(
        currentBio: currentBio,
        onBioUpdated: () {
          setState(() {
            // ProfileHeader'ı yeniden yükle
          });
        },
      ),
    );
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
        final bio = userData?['bio'] as String? ?? '';

        return Container(
          padding: const EdgeInsets.all(20),
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
                  ? const Color(0xFFE0E0E0).withOpacity(0.3)
                  : const Color(0xFF393E46).withOpacity(0.5),
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
          child: Column(
            children: [
              Row(
                children: [
                  // Profil resmi ve add icon
                  ProfilePictureAddIconWidget(
                    isDarkMode: isDarkMode,
                    defaultImagePath: _defaultImagePath,
                    profileImageUrl: _profileImageUrl ?? '',
                    seeFullSizeOfImage: _seeFullSizeOfImage,
                    uploadProfileImage: _uploadProfileImage,
                  ),
                  const SizedBox(width: 20),
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
                        const SizedBox(height: 4),
                        Text(
                          nickname != null ? '@$nickname' : 'No nickname',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF948979),
                            fontFamily: 'DMSerif',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),

              // Bio Section
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF222831).withOpacity(0.3)
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF948979).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    bio,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                      height: 1.4,
                    ),
                  ),
                ),
              ],

              // Bio Edit Button
              if (bio.isEmpty) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _showBioEditDialog(bio),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF222831).withOpacity(0.3)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF948979).withOpacity(0.2),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          color: const Color(0xFF948979),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add bio',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF948979),
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showBioEditDialog(bio),
                    icon: Icon(
                      Icons.edit,
                      size: 16,
                      color: const Color(0xFF948979),
                    ),
                    label: Text(
                      'Edit bio',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF948979),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Takipçi ve Takip Edilen Sayıları
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF222831).withOpacity(0.5)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF948979).withOpacity(0.8)
                        : const Color(0xFFE0E0E0).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ProfileHeaderStatItem(
                      label: 'Followers',
                      count: _followersCount,
                      isDark: isDarkMode,
                      onTap: _showFollowersList,
                      isLoadingStats: _isLoadingStats,
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      color: const Color(0xFF948979).withOpacity(0.3),
                    ),
                    ProfileHeaderStatItem(
                      label: 'Following',
                      count: _followingCount,
                      isDark: isDarkMode,
                      onTap: _showFollowingList,
                      isLoadingStats: _isLoadingStats,
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
