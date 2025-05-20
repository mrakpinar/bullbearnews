import 'package:bullbearnews/screens/videos/videos_screen.dart';
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'market/market_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // PageController'ı Home ekranı ile başlatın
    _pageController = PageController(initialPage: _selectedIndex);
  }

  // Screens'i önbelleğe al
  final List<Widget> _screens = const [
    MarketScreen(),
    VideosScreen(),
    HomeScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Aynı sayfaya tekrar tıklamayı önle

    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index); // Animasyon yerine direkt geçiş
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics:
            const AlwaysScrollableScrollPhysics(), // Swipe'ı devre dışı bırak
        children: _screens,
      ),
      bottomNavigationBar: _buildNavigationBar(context),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      indicatorColor: Theme.of(context)
          .primaryColor
          .withOpacity(0.2), // Seçili tab için arkaplan rengi

      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.show_chart_outlined),
          selectedIcon: Icon(
            Icons.show_chart,
            color: Colors.white,
            size: 35,
          ),
          label: 'Market',
        ),
        const NavigationDestination(
          icon: Icon(Icons.video_library_outlined),
          selectedIcon: Icon(
            Icons.video_library_rounded,
            color: Colors.white,
            size: 35,
          ),
          label: 'Videos',
        ),
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(
            Icons.home,
            color: Colors.white,
            size: 35,
          ),
          label: 'News',
        ),
        const NavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(
            Icons.group,
            color: Colors.white,
            size: 35,
          ),
          label: 'Community',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(
            Icons.person,
            color: Colors.white,
            size: 35,
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
