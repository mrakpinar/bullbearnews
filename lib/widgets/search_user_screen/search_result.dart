import 'package:bullbearnews/widgets/search_user_screen/loading_overlay.dart';
import 'package:bullbearnews/widgets/search_user_screen/user_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchResult extends StatelessWidget {
  final Animation<double> listAnimation;
  final bool isDark;
  final bool isLoading;
  final List<DocumentSnapshot> searchResults;
  final String searchQuery;
  final TextEditingController? searchController;

  const SearchResult({
    super.key,
    required this.listAnimation,
    required this.isDark,
    required this.isLoading,
    required this.searchResults,
    required this.searchQuery,
    this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: listAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - listAnimation.value)),
          child: Opacity(
            opacity: listAnimation.value,
            child: _buildResultsContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildResultsContent(bool isDark) {
    // Loading durumu
    if (isLoading) {
      return LoadingOverlay(
        isDark: isDark,
      );
    }

    // Arama yapıldı ama sonuç yok
    if (searchResults.isEmpty && searchQuery.trim().isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF393E46).withOpacity(0.5)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 48,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
          ],
        ),
      );
    }

    // Henüz arama yapılmadı (başlangıç durumu)
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF393E46).withOpacity(0.5)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 48,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start typing to search',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter at least 2 characters',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
          ],
        ),
      );
    }

    // Sonuçları listele
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOut,
          child: UserTile(
            user: searchResults[index],
            isDark: isDark,
            index: index,
          ),
        );
      },
    );
  }
}
