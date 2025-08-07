import 'package:bullbearnews/services/firebase_new_saved_service.dart';
import 'package:bullbearnews/widgets/profile/saved_news_list.dart';
import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';

class SavedNewsSection extends StatefulWidget {
  const SavedNewsSection({super.key});

  @override
  State<SavedNewsSection> createState() => _SavedNewsSectionState();
}

class _SavedNewsSectionState extends State<SavedNewsSection>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final FirebaseSavedNewsService _firebaseSavedNewsService =
      FirebaseSavedNewsService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshSavedNews() async {
    setState(() => _isLoading = true);
    try {
      // Firebase otomatik olarak güncel verileri getirir
      // Burada ekstra bir işlem yapmanıza gerek yok
      await Future.delayed(
          const Duration(milliseconds: 500)); // UX için kısa delay
    } catch (e) {
      debugPrint('Refresh error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearAllSavedNews() async {
    // Confirmation dialog
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear All Saved News',
          style: TextStyle(
            fontFamily: 'DMSerif',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to remove all saved news? This action cannot be undone.',
          style: TextStyle(fontFamily: 'DMSerif'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade200,
                    fontFamily: 'DMSerif',
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(fontFamily: 'DMSerif'),
            ),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      try {
        setState(() => _isLoading = true);
        await _firebaseSavedNewsService.clearAllSavedNews();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All saved news cleared successfully',
                      style: TextStyle(fontFamily: 'DMSerif'),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to clear saved news: $e',
                      style: const TextStyle(fontFamily: 'DMSerif'),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildModernSection(
          title: 'Saved News',
          icon: Icons.bookmark_rounded,
          isDark: isDark,
          child: StreamBuilder<int>(
            stream: _firebaseSavedNewsService.getSavedNewsCountStream(),
            builder: (context, countSnapshot) {
              final savedNewsCount = countSnapshot.data ?? 0;

              return Column(
                children: [
                  if (savedNewsCount == 0)
                    _buildEmptyStateCard(isDark)
                  else
                    SavedNewsList(
                      isLoading: _isLoading,
                      onRefresh: _refreshSavedNews,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.lightText.withOpacity(0.1)
              : AppColors.darkText.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.deepOrange.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.whiteText,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.lightText : AppColors.darkText,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                      StreamBuilder<int>(
                        stream:
                            _firebaseSavedNewsService.getSavedNewsCountStream(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            count == 0
                                ? 'No saved articles'
                                : '$count saved articles',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.lightText.withOpacity(0.7)
                                  : AppColors.darkText.withOpacity(0.7),
                              fontFamily: 'DMSerif',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Action Buttons Row
                Row(
                  children: [
                    // Refresh Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isLoading
                              ? Icons.hourglass_empty
                              : Icons.refresh_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        onPressed: _isLoading ? null : _refreshSavedNews,
                        tooltip: 'Refresh',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clear All Button
                    StreamBuilder<int>(
                      stream:
                          _firebaseSavedNewsService.getSavedNewsCountStream(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.clear_all_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: _isLoading ? null : _clearAllSavedNews,
                            tooltip: 'Clear All',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                color: Colors.orange.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved News',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.lightText : AppColors.darkText,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start saving news articles you want to\nread later to see them here',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.lightText.withOpacity(0.7)
                    : AppColors.darkText.withOpacity(0.7),
                fontFamily: 'DMSerif',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Explore News',
                    style: const TextStyle(
                      color: Colors.white,
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
    );
  }
}
