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
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: theme.colorScheme.onBackground,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        iconTheme: IconThemeData(
          color: theme.colorScheme.onBackground,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_sharp,
            color: theme.colorScheme.onBackground,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground.withOpacity(0.8),
              ),
              textAlign: TextAlign.start,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textScaleFactor: 1.2,
              textDirection: TextDirection.ltr,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: true,
                applyHeightToLastDescent: true,
              ),
              locale: const Locale('en', 'US'),
              semanticsLabel: 'Appearance Settings',
            ),
            const SizedBox(height: 16),
            _buildThemeToggleCard(themeProvider, isDarkMode, theme),
            const SizedBox(height: 32),
            Divider(
              color: theme.dividerColor.withOpacity(0.1),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 16),
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground.withOpacity(0.8),
              ),
              textAlign: TextAlign.start,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textScaleFactor: 1.2,
              textDirection: TextDirection.ltr,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: true,
                applyHeightToLastDescent: true,
              ),
              locale: const Locale('en', 'US'),
              semanticsLabel: 'Preferences Settings',
            ),
            const SizedBox(height: 16),
            _buildSettingOption(
              context: context,
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () {},
            ),
            _buildSettingOption(
              context: context,
              icon: Icons.security,
              title: 'Privacy',
              subtitle: 'Control your privacy settings',
              onTap: () {},
            ),
            _buildSettingOption(
              context: context,
              icon: Icons.language,
              title: 'Language',
              subtitle: 'Select your preferred language',
              onTap: () {},
            ),
            _buildSettingOption(
              context: context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help or send feedback',
              onTap: () {},
            ),
            _buildSettingOption(
              context: context,
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'Learn more about this app',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleCard(
    ThemeProvider themeProvider,
    bool isDarkMode,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Theme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isDarkMode ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
              activeColor: theme.colorScheme.primary,
              activeThumbImage: isDarkMode
                  ? const AssetImage('assets/icons/moon.png')
                  : const AssetImage('assets/icons/sun.png'),
              inactiveThumbImage: isDarkMode
                  ? const AssetImage('assets/icons/moon.png')
                  : const AssetImage('assets/icons/sun.png'),
              activeTrackColor: theme.colorScheme.primary.withOpacity(0.4),
              inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(0.6),
              inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
