import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'account_settings_screen.dart';
import 'home_screen.dart';
import 'manage_family_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onGoHome;

  const ProfileScreen({super.key, this.onGoHome});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Design tokens from Luminous Midnight
  static const Color _background = Color(0xFF060E20);
  static const Color _surfaceContainer = Color(0xFF0F1930);
  static const Color _surfaceContainerHighest = Color(0xFF192540);
  static const Color _primary = Color(0xFF74B1FF);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _errorRed = Color(0xFFD32F2F);
  static const Color _surfaceBright = Color(0xFF384A62);

  late AuthService _authService;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      final currentUser = _authService.currentUser;
      
      setState(() {
        _userName = profile?['username'] ?? currentUser?.email?.split('@')[0] ?? 'Usuario';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Usuario';
          _isLoading = false;
        });
      }
    }
  }

  void _handleLogout() {
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: _surfaceContainer,
        title: const Text(
          'Log Out',
          style: TextStyle(color: _textMain, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              nav.pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: _errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _goHome() {
    if (widget.onGoHome != null) {
      widget.onGoHome!();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(initialTab: 0),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: _isLoading
          ? _buildLoadingState()
          : Stack(
              children: [
                // Background gradient with glow
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _background,
                          Color.lerp(_background, Color(0xFF192540), 0.3) ?? _background,
                        ],
                      ),
                    ),
                  ),
                ),
                // Ambient glow circle (top right)
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _primary.withValues(alpha: 0.15),
                          _primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 32),
                        _buildProfileHeader(),
                        const SizedBox(height: 32),
                        _buildSyncingSection(),
                        const SizedBox(height: 32),
                        _buildFamilySection(),
                        const SizedBox(height: 32),
                        _buildPreferencesSection(),
                        const SizedBox(height: 24),
                        _buildLogoutButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(_primary),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _textMain,
            letterSpacing: -0.02,
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _goHome,
            icon: const Icon(
              Icons.home_rounded,
              color: _primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _surfaceBright.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: _primary,
            ),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName ?? 'User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Family Administrator',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ADMIN',
                    style: TextStyle(
                      fontSize: 12,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SYNCING WITH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textMuted,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pets,
                  color: _primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stitch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Poodle Mix • 2y',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: _textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFamilySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FAMILY MEMBERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textMuted,
                letterSpacing: 0.05,
              ),
            ),
            const Text(
              '4 active',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Avatar placeholders
            _buildAvatarBubble(0),
            Transform.translate(
              offset: const Offset(-12, 0),
              child: _buildAvatarBubble(1),
            ),
            Transform.translate(
              offset: const Offset(-24, 0),
              child: _buildAvatarBubble(2),
            ),
            Transform.translate(
              offset: const Offset(-36, 0),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _surfaceContainer,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '+1',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarBubble(int index) {
    final colors = [_primary, Color(0xFF6D9CFE), Color(0xFFE8AAFF)];
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors[index % colors.length].withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _surfaceContainer,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.person,
        size: 24,
        color: colors[index % colors.length],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PREFERENCES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textMuted,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 12),
        _buildPreferenceItem(
          icon: Icons.people,
          title: 'Manage Family & Pets',
          subtitle: 'Add or remove members and pets',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ManageFamilyScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildPreferenceItem(
          icon: Icons.notifications,
          title: 'Feeding Reminders',
          subtitle: 'Manage schedules and notifications',
        ),
        const SizedBox(height: 12),
        _buildPreferenceItem(
          icon: Icons.settings,
          title: 'Account Settings',
          subtitle: 'Email, password and security',
                 onTap: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(
                       builder: (_) => const AccountSettingsScreen(),
                     ),
                   );
                 },
        ),
      ],
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
                          color: _primary,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: _textMuted,
            size: 24,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _errorRed.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
          color: _errorRed.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout,
              color: _errorRed,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text(
              'Log Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _errorRed,
                letterSpacing: 0.02,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
