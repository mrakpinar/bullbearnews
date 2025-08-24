import 'package:bullbearnews/constants/colors.dart';
import 'package:bullbearnews/screens/analytics/analysis_screen.dart';
import 'package:bullbearnews/screens/videos/videos_screen.dart';
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'market/market_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';
import '../services/announcement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 4;
  late final PageController _pageController;
  late AnimationController _animationController;

  final AnnouncementService _announcementService = AnnouncementService();
  bool _hasNewAnnouncements = false;
  String? _lastSeenAnnouncementId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadLastSeenAnnouncement();
    _listenToAnnouncements();
  }

  void _loadLastSeenAnnouncement() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSeenAnnouncementId = prefs.getString('last_seen_announcement_id');
  }

  void _listenToAnnouncements() {
    _announcementService.getActiveAnnouncements().listen((announcements) {
      if (announcements.isNotEmpty) {
        final latestAnnouncement = announcements.first;

        // Eğer son görülen duyuru ID'si yoksa veya yeni bir duyuru varsa
        if (_lastSeenAnnouncementId == null ||
            _lastSeenAnnouncementId != latestAnnouncement.id) {
          if (mounted) {
            setState(() {
              _hasNewAnnouncements = true;
            });
          }
        }
      }
    });
  }

  final List<Widget> _screens = [
    HomeScreen(),
    CommunityScreen(),
    MarketScreen(),
    VideosScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
    _animationController.reset();
    _animationController.forward();

    // Community screen'e geçildiğinde badge'i güncelle
    if (index == 1 && _hasNewAnnouncements) {
      // Kısa bir gecikme ile badge'i temizle (kullanıcı community'ye girdi)
      Future.delayed(const Duration(milliseconds: 1000), () {
        _checkAndClearBadge();
      });
    }
  }

  void _checkAndClearBadge() async {
    // Aktif duyuruları kontrol et ve badge'i temizle
    final announcements =
        await _announcementService.getActiveAnnouncements().first;
    if (announcements.isNotEmpty) {
      final latestAnnouncement = announcements.first;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_seen_announcement_id', latestAnnouncement.id);

      if (mounted) {
        setState(() {
          _hasNewAnnouncements = false;
          _lastSeenAnnouncementId = latestAnnouncement.id;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: _buildModernNavigationBar(context),
    );
  }

  Widget _buildModernNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color.fromARGB(255, 23, 25, 28)
            : AppColors.lightCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                  0, Icons.home_outlined, Icons.home, 'News', isDarkMode),
              _buildNavItem(1, Icons.people_outline, Icons.people, 'Community',
                  isDarkMode,
                  hasNotification: _hasNewAnnouncements),
              _buildNavItem(2, Icons.trending_up_outlined, Icons.trending_up,
                  'Market', isDarkMode),
              _buildNavItem(3, Icons.play_circle_outline,
                  Icons.play_circle_filled, 'Videos', isDarkMode),
              _buildNavItem(4, Icons.analytics_outlined, Icons.analytics,
                  'Analytics', isDarkMode),
              _buildNavItem(
                  5, Icons.person_outline, Icons.person, 'Profile', isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled,
      String title, bool isDarkMode,
      {bool hasNotification = false}) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withOpacity(0.4)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(50)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        isSelected ? iconFilled : iconOutlined,
                        size: isSelected ? 26 : 22,
                        color: isSelected
                            ? AppColors.whiteText
                            : isDarkMode
                                ? AppColors.secondary.withOpacity(0.5)
                                : AppColors.primary.withOpacity(0.6),
                      ),
                    ),
                  ),
                  // Bildirim badge'i
                  if (hasNotification && !isSelected)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDarkMode
                                ? const Color.fromARGB(255, 23, 25, 28)
                                : AppColors.lightCard,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
