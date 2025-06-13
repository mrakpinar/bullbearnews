import 'dart:async';

import 'package:bullbearnews/screens/profile/shown_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  final Map<String, List<DocumentSnapshot>> _searchCache = {};

  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _listAnimationController.forward();
    });
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty && query.length >= 2) {
        _searchUsers(query);
      } else {
        setState(() {
          _searchResults.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty || query.length < 2) return;

    if (_searchCache.containsKey(query)) {
      setState(() {
        _searchResults = _searchCache[query]!;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: query)
          .where('nickname', isLessThan: '${query}z')
          .limit(20)
          .get();

      final filteredResults = result.docs
          .where((doc) => doc.id != FirebaseAuth.instance.currentUser!.uid)
          .toList();

      _searchCache[query] = filteredResults;

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Arama hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildSearchBar(isDark),
            Expanded(
              child: _buildSearchResults(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF393E46).withOpacity(0.8)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF393E46),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Users',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF222831),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find and connect with people',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF948979)
                                : const Color(0xFF393E46),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF393E46).withOpacity(0.8)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by username (min 2 characters)...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46).withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.search_rounded,
                        size: 24,
                        color: isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46),
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults.clear();
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: isDark
                                      ? const Color(0xFF948979)
                                      : const Color(0xFF393E46),
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _listAnimation.value)),
          child: Opacity(
            opacity: _listAnimation.value,
            child: _buildResultsContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildResultsContent(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching users...',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.trim().isNotEmpty) {
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

    if (_searchResults.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOut,
          child: _buildUserTile(_searchResults[index], isDark, index),
        );
      },
    );
  }

  Widget _buildUserTile(DocumentSnapshot user, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShownProfileScreen(userId: user.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF393E46),
                        const Color(0xFF948979),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: user['profileImageUrl'] != null &&
                            user['profileImageUrl'].toString().isNotEmpty
                        ? Image.network(
                            user['profileImageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF393E46),
                                      const Color(0xFF948979),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 28,
                                  color: Color(0xFFDFD0B8),
                                ),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: Color(0xFFDFD0B8),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nickname'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF948979)
                              : const Color(0xFF393E46),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF948979).withOpacity(0.2)
                        : const Color(0xFF393E46).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
