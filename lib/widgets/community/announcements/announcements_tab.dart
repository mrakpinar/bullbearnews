import 'package:bullbearnews/widgets/community/empty_state.dart';
import 'package:flutter/material.dart';
import '../../../../models/announcement_model.dart';
import '../../../../services/announcement_service.dart';
import 'announcement_card.dart';

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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final announcements = snapshot.data!;
          if (announcements.isEmpty) {
            return const EmptyState(
              icon: Icons.announcement_outlined,
              title: 'No announcements available',
            );
          }

          return ListView.separated(
            itemCount: announcements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => AnnouncementCard(
              announcement: announcements[index],
              isLatest: index == 0, // İlk sıradaki (en yeni) duyuru
            ),
          );
        },
      ),
    );
  }
}
