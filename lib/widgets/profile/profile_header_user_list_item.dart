import 'package:bullbearnews/screens/profile/shown_profile_screen.dart';
import 'package:flutter/material.dart';

class ProfileHeaderUserListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final String defaultImagePath;
  const ProfileHeaderUserListItem(
      {super.key,
      required this.user,
      required this.isDark,
      required this.defaultImagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF948979).withOpacity(0.3),
          backgroundImage: user['profileImageUrl'] != null &&
                  user['profileImageUrl'].toString().isNotEmpty
              ? NetworkImage(user['profileImageUrl'])
              : AssetImage(defaultImagePath) as ImageProvider,
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
}
