import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileHeader extends StatelessWidget {
  final User? user;
  final VoidCallback? onImageUpload;
  final String? profileImageUrl;

  const UserProfileHeader({
    super.key,
    required this.user,
    this.onImageUpload,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _buildHeader(context, 0, 0);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildHeader(context, 0, 0);
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final followers = (userData['followers'] as List? ?? []).length;
        final following = (userData['following'] as List? ?? []).length;

        return _buildHeader(context, followers, following);
      },
    );
  }

  Widget _buildHeader(BuildContext context, int followers, int following) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () {
              // Show options to change profile picture
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Change Profile Picture'),
                    content: const Text('Choose an option'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Handle camera option
                          Navigator.of(context).pop();
                        },
                        child: const Text('Camera'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Handle gallery option
                          Navigator.of(context).pop();
                        },
                        child: const Text('Gallery'),
                      ),
                    ],
                  );
                },
              );
            },
            onTap: onImageUpload,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(
                          profileImageUrl!,
                          scale: 1.0,
                        )
                      : null,
                  child: profileImageUrl == null
                      ? Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: -10,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.add_a_photo_sharp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      size: 24,
                      semanticLabel: 'Change Profile Picture',
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 13),
          Text(
            user?.displayName ?? 'User',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
          ),
          const SizedBox(height: 4),
          Text(user?.email ?? 'Not available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  )),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCountInfo(context, 'Followers', followers),
              const SizedBox(width: 24),
              _buildCountInfo(context, 'Following', following),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountInfo(BuildContext context, String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }
}
