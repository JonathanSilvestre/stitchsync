import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_i18n.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import 'add_new_pet_screen.dart';

class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final FamilyService _familyService = FamilyService();
  final AuthService _authService = AuthService();
  final TextEditingController _familyNameController = TextEditingController();

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);

  bool _isSaving = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    final familyName = _familyNameController.text.trim();
    if (familyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter a family name.'))),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final familyId = await _familyService.createFamily(familyName);

      if (!mounted) {
        return;
      }

      // Set the new family as active and clear previous pet selection
      await _authService.saveActivePetSelection(
        familyId: familyId,
        petId: '', // Clear the pet ID to show "No pets yet"
      );

      if (!mounted) {
        return;
      }

      final addPetNow = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: _surfaceHigh,
            title: Text(
              context.tr('Family created'),
              style: const TextStyle(color: _textMain, fontWeight: FontWeight.w700),
            ),
            content: Text(
              context.tr('Do you want to add a pet now?'),
              style: const TextStyle(color: _textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(context.tr('No')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: const Color(0xFF0A2550),
                ),
                child: Text(context.tr('Yes')),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      if (addPetNow == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AddNewPetScreen(familyId: familyId),
          ),
        );
        return;
      }

      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_familyService.getReadableError(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
            child: Column(
              children: [
                Container(
                  height: 84,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFF0A1730),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: _primary, size: 30),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          context.tr('Create Family'),
                          style: const TextStyle(
                            color: Color(0xFF9DC7FF),
                            fontSize: 32,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _surfaceHigh,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Icon(Icons.pets_rounded, color: _primary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Start Your Family Circle'),
                          style: const TextStyle(
                            color: _textMain,
                            fontSize: 40,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.tr('Create a group to share Stitch\'s care schedule with everyone.'),
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 18,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 12, 30, 0.40),
                                blurRadius: 40,
                                offset: Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                context.tr('FAMILY NAME'),
                                style: const TextStyle(
                                  color: Color(0xFFAFBED9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: _surfaceHigh,
                                  borderRadius: BorderRadius.circular(44),
                                ),
                                child: TextField(
                                  controller: _familyNameController,
                                  style: const TextStyle(color: _textMain, fontSize: 18),
                                  decoration: InputDecoration(
                                    hintText: context.tr('e.g., The Rodriguez Family'),
                                    hintStyle: TextStyle(color: Color(0xFF60708E), fontSize: 18),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                context.tr('This is the name your family members will see when they join.'),
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: _surfaceHigh.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info, color: _primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        context.tr('Your family circle is encrypted and private to invited members only.'),
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF74B1FF), Color(0xFF5FA3F6)],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(95, 163, 246, 0.30),
                                      blurRadius: 24,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _createFamily,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.transparent,
                                    disabledForegroundColor: Colors.white70,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(64),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                          : Text(context.tr('Create Family')),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
