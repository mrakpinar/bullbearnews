import 'package:bullbearnews/screens/profile/shown_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final DocumentSnapshot user;
  final bool isDark;
  final int index;

  const UserTile(
      {super.key,
      required this.user,
      required this.isDark,
      required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShownProfileScreen(userId: user.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF393E46),
                        const Color(0xFF948979),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: user['profileImageUrl'] != null &&
                            user['profileImageUrl'].toString().isNotEmpty
                        ? Image.network(
                            user['profileImageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF393E46),
                                      const Color(0xFF948979),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 28,
                                  color: Color(0xFFDFD0B8),
                                ),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: Color(0xFFDFD0B8),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nickname'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF948979)
                              : const Color(0xFF393E46),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF948979).withOpacity(0.2)
                        : const Color(0xFF393E46).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
