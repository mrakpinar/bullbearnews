import 'package:bullbearnews/widgets/community/chat_room_card.dart';
import 'package:flutter/material.dart';
import '../../../models/chat_room_model.dart';
import '../../../services/chat_service.dart';

class ChatRoomsTab extends StatelessWidget {
  const ChatRoomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive grid parameters
    int crossAxisCount;
    double childAspectRatio;
    double horizontalPadding;
    double spacing;

    if (screenWidth < 350) {
      // Very small phones
      crossAxisCount = 1;
      childAspectRatio = 1.2;
      horizontalPadding = 12;
      spacing = 12;
    } else if (screenWidth < 400) {
      // Small phones
      crossAxisCount = 2;
      childAspectRatio = 0.75;
      horizontalPadding = 16;
      spacing = 12;
    } else if (screenWidth < 600) {
      // Normal phones
      crossAxisCount = 2;
      childAspectRatio = 0.85;
      horizontalPadding = 16;
      spacing = 16;
    } else if (screenWidth < 900) {
      // Large phones / small tablets
      crossAxisCount = 3;
      childAspectRatio = 0.8;
      horizontalPadding = 20;
      spacing = 16;
    } else {
      // Tablets
      crossAxisCount = 4;
      childAspectRatio = 0.9;
      horizontalPadding = 24;
      spacing = 20;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: StreamBuilder<List<ChatRoom>>(
        stream: ChatService().getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isDark);
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(isDark, screenWidth);
          }

          final chatRooms = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger a rebuild by calling the stream again
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            backgroundColor:
                isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header info
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? const Color(0xFF393E46) : Colors.white)
                              .withOpacity(0.8),
                          (isDark
                                  ? const Color(0xFF948979)
                                  : const Color(0xFF393E46))
                              .withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF948979).withOpacity(0.2)
                            : const Color(0xFF393E46).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.forum,
                            color: const Color(0xFFDFD0B8),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chat Rooms',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFDFD0B8)
                                      : const Color(0xFF222831),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'DMSerif',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${chatRooms.length} rooms available',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF948979)
                                      : const Color(0xFF393E46),
                                  fontSize: 14,
                                  fontFamily: 'DMSerif',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Live',
                                style: TextStyle(
                                  color: const Color(0xFF4CAF50),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'DMSerif',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Chat rooms grid
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        curve: Curves.easeOutBack,
                        child: ChatRoomCard(
                          room: chatRooms[index],
                          isDark: isDark,
                        ),
                      );
                    },
                    childCount: chatRooms.length,
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF393E46).withOpacity(0.3),
                  const Color(0xFF948979).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading chat rooms...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch the latest rooms',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF948979).withOpacity(0.7)
                  : const Color(0xFF393E46).withOpacity(0.7),
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, double screenWidth) {
    final iconSize = screenWidth < 360 ? 56.0 : 64.0;
    final titleSize = screenWidth < 360 ? 18.0 : 20.0;
    final subtitleSize = screenWidth < 360 ? 12.0 : 14.0;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? const Color(0xFF393E46) : Colors.white)
                        .withOpacity(0.8),
                    (isDark ? const Color(0xFF948979) : const Color(0xFF393E46))
                        .withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF948979).withOpacity(0.3)
                      : const Color(0xFF393E46).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: iconSize,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Chat Rooms Yet',
              style: TextStyle(
                fontSize: titleSize,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Chat rooms will appear here when they become available. Pull down to refresh and check for new rooms.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: isDark
                      ? const Color(0xFF948979)
                      : const Color(0xFF393E46),
                  fontFamily: 'DMSerif',
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color:
                    (isDark ? const Color(0xFF948979) : const Color(0xFF393E46))
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF948979)
                      : const Color(0xFF393E46),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pull to refresh',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                      fontFamily: 'DMSerif',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
