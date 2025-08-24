import 'package:bullbearnews/widgets/profile/profile_header_user_list_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileHeaderUserList extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final bool isFollowersList;
  final ScrollController scrollController;
  final String defaultImagePath;

  const ProfileHeaderUserList({
    super.key,
    required this.isDark,
    required this.title,
    required this.icon,
    required this.isFollowersList,
    required this.scrollController,
    required this.defaultImagePath,
  });

  @override
  Widget build(BuildContext context) {
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
                    return ProfileHeaderUserListItem(
                      user: user,
                      isDark: isDark,
                      defaultImagePath: defaultImagePath,
                    );
                  },
                );
              },
            ),
          ),
        ],
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
}
