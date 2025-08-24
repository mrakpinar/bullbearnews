import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSuggestionWidget extends StatelessWidget {
  final String query;
  final String roomId;
  final Function(String userId, String username) onUserSelected;
  final ThemeData theme;

  const UserSuggestionWidget({
    super.key,
    required this.query,
    required this.roomId,
    required this.onUserSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(roomId)
            .snapshots(),
        builder: (context, roomSnapshot) {
          if (!roomSnapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final roomData = roomSnapshot.data!.data() as Map<String, dynamic>;
          final userIds = List<String>.from(roomData['users'] ?? []);

          if (userIds.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No users to mention',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            );
          }

          return FutureBuilder<List<DocumentSnapshot>>(
            future: _getUserDetails(userIds, query),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final users = userSnapshot.data!;

              if (users.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No matching users',
                    style: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  final nickname = userData['nickname'] ?? 'Unknown';
                  final profileImageUrl = userData['profileImageUrl'];

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          profileImageUrl != null && profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null,
                      child: profileImageUrl == null || profileImageUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                    title: Text(
                      nickname,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      '@$nickname',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => onUserSelected(users[index].id, nickname),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _getUserDetails(
      List<String> userIds, String query) async {
    if (userIds.isEmpty) return [];

    // Batch olarak kullanıcı bilgilerini çek
    final futures = userIds.map((userId) =>
        FirebaseFirestore.instance.collection('users').doc(userId).get());

    final userDocs = await Future.wait(futures);

    // Query'ye göre filtrele
    return userDocs.where((doc) {
      if (!doc.exists) return false;
      final userData = doc.data() as Map<String, dynamic>;
      final nickname = (userData['nickname'] ?? '').toString().toLowerCase();
      return nickname.contains(query.toLowerCase());
    }).toList();
  }
}
