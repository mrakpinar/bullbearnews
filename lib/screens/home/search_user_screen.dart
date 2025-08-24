import 'dart:async';

import 'package:bullbearnews/widgets/search_user_screen/custom_search_bar.dart';
import 'package:bullbearnews/widgets/search_user_screen/search_result.dart';
import 'package:bullbearnews/widgets/search_user_screen/search_user_screen_header.dart';
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
            SearchUserScreenHeader(
              isDark: isDark,
              headerAnimation: _headerAnimation,
            ),
            _buildSearchBar(isDark),
            Expanded(
              child: _buildSearchResults(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Search by username (min 2 characters)...',
      isDark: isDark,
      animation: _headerAnimation,
      onClear: () {
        _searchController.clear();
        setState(() {
          _searchResults.clear();
        });
      },
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return SearchResult(
      listAnimation: _listAnimation,
      isDark: isDark,
      isLoading: _isLoading,
      searchResults: _searchResults,
      searchQuery: _searchController.text,
      searchController: _searchController,
    );
  }
}
