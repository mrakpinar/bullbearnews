import 'package:bullbearnews/screens/profile/add_to_wallet_screen.dart';
import 'package:bullbearnews/screens/profile/portfolio_detail_screen.dart';
import 'package:bullbearnews/services/auth_service.dart';
import 'package:bullbearnews/widgets/favorite_cryptos_list.dart';
import 'package:bullbearnews/widgets/saved_news_list.dart';
import 'package:bullbearnews/widgets/user_profile_header.dart';
import 'package:bullbearnews/widgets/wallet_summary_card.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadData();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImageUrl = prefs.getString('profileImageUrl');
    });
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
            folder: 'profile_images', // Optional folder in Cloudinary
            publicId: 'profile_${FirebaseAuth.instance.currentUser!.uid}',
          ),
        );

        // Save image URL to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageUrl', response.secureUrl);

        // Update user's profile in Firebase
        await _authService.updateProfileImage(response.secureUrl);

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
    await _loadFavoriteCryptos();
    await _loadWalletItems();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadWalletItems() async {
    if (mounted) {
      setState(() => _isWalletLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> walletItemsJson =
          prefs.getStringList('walletItems') ?? [];

      _walletItems = walletItemsJson
          .map((item) => WalletItem.fromJson(json.decode(item)))
          .toList();

      await _calculatePortfolioValues();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while loading wallet: $e';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
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
        builder: (context) => AddToWalletScreen(
          cryptos: _favoriteCryptos,
        ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
            ),
          );
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PortfolioDetailScreen(
          walletItems: _walletItems,
          onUpdate: () async {
            await _loadWalletItems();
            if (mounted) setState(() {});
          },
        ),
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                UserProfileHeader(
                  user: user,
                  profileImageUrl: _profileImageUrl,
                  onImageUpload: _uploadProfileImage,
                ),
                const SizedBox(height: 32),
                WalletSummaryCard(
                  totalPortfolioValue: _totalPortfolioValue,
                  totalInvestment: _totalInvestment,
                  totalProfitLoss: _totalProfitLoss,
                  totalProfitLossPercentage: _totalProfitLossPercentage,
                  onAddToWallet: _addToWallet,
                  onShowDetails: _showPortfolioDetails,
                ),
                const SizedBox(height: 32),
                FavoriteCryptosList(
                  isLoading: _isLoading,
                  favoriteCryptos: _favoriteCryptos,
                  onRefresh: _loadFavoriteCryptos,
                ),
                const SizedBox(height: 32),
                SavedNewsList(
                    isLoading: _isNewsLoading, onRefresh: _loadSaveNews)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
