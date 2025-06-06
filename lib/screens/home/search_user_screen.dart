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

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  final Map<String, List<DocumentSnapshot>> _searchCache = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Debounce mekanizması
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
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty || query.length < 2) return;

    // Cache kontrolü
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
          .limit(20) // Sonuç limitini ekle
          .get();

      final filteredResults = result.docs
          .where((doc) => doc.id != FirebaseAuth.instance.currentUser!.uid)
          .toList();

      // Cache'e kaydet
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Users',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TextField optimizasyonları
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'User name (min 2 characters)...',
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                prefixIcon: const Icon(Icons.search),
              ),
              // onChanged ve diğer callback'leri kaldır, sadece listener kullan
            ),
            const SizedBox(height: 20),
            _buildSearchResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.trim().isNotEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No users found',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        // Performans için itemExtent ekle
        itemExtent: 80,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildUserTile(DocumentSnapshot user) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person, size: 30, color: Colors.white),
      ),
      title: Text(
        user['nickname'] ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      subtitle: Text(
        user['email'] ?? 'Unknown',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShownProfileScreen(userId: user.id),
          ),
        );
      },
    );
  }
}
