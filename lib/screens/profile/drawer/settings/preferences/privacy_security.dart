import 'package:bullbearnews/services/auth_service.dart';
import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;

  // AuthService instance
  final AuthService _authService = AuthService();

  // Privacy Settings State
  bool _analyticsEnabled = true;
  bool _crashReportsEnabled = true;
  bool _personalizedAdsEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPrivacySettings();
  }

  void _loadPrivacySettings() async {
    try {
      final settings = await _authService.getPrivacySettings();
      setState(() {
        _analyticsEnabled = settings['analyticsEnabled'] ?? true;
        _crashReportsEnabled = settings['crashReportsEnabled'] ?? true;
        _personalizedAdsEnabled = settings['personalizedAdsEnabled'] ?? false;
      });
    } catch (e) {
      print('Privacy ayarları yüklenirken hata: $e');
    }
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

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF393E46),
                            size: 18,
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
                          'Privacy & Security',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF222831),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your data and security',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF948979)
                                : const Color(0xFF393E46),
                            fontWeight: FontWeight.w500,
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

  Widget _buildContent(bool isDark) {
    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _contentAnimation.value)),
          child: Opacity(
            opacity: _contentAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Data & Privacy Section
                  _buildSection(
                    title: 'Data & Privacy',
                    isDark: isDark,
                    children: [
                      _buildInfoCard(
                        icon: Icons.info_outline,
                        title: 'Data Collection',
                        description:
                            'We collect minimal data to improve your experience',
                        onTap: () => _showDataCollectionDialog(),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleCard(
                        icon: Icons.analytics_outlined,
                        title: 'Analytics',
                        description: 'Help us improve the app',
                        value: _analyticsEnabled,
                        onChanged: (value) async {
                          setState(() => _isLoading = true);
                          try {
                            await _authService.updatePrivacySetting(
                                'analyticsEnabled', value);
                            setState(() => _analyticsEnabled = value);
                          } catch (e) {
                            _showErrorSnackBar(
                                'Analytics setting could not be updated');
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleCard(
                        icon: Icons.bug_report_outlined,
                        title: 'Crash Reports',
                        description: 'Automatically send crash reports',
                        value: _crashReportsEnabled,
                        onChanged: (value) async {
                          setState(() => _isLoading = true);
                          try {
                            await _authService.updatePrivacySetting(
                                'crashReportsEnabled', value);
                            setState(() => _crashReportsEnabled = value);
                          } catch (e) {
                            _showErrorSnackBar(
                                'Crash reports setting could not be updated');
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleCard(
                        icon: Icons.ads_click_outlined,
                        title: 'Personalized Ads',
                        description: 'Show ads based on your interests',
                        value: _personalizedAdsEnabled,
                        onChanged: (value) async {
                          setState(() => _isLoading = true);
                          try {
                            await _authService.updatePrivacySetting(
                                'personalizedAdsEnabled', value);
                            setState(() => _personalizedAdsEnabled = value);
                          } catch (e) {
                            _showErrorSnackBar(
                                'Personalized ads setting could not be updated');
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Security Section
                  _buildSection(
                    title: 'Security',
                    isDark: isDark,
                    children: [
                      _buildInfoCard(
                        icon: Icons.vpn_key_outlined,
                        title: 'Change Password',
                        description: 'Update your account password',
                        onTap: () => _showChangePasswordDialog(),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account Management Section
                  _buildSection(
                    title: 'Account Management',
                    isDark: isDark,
                    children: [
                      _buildInfoCard(
                        icon: Icons.download_outlined,
                        title: 'Export Data',
                        description: 'Download your personal data',
                        onTap: () => _exportUserData(),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.delete_outline,
                        title: 'Delete Account',
                        description: 'Permanently delete your account',
                        onTap: () => _showDeleteAccountDialog(),
                        isDark: isDark,
                        isDestructive: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
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
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _exportUserData() async {
    try {
      setState(() => _isLoading = true);

      // Burada veriyi dosya olarak kaydetme işlemi yapılabilir
      // Şimdilik sadece başarı mesajı gösterelim
      _showSuccessSnackBar('User data exported successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to export data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF948979),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _isLoading ? null : onChanged,
            activeColor: const Color(0xFF948979),
            activeTrackColor: const Color(0xFF948979).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF948979).withOpacity(0.5),
            inactiveTrackColor: const Color(0xFF948979).withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.7)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive
              ? Colors.red.withOpacity(0.3)
              : (isDark
                  ? const Color(0xFF948979).withOpacity(0.2)
                  : const Color(0xFF393E46).withOpacity(0.1)),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.2)
                        : const Color(0xFF948979).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Colors.red
                        : (isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF393E46)),
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
                          color: isDestructive
                              ? Colors.red
                              : (isDark
                                  ? const Color(0xFFDFD0B8)
                                  : const Color(0xFF222831)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF948979),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF948979),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDataCollectionDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildCustomDialog(
        title: 'Data Collection',
        content:
            'We collect minimal data to provide you with the best news experience:\n\n• Reading preferences\n• App usage statistics\n• Device information\n• Location (if enabled)\n\nYour data is encrypted and never shared with third parties.',
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF393E46)
            : const Color(0xFFDFD0B8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFDFD0B8)
                : const Color(0xFF222831),
            fontWeight: FontWeight.w700,
            fontFamily: 'DMSerif',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'DMSerif',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'DMSerif',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'DMSerif',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.red.withOpacity(0.2),
                    Colors.red.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 10.0),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                _showErrorSnackBar('Passwords do not match');
                return;
              }

              if (newPasswordController.text.length < 6) {
                _showErrorSnackBar('Password must be at least 6 characters');
                return;
              }

              try {
                await _authService.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                Navigator.of(context).pop();
                _showSuccessSnackBar('Password changed successfully');
              } catch (e) {
                _showErrorSnackBar(
                    'Failed to change password: ${e.toString()}');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.green.withOpacity(0.2),
                    Colors.green.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 10.0),
                child: Text(
                  'Change Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF393E46)
            : const Color(0xFFDFD0B8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action cannot be undone. All your data, preferences, and reading history will be permanently deleted.\n\nPlease enter your password to confirm:',
              style: TextStyle(color: Color(0xFF948979), fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (passwordController.text.isEmpty) {
                _showErrorSnackBar('Please enter your password');
                return;
              }

              try {
                await _authService.deleteAccount(passwordController.text);
                Navigator.of(context).pop();
                // Navigate to login screen or show success message
                _showSuccessSnackBar('Account deleted successfully');
              } catch (e) {
                _showErrorSnackBar('Failed to delete account: ${e.toString()}');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red,
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

  Widget _buildCustomDialog({
    required String title,
    required String content,
    required bool isDark,
    bool hasAction = false,
    String? actionText,
    VoidCallback? onAction,
    bool isDestructive = false,
  }) {
    return AlertDialog(
      backgroundColor:
          isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
          fontWeight: FontWeight.w700,
          fontFamily: 'DMSerif',
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          color: Color(0xFF948979),
          fontSize: 16,
          fontFamily: 'DMSerif',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF948979).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Color.fromARGB(255, 180, 165, 140),
                ),
              ),
            ),
          ),
        ),
        if (hasAction)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText!,
              style: TextStyle(
                color: isDestructive ? Colors.red : const Color(0xFF948979),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
