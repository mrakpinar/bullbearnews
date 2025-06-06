import 'package:cached_network_image/cached_network_image.dart';
import 'package:bullbearnews/constants/colors.dart';
import 'package:bullbearnews/models/announcement_model.dart';
import 'package:bullbearnews/models/poll_model.dart';
import 'package:bullbearnews/services/announcement_service.dart';
import 'package:bullbearnews/services/poll_serivice.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/chat_room_model.dart';
import 'chat_screen.dart';
import '../../services/chat_service.dart';
import 'package:intl/intl.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 42,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        bottom: _TabBarSection(controller: _tabController),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: const [
          ChatRoomsTab(),
          PollsTab(),
          AnnouncementsTab(),
        ],
      ),
    );
  }
}

class _TabBarSection extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;

  const _TabBarSection({required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.primary,
      child: TabBar(
        controller: controller,
        indicatorColor: AppColors.accent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(width: 3.0, color: AppColors.accent),
        ),
        tabs: [
          _CustomTab(
            index: 0,
            controller: controller,
            icon: Icons.forum_outlined,
            label: 'Chat Rooms',
          ),
          _CustomTab(
            index: 1,
            controller: controller,
            icon: Icons.poll_outlined,
            label: 'Polls',
          ),
          _CustomTab(
            index: 2,
            controller: controller,
            icon: Icons.announcement_outlined,
            label: 'Announcements',
          ),
        ],
      ),
    );
  }
}

class _CustomTab extends StatelessWidget {
  final int index;
  final TabController controller;
  final IconData icon;
  final String label;

  const _CustomTab({
    required this.index,
    required this.controller,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.index == index;

    return Tab(
      icon: Icon(
        icon,
        size: isSelected ? 30 : 24,
        semanticLabel: label,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSelected ? 13 : 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class ChatRoomsTab extends StatelessWidget {
  const ChatRoomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<List<ChatRoom>>(
        stream: ChatService().getChatRooms(),
        initialData: const [],
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rooms = snapshot.data!;
          if (rooms.isEmpty) {
            return const Center(child: Text('No chat rooms available'));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) => _ChatRoomCard(room: rooms[index]),
          );
        },
      ),
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  final ChatRoom room;

  const _ChatRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ChatService().getCurrentUser();
    final hasJoined =
        currentUser != null && room.users.contains(currentUser.uid);

    return Card(
      color: theme.cardTheme.color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                color: room.isActive ? theme.colorScheme.surface : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                room.name,
                style: TextStyle(
                  color:
                      room.isActive ? theme.colorScheme.surface : Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  room.description,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              _RoomStatusSection(room: room, hasJoined: hasJoined),
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

  const _RoomStatusSection({required this.room, required this.hasJoined});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!room.isActive) {
      return Column(
        children: [
          const _RoomStatusRow(icon: Icons.lock, text: 'Closed'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            child: Text(
              'Room is inactive',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
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
          color: theme.colorScheme.surface,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: hasJoined ? null : () => ChatService().joinRoom(room.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.background,
            minimumSize: const Size(double.infinity, 36),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            hasJoined ? 'Joined' : 'Join',
            style: TextStyle(
              color: hasJoined ? Colors.grey : Colors.white,
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
  final Color? color;

  const _RoomStatusRow({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.grey, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
          ),
        ),
        const Spacer(),
        const Icon(Icons.poll_outlined, color: Colors.purple, size: 20),
        const SizedBox(width: 8),
        Text(
          'POLL',
          style: TextStyle(
            letterSpacing: 1,
            color: Colors.purple,
          ),
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
                  ? Colors.purple.withOpacity(0.5)
                  : hasVoted
                      ? Colors.purple.withOpacity(0.1)
                      : poll.isActive
                          ? Colors.white
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
                              : Colors.grey[800],
                    ),
                  ),
                ),
                if (canShowResults)
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
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
                color: hasVoted ? Colors.green : Colors.purple[800],
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
      color: isDark ? Colors.black38 : Colors.white,
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
