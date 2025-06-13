import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/announcement_model.dart';
import '../../models/chat_room_model.dart';
import '../../models/poll_model.dart';
import '../../services/announcement_service.dart';
import '../../services/chat_service.dart';
import '../../services/poll_serivice.dart';
import 'chat_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: const [
                        ChatRoomsTab(),
                        PollsTab(),
                        AnnouncementsTab(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Hub',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831),
                    fontFamily: 'DMSerif',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect with other investors',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                    fontFamily: 'DMSerif',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor:
            isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
        labelColor: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
        unselectedLabelColor: isDark
            ? const Color(0xFFDFD0B8).withOpacity(0.7)
            : const Color(0xFF222831).withOpacity(0.7),
        labelStyle: const TextStyle(
          fontFamily: 'DMSerif',
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'DMSerif',
        ),
        tabs: [
          Tab(
            icon: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == 0;
                return Icon(
                  isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  size: isSelected ? 26 : 22,
                );
              },
            ),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == 0;
                return Text(
                  'Chats',
                  style: TextStyle(
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.w500,
                    fontSize: isSelected ? 14 : 12,
                  ),
                );
              },
            ),
          ),
          Tab(
            icon: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == 1;
                return Icon(
                  isSelected ? Icons.poll_rounded : Icons.poll_outlined,
                  size: isSelected ? 26 : 22,
                );
              },
            ),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == 1;
                return Text(
                  'Polls',
                  style: TextStyle(
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.w500,
                    fontSize: isSelected ? 14 : 12,
                  ),
                );
              },
            ),
          ),
          Tab(
            icon: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == 2;
                return Icon(
                  isSelected ? Icons.campaign : Icons.campaign_outlined,
                  size: isSelected ? 26 : 22,
                );
              },
            ),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == 2;
                return Text(
                  'Announcements',
                  style: TextStyle(
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.w500,
                    fontSize: isSelected ? 14 : 12,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ChatRoomsTab - Güncellenmiş versiyon
class ChatRoomsTab extends StatelessWidget {
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    bool isDark = false,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ],
      ),
    );
  }

  const ChatRoomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<List<ChatRoom>>(
        stream: ChatService().getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              icon: Icons.forum_outlined,
              title: 'No chat rooms available',
              isDark: isDark,
            );
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => _ChatRoomCard(
              room: snapshot.data![index],
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final bool isDark;

  const _ChatRoomCard({required this.room, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currentUser = ChatService().getCurrentUser();
    final hasJoined =
        currentUser != null && room.users.contains(currentUser.uid);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF393E46) : Colors.white,
      child: InkWell(
        onTap: room.isActive
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(chatRoom: room),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: room.isActive
                    ? (isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831))
                    : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                room.name,
                style: TextStyle(
                  color: room.isActive
                      ? (isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831))
                      : Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  room.description,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                    fontFamily: 'DMSerif',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              _RoomStatusSection(
                  room: room, hasJoined: hasJoined, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomStatusSection extends StatelessWidget {
  final ChatRoom room;
  final bool hasJoined;
  final bool isDark;

  const _RoomStatusSection({
    required this.room,
    required this.hasJoined,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!room.isActive) {
      return Column(
        children: [
          _RoomStatusRow(
            icon: Icons.lock,
            text: 'Closed',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Text(
            'Room is inactive',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _RoomStatusRow(
          icon: Icons.group,
          text: '${room.users.length} members',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: hasJoined ? null : () => ChatService().joinRoom(room.id),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            minimumSize: const Size(double.infinity, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            hasJoined ? 'Joined' : 'Join',
            style: TextStyle(
              color: const Color(0xFFDFD0B8),
              fontFamily: 'DMSerif',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomStatusRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _RoomStatusRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            fontFamily: 'DMSerif',
          ),
        ),
      ],
    );
  }
}

class PollsTab extends StatelessWidget {
  const PollsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<List<Poll>>(
        stream: PollService().getActivePolls(),
        initialData: const [],
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.purple));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          final polls = snapshot.data!;
          if (polls.isEmpty) {
            return const _EmptyState(
              icon: Icons.poll_outlined,
              title: 'No active polls available',
              subtitle: 'Check back later for new polls',
            );
          }

          return ListView.separated(
            itemCount: polls.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _PollCard(poll: polls[index]),
          );
        },
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;

  const _PollCard({required this.poll});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasVoted = currentUser != null && poll.hasUserVoted(currentUser.uid);
    final canShowResults =
        currentUser != null && poll.canShowResults(currentUser.uid);
    final totalVotes = canShowResults
        ? poll.options.fold(0, (sum, option) => sum + option.votes)
        : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PollHeader(poll: poll),
            const SizedBox(height: 12),
            Text(
              poll.question,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'DMSerif',
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...poll.options.map((option) => _PollOption(
                  option: option,
                  poll: poll,
                  hasVoted: hasVoted,
                  canShowResults: canShowResults,
                  totalVotes: totalVotes,
                )),
            const SizedBox(height: 12),
            _PollFooter(
              hasVoted: hasVoted,
              canShowResults: canShowResults,
              totalVotes: totalVotes,
              isActive: poll.isActive,
            ),
          ],
        ),
      ),
    );
  }
}

class _PollHeader extends StatelessWidget {
  final Poll poll;

  const _PollHeader({required this.poll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: poll.isActive ? Colors.green : Colors.grey,
          ),
        ),
        Text(
          poll.isActive ? 'ACTIVE' : 'CLOSED',
          style: TextStyle(
            letterSpacing: 1,
            color: poll.isActive ? Colors.green : Colors.grey,
            fontFamily: 'DMSerif',
          ),
        ),
        const Spacer(),
        Icon(Icons.poll_outlined,
            color: Theme.of(context).colorScheme.secondary, size: 22),
        const SizedBox(width: 8),
        Text(
          'POLL',
          style: TextStyle(
              letterSpacing: 1,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSerif'),
        ),
      ],
    );
  }
}

