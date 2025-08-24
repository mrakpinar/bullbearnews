import 'package:flutter/material.dart';

class TabBarWidget extends StatelessWidget {
  final bool isDark;
  final Animation<double> tabAnimation;
  final TabController tabController;
  final bool hasNewAnnouncements;

  const TabBarWidget(
      {super.key,
      required this.isDark,
      required this.tabAnimation,
      required this.tabController,
      required this.hasNewAnnouncements});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - tabAnimation.value)),
          child: Opacity(
            opacity: tabAnimation.value,
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              child: TabBar(
                controller: tabController,
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
                        if (hasNewAnnouncements)
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
