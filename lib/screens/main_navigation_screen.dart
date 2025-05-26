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

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  late final PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

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
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
    _animationController.reset();
    _animationController.forward();
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
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      extendBody:
          true, // Bu sayede body içeriği navigation bar'ın arkasına kadar uzanacak
      bottomNavigationBar: _buildModernNavigationBar(context),
    );
  }

  Widget _buildModernNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final primaryColor = theme.primaryColor;
    final backgroundColor = isDarkMode
        ? Colors.grey[900]!.withOpacity(1)
        : Colors.white.withOpacity(0.95);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      height: 75,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.show_chart_outlined, Icons.show_chart,
              'Market', primaryColor, isDarkMode),
          _buildNavItem(1, Icons.video_library_outlined, Icons.video_library,
              'Videos', primaryColor, isDarkMode),
          _buildNavItem(2, Icons.home_outlined, Icons.home, 'News',
              primaryColor, isDarkMode),
          _buildNavItem(3, Icons.group_outlined, Icons.group, 'Community',
              primaryColor, isDarkMode),
          _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile',
              primaryColor, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled,
      String title, Color primaryColor, bool isDarkMode) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color:
                isSelected ? primaryColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isSelected ? 4 : 0,
                width: isSelected ? 30 : 0,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode ? Colors.white : primaryColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Icon(
                isSelected ? iconFilled : iconOutlined,
                size: isSelected ? 30 : 24,
                color: isSelected
                    ? Colors.white
                    : isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? primaryColor
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
