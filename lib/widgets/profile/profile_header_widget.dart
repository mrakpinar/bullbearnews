import 'package:bullbearnews/widgets/profile/profile_action_button.dart';
import 'package:flutter/material.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Animation<double> headerAnimation;
  final bool isDark;
  final GlobalKey<ScaffoldState> scaffoldKey;
  const ProfileHeaderWidget(
      {super.key,
      required this.headerAnimation,
      required this.isDark,
      required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - headerAnimation.value)),
          child: Opacity(
            opacity: headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Logo and Title
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
                                Icons.person_outline,
                                color: Color(0xFFDFD0B8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'My Profile',
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
                          'Manage your portfolio & preferences',
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

                  // Action button (Drawer)
                  ProfileActionButton(
                    icon: Icons.menu,
                    onTap: () => scaffoldKey.currentState?.openDrawer(),
                    isDark: isDark,
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
