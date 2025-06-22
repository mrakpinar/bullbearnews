import 'package:bullbearnews/widgets/community/announcements_tab.dart';
import 'package:bullbearnews/widgets/community/chat_rooms_tab.dart';
import 'package:bullbearnews/widgets/community/polls_tab.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: const [
                        ChatRoomsTab(),
                        PollsTab(),
                        AnnouncementsTab(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Hub',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831),
                    fontFamily: 'DMSerif',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect with other investors',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                    fontFamily: 'DMSerif',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor:
            isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
        labelColor: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
        unselectedLabelColor: isDark
            ? const Color(0xFFDFD0B8).withOpacity(0.7)
            : const Color(0xFF222831).withOpacity(0.7),
        labelStyle: const TextStyle(
          fontFamily: 'DMSerif',
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'DMSerif',
        ),
        tabs: const [
          Tab(text: 'Chats', icon: Icon(Icons.chat_bubble_outline)),
          Tab(text: 'Polls', icon: Icon(Icons.poll_outlined)),
          Tab(text: 'Announcements', icon: Icon(Icons.announcement_outlined)),
        ],
      ),
    );
  }
}
