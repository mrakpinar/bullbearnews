import 'package:bullbearnews/screens/profile/shown_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchUsers(query);
      } else {
        setState(() {
          _searchResults.clear(); // Arama kutusu boşsa sonuçları temizle
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return; // Boş sorgu göndermeyi engelle

    setState(() => _isLoading = true);

    // Firestore'da kullanıcıları arama
    // 'nickname' alanına göre filtreleme yapıyoruz

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('nickname', isLessThan: '${query.toLowerCase()}z')
        .get();

    setState(() {
      _searchResults = result.docs
          .where((doc) => doc.id != FirebaseAuth.instance.currentUser!.uid)
          .toList();
      _isLoading = false;
    });
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
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 16),
              cursorColor: Theme.of(context).colorScheme.primary,
              cursorHeight: 20,
              cursorWidth: 2,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.text,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textAlignVertical: TextAlignVertical.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              decoration: InputDecoration(
                hintText: 'User name...',
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                prefixIcon: const Icon(Icons.search),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final query = _searchController.text.trim();

                    if (query.isNotEmpty) {
                      _searchUsers(query);
                    } else {
                      setState(() {
                        _searchResults
                            .clear(); // Arama kutusu boşsa sonuçları temizle
                      });
                    }
                  },
                ),
              ),
              onChanged: (val) {
                if (val.trim().isNotEmpty) {
                  _searchUsers(val.trim());
                } else if (val.trim().isEmpty) {
                  setState(() {
                    _searchResults
                        .clear(); // Arama kutusu boşsa sonuçları temizle
                  });
                } else if (val.trim().length < 3) {
                  setState(() {
                    _searchResults
                        .clear(); // Arama kutusu boşsa sonuçları temizle
                  });
                } else if (val.trim().length > 20) {
                  setState(() {
                    _searchResults
                        .clear(); // Arama kutusu boşsa sonuçları temizle
                  });
                } else {
                  setState(() {
                    _searchResults
                        .clear(); // Arama kutusu boşsa sonuçları temizle
                  });
                }
              },
              onTap: () {
                if (_searchController.text.trim().isNotEmpty) {
                  _searchUsers(_searchController.text.trim());
                }
              },
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _searchUsers(val.trim());
                }
              },
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        if (index >= _searchResults.length) {
                          return const SizedBox.shrink();
                        }
                        if (_searchResults.isEmpty) {
                          return const Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(fontSize: 18),
                            ),
                          );
                        }
                        // Kullanıcıyı listele
                        final user = _searchResults[index];
                        if (user['nickname'] == null) {
                          return const SizedBox.shrink();
                        }
                        if (user['email'] == null) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person,
                                size: 30, color: Colors.white),
                          ),
                          title: Text(
                            user['nickname'] ?? 'Unknown',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
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
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.6),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ShownProfileScreen(userId: user.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
