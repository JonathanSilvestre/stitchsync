import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_i18n.dart';
import '../services/auth_service.dart';
import '../utils/user_avatar_catalog.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _selectedLanguage = 'en';
  String _selectedAvatarId = kUserAvatarChoices.first.id;
  String _initialUsername = '';
  String _initialLanguage = 'en';
  String _initialAvatarId = kUserAvatarChoices.first.id;

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      final user = _authService.currentUser;

      if (mounted) {
        setState(() {
          _usernameController.text =
              profile?['username'] ?? user?.displayName ?? '';
          _emailController.text = user?.email ?? '';
          final language = (profile?['language'] as String?)?.toLowerCase();
          if (language == 'es' || language == 'en') {
            _selectedLanguage = language!;
          }
          final avatarId = (profile?['profile_avatar_id'] as String?)?.trim();
          if (avatarId != null && avatarId.isNotEmpty) {
            _selectedAvatarId = resolveUserAvatar(avatarId).id;
          }
          _initialUsername = _usernameController.text.trim();
          _initialLanguage = _selectedLanguage;
          _initialAvatarId = _selectedAvatarId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Error loading profile'))),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final username = _usernameController.text.trim();
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();
      final confirmNewPassword = _confirmNewPasswordController.text.trim();
        final usernameChanged = username != _initialUsername;
        final languageChanged = _selectedLanguage != _initialLanguage;
        final avatarChanged = _selectedAvatarId != _initialAvatarId;
      final wantsPasswordChange = newPassword.isNotEmpty;

      if (username.isEmpty) {
        throw Exception('Username cannot be empty');
      }

      if (newPassword.isNotEmpty && newPassword != confirmNewPassword) {
        throw Exception('New passwords do not match');
      }

      if (newPassword.isNotEmpty && currentPassword.isEmpty) {
        throw Exception('Current password is required to change password');
      }

      if (!usernameChanged && !wantsPasswordChange && !languageChanged && !avatarChanged) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('No changes to save.'))),
          );
        }
        return;
      }

      if (usernameChanged || wantsPasswordChange) {
        await _authService.updateAccount(
          newUsername: username,
          currentPassword: currentPassword.isEmpty ? null : currentPassword,
          newPassword: newPassword.isNotEmpty ? newPassword : null,
        );
      }

      if (languageChanged) {
        await _saveLanguagePreference(_selectedLanguage);
      }

      if (avatarChanged) {
        await _saveAvatarPreference(_selectedAvatarId);
      }

      _initialUsername = username;
      _initialLanguage = _selectedLanguage;
      _initialAvatarId = _selectedAvatarId;

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Changes saved successfully'))),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_authService.getReadableAuthError(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('Error')}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveLanguagePreference(String language) async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    await _firestore.collection('users').doc(user.uid).set(
      {'language': language},
      SetOptions(merge: true),
    );
  }

  Future<void> _saveAvatarPreference(String avatarId) async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    await _firestore.collection('users').doc(user.uid).set(
      {'profile_avatar_id': avatarId},
      SetOptions(merge: true),
    );
  }

  Future<void> _openAvatarPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose profile avatar',
                  style: TextStyle(
                    color: _textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pick one of your 8 profile avatars.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.42,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: kUserAvatarChoices.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final avatar = kUserAvatarChoices[index];
                      final isSelected = avatar.id == _selectedAvatarId;

                      return GestureDetector(
                          onTap: () {
                            final navigator = Navigator.of(sheetContext);
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _selectedAvatarId = avatar.id;
                          });
                            navigator.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? _primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: buildUserAvatarVisual(
                            avatarId: avatar.id,
                            size: 58,
                            borderRadius: BorderRadius.circular(13),
                            emojiSize: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A1730),
                    _bg,
                    const Color(0xFF050A17),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: const Color(0xFF0A1730),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back,
                                  color: _textMain, size: 24),
                            ),
                            Expanded(
                              child: Text(
                                context.tr('Settings'),
                                style: const TextStyle(
                                  color: _textMain,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert,
                                  color: _textMuted, size: 24),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 24, 16, 32),
                          child: Column(
                            children: [
                              _buildProfileSection(),
                              const SizedBox(height: 40),
                              _buildProfileInformationSection(),
                              const SizedBox(height: 40),
                              _buildSecuritySection(),
                              const SizedBox(height: 40),
                              _buildSaveButton(),
                              const SizedBox(height: 12),
                              _buildLastUpdated(),
                            ],
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

  Widget _buildProfileSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _primary,
              width: 3,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _surfaceHigh,
            ),
            child: Center(
              child: buildUserAvatarVisual(
                avatarId: _selectedAvatarId,
                size: 156,
                borderRadius: BorderRadius.circular(80),
                emojiSize: 64,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: InkWell(
            onTap: _openAvatarPicker,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary,
                border: Border.all(color: _bg, width: 3),
              ),
              child: const Icon(
                Icons.edit,
                color: _bg,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield,
                color: _primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.tr('Security'),
              style: const TextStyle(
                color: _textMain,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordField(
                label: context.tr('CURRENT PASSWORD'),
                controller: _currentPasswordController,
                hint: '••••••••••••',
                obscureText: _obscureCurrent,
                onToggleObscure: () {
                  setState(() {
                    _obscureCurrent = !_obscureCurrent;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                label: context.tr('NEW PASSWORD'),
                controller: _newPasswordController,
                hint: context.tr('Min. 8 characters'),
                obscureText: _obscureNew,
                onToggleObscure: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                label: context.tr('CONFIRM NEW PASSWORD'),
                controller: _confirmNewPasswordController,
                hint: context.tr('Repeat new password'),
                obscureText: _obscureConfirm,
                onToggleObscure: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            color: _textMain,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: _textMuted,
              fontSize: 14,
            ),
            filled: true,
            fillColor: _surfaceHigh,
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: _textMuted,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Account Settings'),
          style: const TextStyle(
            color: _textMain,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('Manage your personal information'),
          style: const TextStyle(
            color: _textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: _primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('Profile Information'),
                    style: const TextStyle(
                      color: _textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: context.tr('USERNAME'),
                controller: _usernameController,
                hint: 'Enter your username',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: context.tr('EMAIL ADDRESS'),
                controller: _emailController,
                hint: 'Email address',
                enabled: false,
              ),
              const SizedBox(height: 16),
              _buildLanguageDropdown(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('LANGUAGE'),
          style: const TextStyle(
            color: _textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _surfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: _surfaceHigh,
              isExpanded: true,
              iconEnabledColor: _textMuted,
              style: const TextStyle(
                color: _textMain,
                fontSize: 14,
              ),
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(context.tr('English')),
                ),
                DropdownMenuItem(
                  value: 'es',
                  child: Text(context.tr('Español')),
                ),
              ],
              onChanged: (value) {
                if (value == null || value == _selectedLanguage) {
                  return;
                }
                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(
            color: _textMain,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: _textMuted,
              fontSize: 14,
            ),
            filled: true,
            fillColor: _surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: _primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_bg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 20, color: _bg),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('Save Changes'),
                    style: const TextStyle(
                      color: _bg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Text(
      'Last updated on ${DateTime.now().toString().split(' ')[0]}',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _textMuted,
        fontSize: 12,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
