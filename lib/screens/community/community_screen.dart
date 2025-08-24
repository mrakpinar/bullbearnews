import 'package:bullbearnews/widgets/community/announcements/announcements_tab.dart';
import 'package:bullbearnews/widgets/community/chat/chat_rooms_tab.dart';
import 'package:bullbearnews/widgets/community/header_widget.dart';
import 'package:bullbearnews/widgets/community/polls/polls_tab.dart';
import 'package:bullbearnews/widgets/community/tab_bar_widget.dart';
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
            HeaderWidget(
              isDark: isDark,
              headerAnimation: _headerAnimation,
            ),
            TabBarWidget(
              isDark: isDark,
              tabAnimation: _tabAnimation,
              tabController: _tabController,
              hasNewAnnouncements: _hasNewAnnouncements,
            ),
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
}
