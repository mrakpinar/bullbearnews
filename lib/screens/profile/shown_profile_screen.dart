import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/screens/profile/wallet_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ShownProfileScreen extends StatefulWidget {
  final String userId;

  const ShownProfileScreen({super.key, required this.userId});

  @override
  State<ShownProfileScreen> createState() => _ShownProfileScreenState();
}

class _ShownProfileScreenState extends State<ShownProfileScreen> {
  DocumentSnapshot? _userDoc;
  bool _isFollowing = false;
  bool _isLoading = true;
  final bool _isCurrentUser = false;
  bool _isCurrentUserLoading = true;
  List<Map<String, dynamic>> _sharedPortfolios = [];
  bool _isLoadingPortfolios = true;
  List<String> _likedPortfolios = [];
  bool _isLoadingLikes = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadSharedPortfolios();
    _loadLikedPortfolios();
  }

  Future<void> _loadLikedPortfolios() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('likedPortfolios')
          .get();

      setState(() {
        _likedPortfolios = snapshot.docs.map((doc) => doc.id).toList();
        _isLoadingLikes = false;
      });
    } catch (e) {
      setState(() => _isLoadingLikes = false);
    }
  }

  Future<void> _loadUser() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final isFollowing = (userDoc['followers'] as List).contains(currentUserId);

    setState(() {
      _userDoc = userDoc;
      _isFollowing = isFollowing;
      _isLoading = false;
    });
  }

  Future<void> _loadSharedPortfolios() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('sharedPortfolios')
          .where('isPublic', isEqualTo: true)
          .get();

      setState(() {
        _sharedPortfolios = snapshot.docs.map((doc) => doc.data()).toList();
        _isLoadingPortfolios = false;
      });
    } catch (e) {
      setState(() => _isLoadingPortfolios = false);
    }
  }

  Widget _buildPortfolioList() {
    if (_isLoadingPortfolios) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sharedPortfolios.isEmpty) {
      return Center(
        child: Text(
          'No shared portfolios yet',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Shared Portfolios',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
              textBaseline: TextBaseline.alphabetic,
              wordSpacing: 1.2,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        ..._sharedPortfolios.map(
          (portfolio) => _buildPortfolioCard(portfolio),
        ),
      ],
    );
  }

  Widget _buildPortfolioCard(Map<String, dynamic> portfolio) {
    final likes = (portfolio['likes'] ?? []) as List<dynamic>;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('wallets')
          .doc(portfolio['walletId'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: ListTile(title: Text('Loading...')),
          );
        }

        final wallet =
            Wallet.fromJson(snapshot.data!.data() as Map<String, dynamic>);
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Theme.of(context).cardTheme.color,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletDetailScreen(
                    wallet: wallet,
                    onUpdate: () {},
                    isSharedView: true,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wallet, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${wallet.items.length} assets',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  // Like button
                  Builder(
                    builder: (context) {
                      final isLiked =
                          _likedPortfolios.contains(portfolio['walletId']);
                      return IconButton(
                        icon: Icon(
                          isLiked
                              ? Icons.bookmark_border_sharp
                              : Icons.bookmark_sharp,
                          size: 24,
                          color: isLiked
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                        ),
                        tooltip:
                            isLiked ? 'Unlike Portfolio' : 'Like Portfolio',
                        onPressed: () =>
                            _toggleLikePortfolio(portfolio['walletId'], likes),
                        padding: const EdgeInsets.all(0),
                        constraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleLikePortfolio(
      String walletId, List<dynamic> likes) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Hedef kullanıcının sharedPortfolios'unda güncelleme
    final targetDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('sharedPortfolios')
        .doc(walletId);

    // Mevcut kullanıcının likedPortfolios'unda güncelleme
    final currentUserLikedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('likedPortfolios')
        .doc(walletId);

    final isLiked = likes.contains(currentUserId);

    if (isLiked) {
      // Beğeniyi kaldır
      await targetDocRef.update({
        'likes': FieldValue.arrayRemove([currentUserId])
      });
      await currentUserLikedRef.delete();
    } else {
      // Beğeni ekle
      await targetDocRef.update({
        'likes': FieldValue.arrayUnion([currentUserId])
      });
      await currentUserLikedRef.set({
        'ownerId': widget.userId,
        'likedAt': FieldValue.serverTimestamp(),
      });
    }

    // Verileri yenile
    _loadSharedPortfolios();
    _loadLikedPortfolios();
  }

  Future<void> _toggleFollow() async {
    if (_isCurrentUser) return;
    setState(() {
      _isCurrentUserLoading = true;
    });

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final targetRef =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final currentRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);

    if (_isFollowing) {
      await targetRef.update({
        'followers': FieldValue.arrayRemove([currentUserId])
      });
      await currentRef.update({
        'following': FieldValue.arrayRemove([widget.userId])
      });
    } else {
      await targetRef.update({
        'followers': FieldValue.arrayUnion([currentUserId])
      });
      await currentRef.update({
        'following': FieldValue.arrayUnion([widget.userId])
      });
    }

    setState(() {
      _isFollowing = !_isFollowing;
      _isCurrentUserLoading = false;
    });
    await _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nickname = _userDoc!['nickname'];
    final email = _userDoc!['email'];
    final followers = (_userDoc!['followers'] as List).length;
    final following = (_userDoc!['following'] as List).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$nickname\'s Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 24),
          onPressed: () => Navigator.pop(context),
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Theme.of(context).cardTheme.color,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: NetworkImage(
                          _userDoc!['profileImageUrl'],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatItem('Followers', followers),
                          const SizedBox(width: 24),
                          _buildStatItem('Following', following),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing
                                ? Color(0xFFFF5722)
                                : Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _isFollowing
                                    ? Color(0xFFFF5722)
                                    : Color(0xFF00BCD4),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            _isFollowing ? 'Unfollow' : 'Follow',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Shared Portfolios Section
              _buildPortfolioList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
