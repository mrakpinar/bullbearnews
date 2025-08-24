import 'package:bullbearnews/services/poll_serivice.dart';
import 'package:flutter/material.dart';
import '../../../../models/poll_model.dart';
import 'poll_card.dart';

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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
            itemBuilder: (context, index) => PollCard(poll: polls[index]),
          );
        },
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
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
