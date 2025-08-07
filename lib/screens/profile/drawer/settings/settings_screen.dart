import 'package:bullbearnews/providers/theme_provider.dart';
import 'package:bullbearnews/screens/profile/drawer/settings/preferences/notification.dart';
import 'package:bullbearnews/screens/profile/drawer/settings/preferences/privacy_security.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
      body: SafeArea(
        child: Column(
          children: [
            // Header Widget
            _buildHeader(isDarkMode),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Theme Card
                    _buildThemeCard(themeProvider, isDarkMode),

                    const SizedBox(height: 24),

                    // Preferences Section
                    _buildSection(
                      title: 'Preferences',
                      isDarkMode: isDarkMode,
                      children: [
                        _buildTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Manage your alerts',
                          isDarkMode: isDarkMode,
                          onTap: () => _navigateToNotification(context),
                          color: const Color(0xFF667eea),
                        ),
                        const SizedBox(height: 12),
                        _buildTile(
                          icon: Icons.shield_outlined,
                          title: 'Privacy & Security',
                          subtitle: 'Control your data',
                          isDarkMode: isDarkMode,
                          onTap: () => _navigateToPrivacySecurity(context),
                          color: const Color(0xFF11998e),
                        ),
                        const SizedBox(height: 12),
                        _buildTile(
                          icon: Icons.language_outlined,
                          title: 'Language',
                          subtitle: 'Choose your language',
                          isDarkMode: isDarkMode,
                          onTap: () => _showLanguageDialog(context),
                          color: const Color.fromARGB(255, 80, 5, 150),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Support Section
                    _buildSection(
                      title: 'Support & Info',
                      isDarkMode: isDarkMode,
                      children: [
                        _buildTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help Center',
                          subtitle: 'Get instant help',
                          isDarkMode: isDarkMode,
                          onTap: () => _showHelpDialog(context),
                          color: const Color.fromARGB(255, 184, 62, 197),
                        ),
                        const SizedBox(height: 12),
                        _buildTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About BBN',
                          subtitle: 'Version 1.0.0',
                          isDarkMode: isDarkMode,
                          onTap: () => _showAboutDialog(context),
                          color: const Color.fromARGB(255, 4, 119, 219),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Header Widget (Settings screen için)
  Widget _buildHeader(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Back button
            _buildActionButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Navigator.of(context).pop(),
              isDark: isDark,
            ),

            // Centered Settings Title
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 26,
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
            ),
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
                Icons.settings_rounded,
                color: Color(0xFFDFD0B8),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF393E46),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(ThemeProvider themeProvider, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF393E46) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF948979).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Theme icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF393E46), Color(0xFF948979)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Theme Preference',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? const Color(0xFFDFD0B8)
                  : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF948979).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            child: Text(
              isDarkMode ? '🌙 Dark Mode' : '☀️ Light Mode',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF948979),
                fontWeight: FontWeight.w600,
                fontFamily: 'DMSerif',
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Toggle button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => themeProvider.toggleTheme(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 1.2,
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF948979), Color(0xFF393E46)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Switch to ${isDarkMode ? "Light" : "Dark"} Mode',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDarkMode,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? const Color(0xFFDFD0B8)
                  : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF393E46).withOpacity(0.5)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF948979).withOpacity(0.2),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
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
                        color: isDarkMode
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF948979),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToNotification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void _navigateToPrivacySecurity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacySecurityScreen()),
    );
  }

  // Dialog methods
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6a11cb),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.language_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Language',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
        content: Text(
          '\nLanguage selection will be available in future updates.',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'DMSerif',
            color: Colors.grey[500]?.withOpacity(0.6),
            decoration: TextDecoration.underline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: const Color(0xFF948979),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFf093fb),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
        content: const Text(
          '\nFor support, please contact us at:\n📧 support@bullbearnews.com',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'DMSerif',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF948979).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'OK',
                  style: TextStyle(
                      color: const Color.fromARGB(255, 196, 182, 161),
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4facfe),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'About BullBearNews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'BullBearNews is a modern platform designed for cryptocurrency enthusiasts. Stay informed with real-time news, track your portfolio with ease, and make smarter investment decisions using AI-driven insights.',
              style: TextStyle(
                height: 1.5,
                fontFamily: 'DMSerif',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Our Mission',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'DMSerif',
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Empowering investors through clarity, transparency, and up-to-the-minute information.',
              style: TextStyle(
                fontFamily: 'DMSerif',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Contact & Support',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DMSerif'),
            ),
            SizedBox(height: 4),
            Text('📧 support@bullbearnews.com'),
            SizedBox(height: 4),
            Text('🌐 www.bullbearnews.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF948979).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'CLOSE',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 196, 182, 161),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
