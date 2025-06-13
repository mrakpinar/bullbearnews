import 'package:bullbearnews/screens/profile/portfolio_detail_screen.dart';
import 'package:bullbearnews/screens/profile/settings_screen.dart';
import 'package:bullbearnews/screens/profile/wallet_detail_screen.dart';
import 'package:bullbearnews/screens/profile/wallets_screen.dart';
import 'package:bullbearnews/services/auth_service.dart';
import 'package:bullbearnews/widgets/favorite_cryptos_list.dart';
import 'package:bullbearnews/widgets/portfolio_pie_chart.dart';
import 'package:bullbearnews/widgets/saved_news_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/theme_provider.dart';
import '../../models/crypto_model.dart';
import '../../models/wallet_model.dart';
import '../../services/crypto_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final CryptoService _cryptoService = CryptoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<CryptoModel> _favoriteCryptos = [];
  List<WalletItem> _walletItems = [];
  bool _isLoading = true;
  bool _isWalletLoading = true;
  bool _isNewsLoading = false;
  String _errorMessage = '';
  double _totalPortfolioValue = 0;
  double _totalInvestment = 0;
  double _totalProfitLoss = 0;
  double _totalProfitLossPercentage = 0;
  String? _profileImageUrl;
  List<Map<String, dynamic>> _mySharedPortfolios = [];
  bool _isLoadingSharedPortfolios = true;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadData();
    _loadMySharedPortfolios();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMySharedPortfolios() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sharedPortfolios')
          .get();

      if (mounted) {
        // Add this check
        setState(() {
          _mySharedPortfolios = snapshot.docs.map((doc) => doc.data()).toList();
          _isLoadingSharedPortfolios = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Add this check
        setState(() => _isLoadingSharedPortfolios = false);
      }
    }
  }

  Widget _buildSharedPortfolioItem(Map<String, dynamic> portfolio) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('wallets')
          .doc(portfolio['walletId'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(title: Text('Loading...'));
        }

        final wallet =
            Wallet.fromJson(snapshot.data!.data() as Map<String, dynamic>);
        return Card(
          child: ListTile(
            leading: Icon(Icons.wallet),
            title: Text(wallet.name),
            subtitle: Text(
                'Views: ${portfolio['viewCount']} • Likes: ${portfolio['likes']?.length ?? 0}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _unsharePortfolio(portfolio['walletId']),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletDetailScreen(
                    wallet: wallet,
                    onUpdate: () async {
                      await _loadWalletItems();
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _unsharePortfolio(String walletId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unshare Portfolio'),
        content: Text('Do you want to stop sharing this portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Unshare'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sharedPortfolios')
            .doc(walletId)
            .delete();

        _loadMySharedPortfolios();
      }
    }
  }

  Future<void> _loadProfileImage() async {
    const defaultImageUrl =
        "https://isobarscience.com/wp-content/uploads/2020/09/default-profile-picture1.jpg";

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String? imageUrl;
        if (userDoc.exists &&
            userDoc.data()!.containsKey('profileImageUrl') &&
            userDoc.data()!['profileImageUrl'] != null &&
            userDoc.data()!['profileImageUrl'].toString().trim().isNotEmpty) {
          imageUrl = userDoc.data()!['profileImageUrl'];
        }

        if (imageUrl == null || imageUrl.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final savedImageUrl = prefs.getString('profileImageUrl');
          if (savedImageUrl != null && savedImageUrl.trim().isNotEmpty) {
            imageUrl = savedImageUrl;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'profileImageUrl': savedImageUrl});
          }
        }

        if (mounted) {
          setState(() {
            _profileImageUrl = (imageUrl != null && imageUrl.trim().isNotEmpty)
                ? imageUrl
                : defaultImageUrl;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _profileImageUrl = defaultImageUrl;
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
      if (mounted) {
        setState(() {
          _profileImageUrl = defaultImageUrl;
        });
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // Configure Cloudinary
        final cloudinary = CloudinaryPublic(
            'dh7lpyg7t', // Your Cloudinary cloud name
            'upload_image', // Your upload preset
            cache: false);

        // Upload image to Cloudinary
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            pickedFile.path,
            folder: 'profile_images',
            publicId: 'profile_${FirebaseAuth.instance.currentUser!.uid}',
          ),
        );

        // Save image URL to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageUrl', response.secureUrl);

        // Update user's profile in Firebase Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profileImageUrl': response.secureUrl});
        }

        // Update local state
        setState(() {
          _profileImageUrl = response.secureUrl;
        });

        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    try {
      await _loadFavoriteCryptos();
      await _loadWalletItems();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  Future<void> _loadFavoriteCryptos() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final List<CryptoModel> allCryptos = await _cryptoService.getCryptoData();
      final prefs = await SharedPreferences.getInstance();
      final List<String> favoriteIds =
          prefs.getStringList('favoriteCryptos') ?? [];

      _favoriteCryptos = allCryptos
          .where((crypto) => favoriteIds.contains(crypto.id))
          .toList();

      _favoriteCryptos.sort((a, b) => b.marketCap.compareTo(a.marketCap));
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while loading favorites: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadWalletItems() async {
    if (!mounted) return;

    setState(() => _isWalletLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .get();

      List<WalletItem> allItems = [];
      for (var doc in snapshot.docs) {
        final wallet = Wallet.fromJson(doc.data()).copyWith(id: doc.id);
        allItems.addAll(wallet.items);
      }

      setState(() {
        _walletItems = allItems;
      });

      await _calculatePortfolioValues();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred while loading wallet: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isWalletLoading = false);
      }
    }
  }

  Future<void> _addToWallet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletsScreen(),
      ),
    );

    // Eğer result true ise (yeni coin eklendiyse) verileri yenile
    if (result == true) {
      await _loadWalletItems();
    }
  }

  Future<void> _calculatePortfolioValues() async {
    double totalValue = 0;
    double totalInvestment = 0;

    try {
      final List<CryptoModel> allCryptos = await _cryptoService.getCryptoData();

      for (var item in _walletItems) {
        final crypto = allCryptos.firstWhere(
          (c) => c.id == item.cryptoId,
          orElse: () => CryptoModel(
            id: item.cryptoId,
            name: item.cryptoName,
            symbol: item.cryptoSymbol,
            image: item.cryptoImage,
            currentPrice: 0,
            priceChangePercentage24h: 0,
            marketCap: 0,
            totalVolume: 0,
            circulatingSupply: 0,
            ath: 0,
            atl: 0,
          ),
        );

        totalValue += item.amount * crypto.currentPrice;
        totalInvestment += item.amount * item.buyPrice;
      }

      double profitLoss = totalValue - totalInvestment;
      double profitLossPercentage =
          totalInvestment > 0 ? (profitLoss / totalInvestment) * 100 : 0;

      if (mounted) {
        setState(() {
          _totalPortfolioValue = totalValue;
          _totalInvestment = totalInvestment;
          _totalProfitLoss = profitLoss;
          _totalProfitLossPercentage = profitLossPercentage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error calculating portfolio: $e';
        });
      }
    }
  }

  String formatPrice(double price) {
    return price
        .toStringAsFixed(5)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _showPortfolioDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get the active wallet from Firestore
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wallets')
        .get();

    if (snapshot.docs.isNotEmpty) {
      final wallet = Wallet.fromJson(snapshot.docs.first.data())
          .copyWith(id: snapshot.docs.first.id);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PortfolioDetailScreen(
            wallet: wallet,
            onUpdate: () async {
              await _loadWalletItems();
              if (mounted) setState(() {});
            },
          ),
        ),
      );
    } else {
      // No wallet found, show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No wallet found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSaveNews() async {
    if (mounted) {
      setState(() => _isNewsLoading = true);
    }
    await Future.delayed(
      const Duration(microseconds: 500),
    );
    if (mounted) {
      setState(() => _isNewsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey, // Scaffold key eklendi
      backgroundColor: theme.colorScheme.background,
      drawer: _buildDrawer(context), // Drawer eklendi
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF393E46), const Color(0xFF393E46)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  "My Profile",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: -1,
                  ),
                ),
                titlePadding: const EdgeInsets.only(bottom: 16),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.menu, // Geri tuşu yerine menü ikonu
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (user == null)
                  Center(
                    child: Text(
                      'Please log in to view your profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDarkMode
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // User Profile Card
                      _buildUserProfileCard(context, theme, isDarkMode),

                      const SizedBox(height: 24),

                      // Portfolio Summary Card
                      _buildPortfolioSummaryCard(theme, isDarkMode),

                      const SizedBox(height: 24),

                      // Portfolio Pie Chart
                      FutureBuilder<List<CryptoModel>>(
                        future: _cryptoService.getCryptoData(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: isDarkMode
                                      ? const Color(0xFF393E46).withOpacity(0.7)
                                      : const Color(0xFFF5F5F5)
                                          .withOpacity(0.7),
                                ),
                                child: const CircularProgressIndicator(),
                              ),
                            );
                          }
                          return _buildGlassSection(
                            title: 'Portfolio Distribution',
                            theme: theme,
                            isDarkMode: isDarkMode,
                            children: [
                              PortfolioPieChart(
                                walletItems: _walletItems,
                                allCryptos: snapshot.data!,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Favorite Cryptos
                      _buildGlassSection(
                        title: 'Favorite Cryptos',
                        theme: theme,
                        isDarkMode: isDarkMode,
                        children: [
                          FavoriteCryptosList(
                            isLoading: _isLoading,
                            favoriteCryptos: _favoriteCryptos,
                            onRefresh: _loadFavoriteCryptos,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Saved News
                      _buildGlassSection(
                        title: 'Saved News',
                        theme: theme,
                        isDarkMode: isDarkMode,
                        children: [
                          SavedNewsList(
                            isLoading: _isNewsLoading,
                            onRefresh: _loadSaveNews,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Shared Portfolios
                      if (!_isLoadingSharedPortfolios &&
                          _mySharedPortfolios.isNotEmpty)
                        _buildGlassSection(
                          title: 'Shared Portfolios',
                          theme: theme,
                          isDarkMode: isDarkMode,
                          children: [
                            ..._mySharedPortfolios.map((portfolio) =>
                                _buildSharedPortfolioItem(portfolio)),
                          ],
                        ),

                      const SizedBox(height: 50),
                    ],
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(
      BuildContext context, ThemeData theme, bool isDarkMode) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF393E46), const Color(0xFF393E46)]
              : [const Color(0xFFF5F5F5), const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF393E46).withOpacity(0.3)
              : const Color(0xFFE0E0E0).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? const Color(0xFF222831).withOpacity(0.3)
                : const Color(0xFFDFD0B8).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _uploadProfileImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF948979).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _profileImageUrl != null
                    ? Image.network(
                        _profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 40,
                          color: isDarkMode
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 40,
                        color: isDarkMode
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Guest User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Not logged in',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF948979),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: const Color(0xFF948979).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? Colors.black54 : Colors.grey[300]!,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/default_profile.png')
                          as ImageProvider,
                ),
                const SizedBox(height: 10),
                Text(
                  user?.displayName ?? 'Guest',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Mono',
                  ),
                ),
                Text(
                  user?.email ?? 'Not logged in',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Mono',
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: theme.iconTheme.color),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/auth',
                (route) => false,
              );
            },
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet,
                color: theme.iconTheme.color),
            title: const Text('Wallet'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WalletsScreen()),
              );
            },
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: theme.iconTheme.color),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()));
            },
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          ListTile(
            leading: Icon(Icons.help_outline, color: theme.iconTheme.color),
            title: const Text('Help & Feedback'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: theme.iconTheme.color),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/auth',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSummaryCard(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF393E46), const Color(0xFF393E46)]
              : [const Color(0xFFF5F5F5), const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF393E46).withOpacity(0.3)
              : const Color(0xFFE0E0E0).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? const Color(0xFF222831).withOpacity(0.3)
                : const Color(0xFFDFD0B8).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portfolio Value',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                ),
              ),
              Text(
                '\$${_totalPortfolioValue.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investment',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF948979),
                    ),
                  ),
                  Text(
                    '\$${_totalInvestment.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Profit/Loss',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF948979),
                    ),
                  ),
                  Text(
                    '${_totalProfitLossPercentage.toStringAsFixed(2)}% (\$${_totalProfitLoss.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontSize: 16,
                      color: _totalProfitLoss >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add,
                  label: 'Add Coin',
                  onPressed: _addToWallet,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.pie_chart_outline,
                  label: 'Details',
                  onPressed: _showPortfolioDetails,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF948979).withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFF948979).withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color:
                isDarkMode ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFDFD0B8)
                  : const Color(0xFF222831),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSection({
    required String title,
    required ThemeData theme,
    required bool isDarkMode,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              Column(children: children),
            ],
          ),
        ),
      ],
    );
  }
}
