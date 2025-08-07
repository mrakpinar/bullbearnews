import 'package:bullbearnews/widgets/community/announcements_tab.dart';
import 'package:bullbearnews/widgets/community/chat_rooms_tab.dart';
import 'package:bullbearnews/widgets/community/polls_tab.dart';
import 'package:flutter/material.dart';
import '../../../services/announcement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerAnimation;
  late Animation<double> _tabAnimation;

  final AnnouncementService _announcementService = AnnouncementService();
  bool _hasNewAnnouncements = false;
  String? _lastSeenAnnouncementId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAnimations();
    _loadLastSeenAnnouncement();
    _listenToAnnouncements();

    // Tab değiştirildiğinde dinle
    _tabController.addListener(_onTabChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _tabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeOut),
    );

    // Animasyonları sıralı başlat
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _tabAnimationController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _animationController.forward();
      }
    });
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

  void _onTabChanged() {
    // Notice tab'ına geçildiğinde (index 2)
    if (_tabController.index == 2 && _hasNewAnnouncements) {
      _markAnnouncementsAsSeen();
    }
  }

  void _markAnnouncementsAsSeen() async {
    // En son duyuruyu al ve görüldü olarak işaretle
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

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _headerAnimationController.dispose();
    _tabAnimationController.dispose();
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
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF393E46),
                                    const Color(0xFF948979),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: Color(0xFFDFD0B8),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Community Hub',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                                letterSpacing: -0.5,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect with other investors',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF948979)
                                : const Color(0xFF393E46),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar(bool isDark) {
    return AnimatedBuilder(
      animation: _tabAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _tabAnimation.value)),
          child: Opacity(
            opacity: _tabAnimation.value,
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              child: TabBar(
                controller: _tabController,
                indicatorColor:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                indicatorWeight: 3,
                labelColor:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                unselectedLabelColor: isDark
                    ? const Color(0xFFDFD0B8).withOpacity(0.6)
                    : const Color(0xFF222831).withOpacity(0.6),
                labelStyle: const TextStyle(
                  fontFamily: 'DMSerif',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'DMSerif',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text('Chats'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.poll_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text('Polls'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.announcement_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text('Notice'),
                          ],
                        ),
                        // Yeni bildirim badge'i
                        if (_hasNewAnnouncements)
                          Positioned(
                            right: -8,
                            top: -4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
