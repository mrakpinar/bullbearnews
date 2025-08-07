// import 'package:bullbearnews/screens/profile/edit_profile_screen.dart';
import 'package:bullbearnews/screens/profile/shown_profile_screen.dart';
import 'package:bullbearnews/widgets/profile/bio_edit_dialog.dart';
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
    const defaultImageUrl =
        "https://isobarscience.com/wp-content/uploads/2020/09/default-profile-picture1.jpg";

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Sadece Firebase'den çek
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

  Widget _buildStatItem(
      String label, int count, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              _isLoadingStats ? '-' : count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF948979),
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
      ),
    );
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

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF393E46),
                              const Color(0xFF948979),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF222831),
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Users List
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _loadUsersList(isFollowersList),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading users',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        );
                      }

                      final users = snapshot.data ?? [];

                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isFollowersList
                                    ? 'No followers yet'
                                    : 'Not following anyone yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.black.withOpacity(0.7),
                                  fontFamily: 'DMSerif',
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserListItem(user, isDark);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Takipçi/takip edilen listesini yükle
  Future<List<Map<String, dynamic>>> _loadUsersList(
      bool isFollowersList) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final userIds = isFollowersList
          ? (userData['followers'] as List?) ?? []
          : (userData['following'] as List?) ?? [];

      if (userIds.isEmpty) return [];

      // Kullanıcı bilgilerini çek
      List<Map<String, dynamic>> users = [];
      for (String userId in userIds) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (doc.exists) {
            final data = doc.data()!;
            data['id'] = userId;
            users.add(data);
          }
        } catch (e) {
          print('Error loading user $userId: $e');
        }
      }

      return users;
    } catch (e) {
      print('Error loading users list: $e');
      return [];
    }
  }

  // Kullanıcı list item widget'i
  Widget _buildUserListItem(Map<String, dynamic> user, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF948979).withOpacity(0.3),
          backgroundImage: user['profileImageUrl'] != null &&
                  user['profileImageUrl'].toString().isNotEmpty
              ? NetworkImage(user['profileImageUrl'])
              : null,
          child: user['profileImageUrl'] == null ||
                  user['profileImageUrl'].toString().isEmpty
              ? Icon(
                  Icons.person,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                )
              : null,
        ),
        title: Text(
          user['name'] ?? 'Unknown User',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'DMSerif',
          ),
        ),
        subtitle: Text(
          user['nickname'] != null ? '@${user['nickname']}' : 'No nickname',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF948979),
            fontFamily: 'DMSerif',
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark
                ? Colors.white.withOpacity(0.5)
                : Colors.black.withOpacity(0.5),
          ),
          onPressed: () {
            Navigator.pop(context);
            // Kullanıcı profiline git
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShownProfileScreen(userId: user['id']),
              ),
            );
          },
        ),
        onTap: () {
          Navigator.pop(context);
          // Kullanıcı profiline git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShownProfileScreen(userId: user['id']),
            ),
          );
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: isDark
            ? const Color(0xFF393E46).withOpacity(0.3)
            : Colors.white.withOpacity(0.7),
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
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: () => _seeFullSizeOfImage(),
                        child: Container(
                          width: 80,
                          height: 80,
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
                                    // Cache parametresi eklendi
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                      Icons.person,
                                      size: 35,
                                      color: isDarkMode
                                          ? const Color(0xFFDFD0B8)
                                          : const Color(0xFF222831),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 35,
                                    color: isDarkMode
                                        ? const Color(0xFFDFD0B8)
                                        : const Color(0xFF222831),
                                  ),
                          ),
                        ),
                      ),
                      // Add icon butonu
                      Positioned(
                        right: -1,
                        bottom: -14,
                        child: Container(
                          width: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF948979),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDarkMode
                                  ? const Color(0xFF393E46)
                                  : const Color(0xFFF5F5F5),
                              width: 5,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.add_a_photo,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: _uploadProfileImage,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      )
                    ],
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
                        // OutlinedButton(
                        //   onPressed: () => Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) =>
                        //             const EditProfileScreen()),
                        //   ),
                        //   style: OutlinedButton.styleFrom(
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(12),
                        //     ),
                        //     side: BorderSide(
                        //       color: const Color(0xFF948979).withOpacity(0.3),
                        //     ),
                        //     minimumSize: const Size(0, 32),
                        //     padding: const EdgeInsets.symmetric(
                        //         horizontal: 16, vertical: 6),
                        //   ),
                        //   child: Text(
                        //     'Edit Profile',
                        //     style: TextStyle(
                        //       color: isDarkMode
                        //           ? const Color(0xFFDFD0B8)
                        //           : const Color(0xFF222831),
                        //       fontFamily: 'DMSerif',
                        //       fontSize: 13,
                        //     ),
                        //   ),
                        // ),
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
                    _buildStatItem('Followers', _followersCount, isDarkMode,
                        _showFollowersList),
                    Container(
                      width: 2,
                      height: 30,
                      color: const Color(0xFF948979).withOpacity(0.3),
                    ),
                    _buildStatItem('Following', _followingCount, isDarkMode,
                        _showFollowingList),
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
