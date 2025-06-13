import 'package:bullbearnews/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar with gradient
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF393E46), const Color(0xFF393E46)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  "Settings",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                titlePadding: const EdgeInsets.only(bottom: 16),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // Hero Theme Card
                _buildHeroThemeCard(themeProvider, isDarkMode, theme),

                const SizedBox(height: 32),

                // Preferences Section with glassmorphism
                _buildGlassSection(
                  title: 'Preferences',
                  theme: theme,
                  isDarkMode: isDarkMode,
                  children: [
                    _buildModernTile(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Manage your alerts',
                      theme: theme,
                      isDarkMode: isDarkMode,
                      onTap: () {},
                      accentColor: const Color(0xFF948979), // secondary color
                    ),
                    const SizedBox(height: 12),
                    _buildModernTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Security',
                      subtitle: 'Control your data',
                      theme: theme,
                      isDarkMode: isDarkMode,
                      onTap: () {},
                      accentColor: const Color(0xFF948979), // accent color
                    ),
                    const SizedBox(height: 12),
                    _buildModernTile(
                      icon: Icons.translate,
                      title: 'Language',
                      subtitle: 'Choose your language',
                      theme: theme,
                      isDarkMode: isDarkMode,
                      onTap: () {},
                      accentColor: const Color(0xFF948979), // secondary color
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Support Section
                _buildGlassSection(
                  title: 'Support',
                  theme: theme,
                  isDarkMode: isDarkMode,
                  children: [
                    _buildModernTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help Center',
                      subtitle: 'Get instant help',
                      theme: theme,
                      isDarkMode: isDarkMode,
                      onTap: () {},
                      accentColor: const Color(0xFF948979), // accent color
                    ),
                    const SizedBox(height: 12),
                    _buildModernTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About App',
                      subtitle: 'Version & details',
                      theme: theme,
                      isDarkMode: isDarkMode,
                      onTap: () {},
                      accentColor: const Color(0xFF948979), // secondary color
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroThemeCard(
      ThemeProvider themeProvider, bool isDarkMode, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF393E46), // darkCard
                  const Color(0xFF393E46).withOpacity(0.8),
                ]
              : [
                  const Color(0xFFF5F5F5), // lightCard
                  const Color(0xFFF5F5F5).withOpacity(0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF393E46).withOpacity(0.3) // dividerDark
              : const Color(0xFFE0E0E0).withOpacity(0.5), // dividerLight
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? const Color(0xFF222831).withOpacity(0.3) // darkBackground
                : const Color(0xFFDFD0B8).withOpacity(0.2), // lightBackground
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Large theme icon with animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        const Color(0xFF948979).withOpacity(0.3), // secondary
                        const Color(0xFFDFD0B8).withOpacity(0.2), // accent
                      ]
                    : [
                        const Color(0xFFDFD0B8).withOpacity(0.4), // accent
                        const Color(0xFF948979).withOpacity(0.3), // secondary
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDarkMode
                  ? const Color(0xFFDFD0B8) // lightText
                  : const Color(0xFF222831), // darkText
              size: 40,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Theme Preference',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? const Color(0xFFDFD0B8) // lightText
                  : const Color(0xFF222831), // darkText
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isDarkMode ? 'Dark Mode Active' : 'Light Mode Active',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF948979), // secondary color for subtitle
            ),
          ),

          const SizedBox(height: 24),

          // Custom toggle button
          GestureDetector(
            onTap: () => themeProvider.toggleTheme(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF948979).withOpacity(0.2), // secondary
                    const Color(0xFF948979).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF948979).withOpacity(0.3), // secondary
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: isDarkMode
                        ? const Color(0xFFDFD0B8) // lightText
                        : const Color(0xFF222831), // darkText
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Switch to ${isDarkMode ? "Light" : "Dark"} Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? const Color(0xFFDFD0B8) // lightText
                          : const Color(0xFF222831), // darkText
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSection({
    required String title,
    required ThemeData theme,
    required bool isDarkMode,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDarkMode
                  ? const Color(0xFFDFD0B8) // lightText
                  : const Color(0xFF222831), // darkText
              letterSpacing: -0.8,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF393E46).withOpacity(0.7) // darkCard
                : const Color(0xFFF5F5F5).withOpacity(0.7), // lightCard
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF393E46).withOpacity(0.3) // dividerDark
                  : const Color(0xFFE0E0E0).withOpacity(0.5), // dividerLight
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? const Color(0xFF222831).withOpacity(0.2) // darkBackground
                    : const Color(0xFFDFD0B8)
                        .withOpacity(0.1), // lightBackground
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildModernTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required bool isDarkMode,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.1),
                accentColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isDarkMode
                      ? const Color(0xFFDFD0B8) // lightText
                      : const Color(0xFF222831), // darkText
                  size: 24,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? const Color(0xFFDFD0B8) // lightText
                            : const Color(0xFF222831), // darkText
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(
                            0xFF948979), // secondary color for subtitle
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFF948979), // secondary
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
