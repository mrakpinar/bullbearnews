import 'package:bullbearnews/models/poll_model.dart';
import 'package:bullbearnews/services/poll_serivice.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/chat_room_model.dart';
import 'chat_screen.dart';
import '../../services/chat_service.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Community'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.forum_outlined), text: 'Chat Rooms'),
            Tab(icon: Icon(Icons.poll_outlined), text: 'Polls'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ChatRoomsTab(),
          PollsTab(),
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
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  room.description,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                      style: theme.textTheme.bodySmall,
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
                  ),
                  child: Text(hasJoined ? 'Joined' : 'Join'),
                ),
              // Oda aktif değilse bir bilgilendirme metni gösterebiliriz (opsiyonel)
              if (!room.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: Text(
                    'Room is inactive',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.poll_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active polls available'),
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              ],
            ),
            const SizedBox(height: 12),
            Text(
              poll.question,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...poll.options.map((option) {
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
                                    content: Text('Vote submitted!')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: hasVoted
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasVoted
                              ? Colors.grey.withOpacity(0.3)
                              : Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.text,
                              style: TextStyle(
                                color: hasVoted || !poll.isActive
                                    ? Colors.grey
                                    : Colors.purple,
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
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.purple),
                      minHeight: 4,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                      style: theme.textTheme.bodySmall,
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
