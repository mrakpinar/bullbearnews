import 'package:bullbearnews/widgets/profile/saved_news_list.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/news_model.dart';

class SavedNewsSection extends StatefulWidget {
  const SavedNewsSection({super.key});

  @override
  State<SavedNewsSection> createState() => _SavedNewsSectionState();
}

class _SavedNewsSectionState extends State<SavedNewsSection> {
  bool _isLoading = false;

  Future<void> _refreshSavedNews() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate refresh
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return _buildGlassSection(
      title: 'Saved News',
      theme: theme,
      isDarkMode: isDarkMode,
      child: ValueListenableBuilder<Box<NewsModel>>(
        valueListenable: Hive.box<NewsModel>('savedNews').listenable(),
        builder: (context, box, _) {
          return SavedNewsList(
            isLoading: _isLoading || box.values.isEmpty,
            onRefresh: _refreshSavedNews,
          );
        },
      ),
    );
  }

  Widget _buildGlassSection({
    required String title,
    required ThemeData theme,
    required bool isDarkMode,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF393E46).withOpacity(0.7)
            : const Color(0xFFF5F5F5).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF393E46).withOpacity(0.3)
              : const Color(0xFFE0E0E0).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? const Color(0xFF222831).withOpacity(0.2)
                : const Color(0xFFDFD0B8).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDarkMode
                    ? const Color(0xFFDFD0B8)
                    : const Color(0xFF222831),
                letterSpacing: -0.8,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
