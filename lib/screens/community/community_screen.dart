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
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text(
        //   'Community',
        //   style: TextStyle(
        //     fontWeight: FontWeight.bold,
        //     fontSize: 24,
        //     letterSpacing: 1.2,
        //     wordSpacing: 1.5,
        //     fontFamily: 'Roboto',
        //   ),
        // ),
        // centerTitle: true,

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey[600],
          dividerColor: Colors.transparent, // TabBar altındaki çizgiyi kaldırır
          // isScrollable: true, // Bu satırı kaldırabilirsiniz (sabit genişlik için)
          labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.purple),
          ),
          tabs: const [
            Tab(
              icon: Icon(
                Icons.forum_outlined,
                size: 32,
              ),
            ),
            Tab(
              icon: Icon(
                Icons.poll_outlined,
                size: 32,
              ),
            ),
            Tab(
              icon: Icon(
                Icons.announcement_outlined,
                size: 32,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PollsTab(),
          ChatRoomsTab(),
          AnnouncementsTab(),
        ],
      ),
    );
  }
}

class ChatRoomsTab extends StatelessWidget {
  const ChatRoomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<List<ChatRoom>>(
        stream: chatService.getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No chat rooms available'));
          }

          final rooms = snapshot.data!;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _buildRoomCard(context, room);
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, ChatRoom room) {
    final theme = Theme.of(context);
    final chatService = ChatService();
    final currentUser = chatService.getCurrentUser();
    final hasJoined =
        currentUser != null && room.users.contains(currentUser.uid);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          if (room.isActive) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatRoom: room),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: room.isActive ? Colors.purple : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                room.name,
                style: TextStyle(
                  color: room.isActive ? Colors.purple : Colors.grey,
                  fontSize: 18,
                  letterSpacing: 1,
                  height: 1.2,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                  textBaseline: TextBaseline.alphabetic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                flex: 1,
                child: Text(
                  room.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: room.isActive ? Colors.grey : Colors.grey,
                    fontSize: 14,
                    letterSpacing: 0.5,
                    height: 1.4,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 8),
              if (room.isActive) ...[
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      color: Colors.purple,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${room.users.length} members',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              if (!room.isActive) ...[
                Row(
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Closed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (room.isActive)
                ElevatedButton(
                  onPressed:
                      hasJoined ? null : () => chatService.joinRoom(room.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    hasJoined ? 'Joined' : 'Join',
                    style: TextStyle(
                      color: hasJoined ? Colors.grey : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                      fontFamily: 'Roboto',
                      fontStyle: FontStyle.normal,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              // Oda aktif değilse bir bilgilendirme metni gösterebiliriz (opsiyonel)
              if (!room.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: Text(
                    'Room is inactive',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PollsTab extends StatelessWidget {
  const PollsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pollService = PollService();
    Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<List<Poll>>(
        stream: pollService.getActivePolls(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.purple,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    )));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.poll_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active polls available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center),
                  SizedBox(height: 8),
                  Text('Check back later for new polls',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final poll = snapshot.data![index];
              return _buildPollCard(context, poll);
            },
          );
        },
      ),
    );
  }

  Widget _buildPollCard(BuildContext context, Poll poll) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasVoted = currentUser != null && poll.hasUserVoted(currentUser.uid);
    final canShowResults =
        currentUser != null && poll.canShowResults(currentUser.uid);
    final totalVotes = canShowResults
        ? poll.options.fold(0, (sum, option) => sum + option.votes)
        : 0;
    final selectedOptionIndex = currentUser != null
        ? poll.getSelectedOptionIndex(currentUser.uid)
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poll status header
            Row(
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: poll.isActive ? Colors.green : Colors.grey,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.poll_outlined, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'POLL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Poll question
            Text(
              poll.question,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: 18,
                letterSpacing: 1,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Poll options
            ...poll.options.map((option) {
              final isSelected = hasVoted &&
                  selectedOptionIndex == poll.options.indexOf(option);
              final percentage = canShowResults && totalVotes > 0
                  ? (option.votes / totalVotes * 100).round()
                  : 0;

              return Column(
                children: [
                  InkWell(
                    onTap: hasVoted || !poll.isActive
                        ? null
                        : () async {
                            try {
                              await PollService()
                                  .vote(poll.id, poll.options.indexOf(option));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vote submitted!',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold)),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.purple.withOpacity(
                                0.5) // Seçilen seçenek - daha koyu mor
                            : hasVoted
                                ? Colors.purple.withOpacity(
                                    0.1) // Diğer seçenekler - açık mor
                                : poll.isActive
                                    ? Colors.white
                                    : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.purple // Seçilen seçenek border rengi
                              : hasVoted
                                  ? Colors.grey.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                          width: isSelected
                              ? 2
                              : 1, // Seçilen seçenekte daha kalın border
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
                                    ? Colors
                                        .white // Seçilen seçenekte beyaz yazı
                                    : hasVoted || !poll.isActive
                                        ? Colors.grey[600]
                                        : Colors.grey[800],
                                fontSize: 16,
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
                      color: isSelected
                          ? Colors.purple
                          : Colors.purple.withOpacity(0.5),
                      minHeight: 4,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            }),

            // Poll footer info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasVoted
                      ? Colors.grey.withOpacity(0.3)
                      : Colors.purple.withOpacity(0.3),
                ),
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
                          : poll.isActive
                              ? 'Select an option to vote'
                              : 'This poll is closed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasVoted
                            ? Colors.green
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.purple[800],
                      ),
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

class AnnouncementsTab extends StatelessWidget {
  const AnnouncementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final announcementService = AnnouncementService();
    Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<List<Announcement>>(
        stream: announcementService.getActiveAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.purple,
            ));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.announcement_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No announcements available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textScaleFactor: 1.2,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                    ),
                    textWidthBasis: TextWidthBasis.longestLine,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final announcement = snapshot.data![index];
              return _buildAnnouncementCard(context, announcement);
            },
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(
      BuildContext context, Announcement announcement) {
    final theme = Theme.of(context);

    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black38
          : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white24
              : Colors.grey.withOpacity(0.2),
          width: 1,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.campaign,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'ANNOUNCEMENT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(announcement.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: 20,
                letterSpacing: 1,
                height: 1.2,
                textBaseline: TextBaseline.alphabetic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
                fontSize: 16,
                letterSpacing: 1,
                height: 1.4,
              ),
            ),
            if (announcement.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  announcement.imageUrl!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).round()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).round()} months ago';
    }

    // For dates older than a year, format as "MMM dd, yyyy"
    // Example: "Jan 01, 2022"
    // return DateFormat('MMM dd, yyyy').format(date);
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