class _PollOption extends StatelessWidget {
  final PollOption option;
  final Poll poll;
  final bool hasVoted;
  final bool canShowResults;
  final int totalVotes;

  const _PollOption({
    required this.option,
    required this.poll,
    required this.hasVoted,
    required this.canShowResults,
    required this.totalVotes,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isSelected = hasVoted &&
        poll.getSelectedOptionIndex(currentUser?.uid ?? '') ==
            poll.options.indexOf(option);
    final percentage = canShowResults && totalVotes > 0
        ? (option.votes / totalVotes * 100).round()
        : 0;

    return Column(
      children: [
        InkWell(
          onTap: hasVoted || !poll.isActive
              ? null
              : () => _handleVote(context, poll, option),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : hasVoted
                      ? Theme.of(context).colorScheme.primary
                      : poll.isActive
                          ? Colors.white60
                          : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? Colors.purple : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : hasVoted || !poll.isActive
                              ? Colors.grey[600]
                              : Theme.of(context).colorScheme.primary,
                      fontFamily: 'DMSerif',
                      fontSize: 16,
                    ),
                  ),
                ),
                if (canShowResults)
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.background,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (canShowResults) ...[
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: totalVotes > 0 ? option.votes / totalVotes : 0,
            backgroundColor: Colors.grey[200],
            color: isSelected ? Colors.purple : Colors.purple.withOpacity(0.5),
            minHeight: 4,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _handleVote(
      BuildContext context, Poll poll, PollOption option) async {
    try {
      await PollService().vote(poll.id, poll.options.indexOf(option));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Vote submitted!', style: TextStyle(color: Colors.green)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _PollFooter extends StatelessWidget {
  final bool hasVoted;
  final bool canShowResults;
  final int totalVotes;
  final bool isActive;

  const _PollFooter({
    required this.hasVoted,
    required this.canShowResults,
    required this.totalVotes,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            hasVoted ? Icons.check_circle : Icons.info,
            color: hasVoted ? Colors.green : Colors.purple,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasVoted
                  ? canShowResults
                      ? 'Total votes: $totalVotes'
                      : 'Thanks for voting! Results coming soon.'
                  : isActive
                      ? 'Select an option to vote'
                      : 'This poll is closed',
              style: TextStyle(
                color: hasVoted
                    ? Colors.green
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementsTab extends StatelessWidget {
  const AnnouncementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<List<Announcement>>(
        stream: AnnouncementService().getActiveAnnouncements(),
        initialData: const [],
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.purple));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final announcements = snapshot.data!;
          if (announcements.isEmpty) {
            return const _EmptyState(
              icon: Icons.announcement_outlined,
              title: 'No announcements available',
            );
          }

          return ListView.separated(
            itemCount: announcements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) =>
                _AnnouncementCard(announcement: announcements[index]),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnnouncementHeader(announcement: announcement),
            const SizedBox(height: 12),
            Text(
              announcement.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
            if (announcement.imageUrl != null) ...[
              const SizedBox(height: 12),
              _AnnouncementImage(imageUrl: announcement.imageUrl!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnnouncementHeader extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementHeader({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.campaign, color: Colors.orange, size: 24),
        const SizedBox(width: 8),
        Text(
          'ANNOUNCEMENT',
          style: TextStyle(
            letterSpacing: 1,
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          _formatDate(announcement.createdAt),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).round()} weeks ago';
    }
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).round()} months ago';
    }

    return DateFormat('MMM dd, yyyy').format(date);
  }
}

class _AnnouncementImage extends StatelessWidget {
  final String imageUrl;

  const _AnnouncementImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 150,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 150,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
