import 'package:flutter/material.dart';

import '../l10n/app_i18n.dart';
import '../viewmodels/screens/manage_account_view_model.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  final ManageAccountViewModel _viewModel = ManageAccountViewModel();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isLoadingProfile = true;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _selectedLanguage = 'es';

  void _onViewModelChanged() {
    if (!mounted) {
      return;
    }
    final message = _viewModel.uiMessage;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(message))),
      );
      _viewModel.clearUiMessage();
    }
    setState(() {
      _isLoadingProfile = _isLoadingProfile && _viewModel.isLoading;
    });
  }

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _loadProfile();
    _loadLanguage();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _viewModel.loadProfileWithState();

    if (!mounted) {
      return;
    }

    _usernameController.text =
      (profile?['username'] as String?) ??
        (_viewModel.authService.currentUser?.displayName ?? '');

    setState(() {
      _isLoadingProfile = false;
    });
  }

  Future<void> _loadLanguage() async {
    final language = await _viewModel.loadLanguageWithState(fallback: 'es');
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<void> _saveLanguage(String language) async {
    final ok = await _viewModel.saveLanguageWithState(
      language: language,
      errorMessage: 'Could not save language preference.',
    );
    if (ok && mounted) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  Future<void> _saveAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final ok = await _viewModel.saveAccountWithState(
        newUsername: _usernameController.text.trim(),
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text.trim().isEmpty
            ? null
            : _newPasswordController.text.trim(),
      );

    if (!mounted) {
      return;
    }

    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    }
  }

  Future<void> _logout() async {
    await _viewModel.authService.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Manage account')),
        backgroundColor: const Color(0xFF143A5A),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr('Update your access details'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17324D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _usernameController,
                        label: context.tr('New username'),
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('Enter your username');
                          }
                          if (value.trim().length < 3) {
                            return context.tr('It must have at least 3 characters');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _currentPasswordController,
                        label: context.tr('Current password'),
                        icon: Icons.lock_outline,
                        obscureText: _obscureCurrent,
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureCurrent = !_obscureCurrent;
                            });
                          },
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('You must enter your current password');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _newPasswordController,
                        label: context.tr('New password (optional)'),
                        icon: Icons.password_outlined,
                        obscureText: _obscureNew,
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureNew = !_obscureNew;
                            });
                          },
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 6) {
                            return context.tr('Minimum 6 characters');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _confirmNewPasswordController,
                        label: context.tr('Confirm new password'),
                        icon: Icons.lock_reset,
                        obscureText: _obscureConfirm,
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (_newPasswordController.text.isNotEmpty &&
                              value != _newPasswordController.text) {
                            return context.tr('Passwords do not match');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _viewModel.isLoading ? null : _saveAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D6A7B),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _viewModel.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(context.tr('Save Changes')),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: Text(context.tr('Log out')),
                      ),
                      const SizedBox(height: 24),
                      _buildLanguageSection(),
                    ],
                  ),
                ),
              ),
            ),
      backgroundColor: const Color(0xFFF4F7FB),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF4F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDDE4ED),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.language,
                color: Color(0xFF1D6A7B),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('Language'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF17324D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFDDE4ED),
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _saveLanguage(newValue);
                }
              },
              isExpanded: true,
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: [
                DropdownMenuItem(
                  value: 'es',
                  child: Text(context.tr('Español')),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(context.tr('English')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}