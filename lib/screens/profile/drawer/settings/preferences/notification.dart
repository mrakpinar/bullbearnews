import 'package:bullbearnews/services/notification_service.dart';
import 'package:bullbearnews/services/notification_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;

  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  // Settings State - will be loaded from Firebase
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;

    try {
      final settings = await _settingsService.getUserSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      if (mounted) {
        setState(() {
          _settings = _settingsService.defaultSettings;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (!mounted) return;

    setState(() {
      _settings[key] = value;
    });

    try {
      await _settingsService.updateSetting(key, value);

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setting updated successfully'),
            backgroundColor: const Color(0xFF948979),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error updating setting: $e');
      // Revert state on error
      if (mounted) {
        setState(() {
          _settings[key] = !value; // Revert the toggle
        });
      }
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF948979),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _buildContent(isDark),
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
                  // Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF393E46).withOpacity(0.8)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF393E46),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF222831),
                            letterSpacing: -0.5,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your alerts and preferences',
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

                  // Reset Button
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF393E46).withOpacity(0.8)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showResetDialog(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.refresh,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF393E46),
                            size: 20,
                          ),
                        ),
                      ),
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

  Widget _buildContent(bool isDark) {
    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _contentAnimation.value)),
          child: Opacity(
            opacity: _contentAnimation.value,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF393E46).withOpacity(0.7)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF948979).withOpacity(0.2)
                            : const Color(0xFF393E46).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF393E46), Color(0xFF948979)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: const Color(0xFFDFD0B8),
                      unselectedLabelColor: const Color(0xFF948979),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'DMSerif',
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        fontFamily: 'DMSerif',
                      ),
                      tabs: const [
                        Tab(text: 'Settings'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSettingsTab(isDark),
                        _buildHistoryTab(isDark),
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

  Widget _buildSettingsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General Notifications
          _buildSection(
            title: 'General',
            isDark: isDark,
            children: [
              _buildToggleCard(
                icon: (_settings['pushNotificationsEnabled'] ?? true)
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                title: 'Push Notifications',
                description: 'Enable all notifications',
                value: _settings['pushNotificationsEnabled'] ?? true,
                onChanged: (value) =>
                    _updateSetting('pushNotificationsEnabled', value),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Notifications
          _buildSection(
            title: 'App Activities',
            isDark: isDark,
            children: [
              _buildToggleCard(
                icon: Icons.person_add,
                title: 'Follow Notifications',
                description: 'When someone follows you',
                value: _settings['followNotificationsEnabled'] ?? true,
                onChanged: (value) =>
                    _updateSetting('followNotificationsEnabled', value),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildToggleCard(
                icon: Icons.favorite,
                title: 'Portfolio Likes',
                description: 'When someone likes your portfolio',
                value: _settings['likeNotificationsEnabled'] ?? true,
                onChanged: (value) =>
                    _updateSetting('likeNotificationsEnabled', value),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildToggleCard(
                icon: Icons.share,
                title: 'Portfolio Shares',
                description: 'When followers share portfolios',
                value: _settings['shareNotificationsEnabled'] ?? true,
                onChanged: (value) =>
                    _updateSetting('shareNotificationsEnabled', value),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // News Categories (Removed Category Updates and Weekly Digest)
          _buildSection(
            title: 'News Categories',
            isDark: isDark,
            children: [
              _buildToggleCard(
                icon: Icons.priority_high,
                title: 'Breaking News',
                description: 'Urgent news updates',
                value: _settings['breakingNewsEnabled'] ?? true,
                onChanged: (value) =>
                    _updateSetting('breakingNewsEnabled', value),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildToggleCard(
                icon: Icons.trending_up,
                title: 'Trending News',
                description: 'Popular stories',
                value: _settings['trendingNewsEnabled'] ?? true,
                onChanged: (value) =>
                    _updateSetting('trendingNewsEnabled', value),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationService.getUserNotifications(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF948979)),
          );
        }

        // Error state
        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: const Color(0xFF948979).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading notifications',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831),
                    fontFamily: 'DMSerif',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {}); // Force rebuild
                  },
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Color(0xFF948979),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // No connection state
        if (snapshot.connectionState == ConnectionState.none) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: const Color(0xFF948979).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No connection',
                  style: TextStyle(
                    fontSize: 18,
                    color: const Color(0xFF948979),
                    fontFamily: 'DMSerif',
                  ),
                ),
              ],
            ),
          );
        }

        // Data processing
        final notifications = snapshot.data?.docs ?? [];

        // Empty state
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: const Color(0xFF948979).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: const Color(0xFF948979),
                    fontFamily: 'DMSerif',
                  ),
                ),
              ],
            ),
          );
        }

        // Success state with data
        return ListView.builder(
          key: ValueKey('notifications_list_${notifications.length}'),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: notifications.length,
          cacheExtent: 1000, // Optimize performance
          itemBuilder: (context, index) {
            try {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>?;

              if (data == null) {
                return const SizedBox.shrink(); // Skip invalid data
              }

              return _buildNotificationHistoryCard(
                notification.id,
                data,
                isDark,
              );
            } catch (e) {
              print('Error building notification item at index $index: $e');
              return const SizedBox.shrink(); // Skip problematic items
            }
          },
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              letterSpacing: -0.3,
              fontFamily: 'DMSerif',
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.7)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF948979).withOpacity(0.2)
              : const Color(0xFF393E46).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF948979).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF393E46),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831),
                    fontFamily: 'DMSerif',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF948979),
                    fontFamily: 'DMSerif',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF948979),
            activeTrackColor: const Color(0xFF948979).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF948979).withOpacity(0.5),
            inactiveTrackColor: const Color(0xFF948979).withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistoryCard(
      String notificationId, Map<String, dynamic> data, bool isDark) {
    // Safely extract data with null checks
    final isRead = data['isRead'] as bool? ?? false;
    final type = data['type'] as String? ?? '';
    final senderName = data['senderNickname'] as String? ??
        data['senderName'] as String? ??
        'Unknown';
    final message = data['message'] as String? ?? '';
    final createdAt = data['createdAt'] as Timestamp?;

    String timeAgo = 'Unknown time';
    if (createdAt != null) {
      try {
        final difference = DateTime.now().difference(createdAt.toDate());
        if (difference.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (difference.inHours < 1) {
          timeAgo = '${difference.inMinutes}m ago';
        } else if (difference.inDays < 1) {
          timeAgo = '${difference.inHours}h ago';
        } else {
          timeAgo = '${difference.inDays}d ago';
        }
      } catch (e) {
        print('Error calculating time difference: $e');
        timeAgo = 'Unknown time';
      }
    }

    return Container(
      key: ValueKey('notification_$notificationId'), // Add unique key
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.7)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? (isDark
                  ? const Color(0xFF948979).withOpacity(0.1)
                  : const Color(0xFF393E46).withOpacity(0.05))
              : const Color(0xFF948979).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notificationId, data),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationTypeColor(type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationTypeIcon(type),
                    color: _getNotificationTypeColor(type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getNotificationTitle(type, senderName),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF948979),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.isNotEmpty ? message : 'No message',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF948979),
                          fontFamily: 'DMSerif',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getNotificationTypeColor(type)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getNotificationTypeLabel(type),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getNotificationTypeColor(type),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF948979),
                              fontFamily: 'DMSerif',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF948979),
                    size: 20,
                  ),
                  color: isDark ? const Color(0xFF393E46) : Colors.white,
                  onSelected: (value) =>
                      _handleNotificationAction(notificationId, value, isRead),
                  itemBuilder: (context) => [
                    if (!isRead)
                      PopupMenuItem(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read,
                                size: 16, color: Color(0xFF948979)),
                            const SizedBox(width: 8),
                            Text(
                              'Mark as read',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_forever_sharp,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'DMSerif',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'follow':
        return Colors.blue;
      case 'like_portfolio':
        return Colors.red;
      case 'share_portfolio':
        return Colors.green;
      default:
        return const Color(0xFF948979);
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add;
      case 'like_portfolio':
        return Icons.favorite;
      case 'share_portfolio':
        return Icons.share;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTitle(String type, String senderName) {
    switch (type) {
      case 'follow':
        return 'New Follower';
      case 'like_portfolio':
        return 'Portfolio Liked';
      case 'share_portfolio':
        return 'Portfolio Shared';
      default:
        return 'Notification';
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'follow':
        return 'Follow';
      case 'like_portfolio':
        return 'Like';
      case 'share_portfolio':
        return 'Share';
      default:
        return 'General';
    }
  }

  Future<void> _handleNotificationTap(
      String notificationId, Map<String, dynamic> data) async {
    // Mark as read if not already read
    if (!(data['isRead'] ?? false)) {
      await _notificationService.markAsRead(notificationId);
    }

    // Handle navigation based on notification type
    // You can implement navigation logic here
  }

  Future<void> _handleNotificationAction(
      String notificationId, String action, bool isRead) async {
    try {
      switch (action) {
        case 'mark_read':
          await _notificationService.markAsRead(notificationId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification marked as read'),
                backgroundColor: Color(0xFF948979),
              ),
            );
          }
          break;
        case 'delete':
          await _notificationService.deleteNotification(notificationId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification deleted'),
                backgroundColor: Color(0xFF948979),
              ),
            );
          }
          break;
      }
    } catch (e) {
      print('Error handling notification action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF393E46) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reset Settings',
            style: TextStyle(
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
          content: Text(
            'Are you sure you want to reset all notification settings to default?',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF948979),
                  fontFamily: 'DMSerif',
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _settingsService.resetToDefaults();
                  await _loadSettings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings reset to defaults'),
                        backgroundColor: Color(0xFF948979),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error resetting settings: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Error resetting settings. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'DMSerif',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
