import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/screens/profile/wallet/wallet_detail_screen.dart';
import 'package:bullbearnews/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ShownProfileScreen extends StatefulWidget {
  final String userId;

  const ShownProfileScreen({super.key, required this.userId});

  @override
  State<ShownProfileScreen> createState() => _ShownProfileScreenState();
}

class _ShownProfileScreenState extends State<ShownProfileScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  DocumentSnapshot? _userDoc;
  bool _isFollowing = false;
  bool _isLoading = true;
  final bool _isCurrentUser = false;
  bool _isCurrentUserLoading = true;
  List<Map<String, dynamic>> _sharedPortfolios = [];
  bool _isLoadingPortfolios = true;
  List<String> _likedPortfolios = [];
  bool _isLoadingLikes = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUser();
    _loadSharedPortfolios();
    _loadLikedPortfolios();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }

    if (_sharedPortfolios.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No shared portfolios yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user hasn\'t shared any portfolios publicly',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20, left: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.share_outlined,
                  size: 24,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Shared Portfolios',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${_sharedPortfolios.length} portfolios',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ..._sharedPortfolios.asMap().entries.map(
              (entry) => AnimatedContainer(
                duration: Duration(milliseconds: 300 + (entry.key * 100)),
                curve: Curves.easeOutBack,
                child: _buildPortfolioCard(entry.value),
              ),
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
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(width: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
            ),
          );
        }

        final wallet =
            Wallet.fromJson(snapshot.data!.data() as Map<String, dynamic>);
        final isLiked = _likedPortfolios.contains(portfolio['walletId']);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            color: Theme.of(context).cardTheme.color,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.wallet_outlined,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.pie_chart_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${wallet.items.length} assets',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.favorite_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${likes.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isLiked
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isLiked ? Icons.bookmark : Icons.bookmark_border,
                          size: 24,
                          color: isLiked ? Colors.blue : Colors.grey[600],
                        ),
                        tooltip:
                            isLiked ? 'Remove from saved' : 'Save portfolio',
                        onPressed: () => _toggleLikePortfolio(
                            portfolio['walletId'], likes, wallet.name),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleLikePortfolio(
      String walletId, List<dynamic> likes, String walletName) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final targetDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('sharedPortfolios')
        .doc(walletId);

    final currentUserLikedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('likedPortfolios')
        .doc(walletId);

    final isLiked = likes.contains(currentUserId);

    if (isLiked) {
      await targetDocRef.update({
        'likes': FieldValue.arrayRemove([currentUserId])
      });
      await currentUserLikedRef.delete();
    } else {
      await targetDocRef.update({
        'likes': FieldValue.arrayUnion([currentUserId])
      });
      await currentUserLikedRef.set({
        'ownerId': widget.userId,
        'likedAt': FieldValue.serverTimestamp(),
      });

      // Send like notification to portfolio owner
      await _notificationService.sendLikePortfolioNotification(
          widget.userId, walletName);
    }

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

      // Send unfollow notification
      // await _notificationService.sendUnfollowNotification(widget.userId);
    } else {
      await targetRef.update({
        'followers': FieldValue.arrayUnion([currentUserId])
      });
      await currentRef.update({
        'following': FieldValue.arrayUnion([widget.userId])
      });

      // Send follow notification
      await _notificationService.sendFollowNotification(widget.userId);
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final nickname = _userDoc!['nickname'];
    final email = _userDoc!['email'];
    final bio = _userDoc!['bio'] ?? ''; // Bio alanını al
    final followers = (_userDoc!['followers'] as List).length;
    final following = (_userDoc!['following'] as List).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 50,
            floating: false,
            pinned: true,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: NetworkImage(
                                  _userDoc!['profileImageUrl'] ?? '',
                                ),
                                child: _userDoc!['profileImageUrl'] == null ||
                                        _userDoc!['profileImageUrl']
                                            .toString()
                                            .isEmpty
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[400],
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              nickname ?? 'No nickname',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email ?? 'No email',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            // Bio Section - YENİ EKLENEN
                            if (bio.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF222831).withOpacity(0.3)
                                      : Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF948979)
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  bio,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFFDFD0B8)
                                        : const Color(0xFF222831),
                                    fontFamily: 'DMSerif',
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem('Followers', followers),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.3),
                                ),
                                _buildStatItem('Following', following),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isFollowing
                                      ? [
                                          Color(0xFFFF5722),
                                          Color(0xFFFF5722).withOpacity(0.8)
                                        ]
                                      : [
                                          Color(0xFF00BCD4),
                                          Color(0xFF00BCD4).withOpacity(0.8)
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isFollowing
                                            ? Color(0xFFFF5722)
                                            : Color(0xFF00BCD4))
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isFollowing
                                          ? Icons.person_remove
                                          : Icons.person_add,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isFollowing ? 'Unfollow' : 'Follow',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Shared Portfolios Section
                    _buildPortfolioList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
