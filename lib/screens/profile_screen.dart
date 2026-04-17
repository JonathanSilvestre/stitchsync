import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/pet_service.dart';
import '../utils/pet_avatar_catalog.dart';
import '../utils/user_avatar_catalog.dart';
import 'account_settings_screen.dart';
import 'home_screen.dart';
import 'manage_family_screen.dart';
import 'notifications_screen.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FamilyService _familyService = FamilyService();
  final PetService _petService = PetService();

  String? _userName;
  String? _activeFamilyId;
  String? _activePetId;
  String _activePetName = 'Pet';
  String _activePetBreed = 'Breed not set';
  String _activePetAgeLabel = 'Age not set';
  String _activePetPhotoUrl = '';
  String _activePetAvatarId = '';
  String _profileAvatarId = kUserAvatarChoices.first.id;
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
      final profileUsername = (profile?['username'] as String?)?.trim();
      final fallbackUsername = currentUser?.email?.split('@').first;
      final activeFamilyId = (profile?['active_family_id'] as String?)?.trim();
      final activePetId = (profile?['active_pet_id'] as String?)?.trim();
      final profileAvatarId = (profile?['profile_avatar_id'] as String?)?.trim();

      if (!mounted) {
        return;
      }

      setState(() {
        _userName = (profileUsername != null && profileUsername.isNotEmpty)
            ? profileUsername
            : (fallbackUsername != null && fallbackUsername.isNotEmpty)
                ? fallbackUsername
                : 'Usuario';
        _activeFamilyId = (activeFamilyId != null && activeFamilyId.isNotEmpty)
            ? activeFamilyId
            : null;
        _activePetId = (activePetId != null && activePetId.isNotEmpty) ? activePetId : null;
        _profileAvatarId = resolveUserAvatar(profileAvatarId).id;
      });

      await _loadActivePetContext();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userName = 'Usuario';
          _activePetName = 'Pet';
          _activePetBreed = 'Breed not set';
          _activePetAgeLabel = 'Age not set';
          _activePetPhotoUrl = '';
          _activePetAvatarId = '';
          _profileAvatarId = kUserAvatarChoices.first.id;
          _isLoading = false;
        });
      }
    }
  }

  String _formatPetAgeLabel(dynamic ageValue) {
    if (ageValue is num) {
      final age = ageValue.toInt();
      if (age == 1) {
        return '1 year';
      }
      if (age > 1) {
        return '$age years';
      }
    }

    return 'Age not set';
  }

  Future<void> _loadActivePetContext() async {
    var familyId = _activeFamilyId;
    if (familyId == null || familyId.isEmpty) {
      final families = await _familyService.streamFamiliesForCurrentUser().first;
      if (families.isNotEmpty) {
        familyId = families.first.id;
      }
    }

    if (familyId == null || familyId.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeFamilyId = null;
        _activePetId = null;
        _activePetName = 'Pet';
        _activePetBreed = 'No family assigned';
        _activePetAgeLabel = 'Age not set';
        _activePetPhotoUrl = '';
        _activePetAvatarId = '';
      });
      return;
    }

    final pets = await _petService.streamPets(familyId).first;
    if (pets.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeFamilyId = familyId;
        _activePetId = null;
        _activePetName = 'No pet yet';
        _activePetBreed = 'No pets in this family';
        _activePetAgeLabel = 'Add a pet';
        _activePetPhotoUrl = '';
        _activePetAvatarId = '';
      });
      return;
    }

    late QueryDocumentSnapshot<Map<String, dynamic>> selectedPet;
    try {
      selectedPet = pets.firstWhere((pet) => pet.id == _activePetId);
    } catch (_) {
      selectedPet = pets.first;
    }

    final petData = selectedPet.data();
    final petName = (petData['name'] as String?)?.trim();
    final petBreed = (petData['breed'] as String?)?.trim();
    final photoUrl = (petData['photo_url'] as String?)?.trim();
    final avatarId = (petData['avatar_id'] as String?)?.trim();

    if (!mounted) {
      return;
    }

    setState(() {
      _activeFamilyId = familyId;
      _activePetId = selectedPet.id;
      _activePetName = (petName != null && petName.isNotEmpty) ? petName : 'Pet';
      _activePetBreed = (petBreed != null && petBreed.isNotEmpty) ? petBreed : 'Breed not set';
      _activePetAgeLabel = _formatPetAgeLabel(petData['age']);
      _activePetPhotoUrl = (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : '';
      _activePetAvatarId = (avatarId != null && avatarId.isNotEmpty)
          ? avatarId
          : kPetAvatarChoices.first.id;
    });
  }

  Future<void> _applyPetSelection(QueryDocumentSnapshot<Map<String, dynamic>> petDoc) async {
    final familyId = _activeFamilyId;
    if (familyId == null || familyId.isEmpty) {
      return;
    }

    final petData = petDoc.data();
    final petName = (petData['name'] as String?)?.trim();
    final petBreed = (petData['breed'] as String?)?.trim();
    final photoUrl = (petData['photo_url'] as String?)?.trim();
    final avatarId = (petData['avatar_id'] as String?)?.trim();

    if (!mounted) {
      return;
    }

    setState(() {
      _activePetId = petDoc.id;
      _activePetName = (petName != null && petName.isNotEmpty) ? petName : 'Pet';
      _activePetBreed = (petBreed != null && petBreed.isNotEmpty) ? petBreed : 'Breed not set';
      _activePetAgeLabel = _formatPetAgeLabel(petData['age']);
      _activePetPhotoUrl = (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : '';
      _activePetAvatarId = (avatarId != null && avatarId.isNotEmpty)
          ? avatarId
          : kPetAvatarChoices.first.id;
    });

    try {
      await _authService.saveActivePetSelection(
        familyId: familyId,
        petId: petDoc.id,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save active pet.')),
      );
    }
  }

  Future<void> _openPetSwitcher() async {
    final familyId = _activeFamilyId;
    if (familyId == null || familyId.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero crea o selecciona una familia.')),
      );
      return;
    }

    final pets = await _petService.streamPets(familyId).first;
    if (pets.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay mascotas disponibles todavía.')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final selectedPetId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: _surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Change Pet',
                        style: TextStyle(
                          color: _textMain,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close, color: _textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Pick the pet to sync from your profile.',
                  style: TextStyle(color: _textMuted),
                ),
                const SizedBox(height: 14),
                ...pets.map((petDoc) {
                  final petData = petDoc.data();
                  final name = ((petData['name'] as String?) ?? 'Pet').trim();
                  final breed = ((petData['breed'] as String?) ?? 'Unknown').trim();
                  final photoUrl = ((petData['photo_url'] as String?) ?? '').trim();
                  final avatarId = ((petData['avatar_id'] as String?) ?? '').trim();
                  final isSelected = petDoc.id == _activePetId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => Navigator.pop(sheetContext, petDoc.id),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? _surfaceContainerHighest : _background,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: buildPetAvatarVisual(
                                photoUrl: photoUrl,
                                avatarId: avatarId,
                                size: 52,
                                borderRadius: BorderRadius.circular(14),
                                iconSize: 24,
                                placeholderBackground: _surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: _textMain,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    breed,
                                    style: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: _primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedPetId == null) {
      return;
    }

    late QueryDocumentSnapshot<Map<String, dynamic>> selectedPet;
    try {
      selectedPet = pets.firstWhere((pet) => pet.id == selectedPetId);
    } catch (_) {
      selectedPet = pets.first;
    }

    await _applyPetSelection(selectedPet);
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
    return FutureBuilder<({String roleName, String roleLabel})>(
      future: _getCurrentUserRole(),
      builder: (context, roleSnapshot) {
        final roleName = roleSnapshot.data?.roleName ?? 'Member';
        final roleLabel = roleSnapshot.data?.roleLabel ?? 'Member';
        
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
                child: Center(
                  child: buildUserAvatarVisual(
                    avatarId: _profileAvatarId,
                    size: 72,
                    borderRadius: BorderRadius.circular(14),
                    emojiSize: 28,
                  ),
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
                      roleName,
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
                        roleLabel,
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
      },
    );
  }
  
  Future<({String roleName, String roleLabel})> _getCurrentUserRole() async {
    try {
      final families = await _familyService.streamFamiliesForCurrentUser().first;
      if (families.isEmpty) {
        return (roleName: 'Sin familia', roleLabel: 'NO FAMILY');
      }

      late QueryDocumentSnapshot<Map<String, dynamic>> selectedFamily;
      try {
        selectedFamily = families.firstWhere((family) => family.id == _activeFamilyId);
      } catch (_) {
        selectedFamily = families.first;
      }

      final familyData = selectedFamily.data();
      final currentUid = _authService.currentUser?.uid ?? '';
      final ownerUid = (familyData['owner_uid'] as String?) ?? '';
      final adminUids = (familyData['admin_uids'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toSet();

      if (currentUid == ownerUid) {
        return (roleName: 'Family Owner', roleLabel: 'OWNER');
      } else if (adminUids.contains(currentUid)) {
        return (roleName: 'Family Administrator', roleLabel: 'ADMIN');
      } else {
        return (roleName: 'Family Member', roleLabel: 'MEMBER');
      }
    } catch (_) {
      return (roleName: 'Family Member', roleLabel: 'MEMBER');
    }
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openPetSwitcher,
            child: Container(
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
                    child: buildPetAvatarVisual(
                      photoUrl: _activePetPhotoUrl,
                      avatarId: _activePetAvatarId,
                      size: 56,
                      borderRadius: BorderRadius.circular(12),
                      iconSize: 30,
                      placeholderBackground: _primary.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activePetName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_activePetBreed • $_activePetAgeLabel',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openPetSwitcher,
                    icon: const Icon(
                      Icons.chevron_right,
                      color: _textMuted,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilySection() {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _familyService.streamFamiliesForCurrentUser(),
      builder: (context, familySnapshot) {
        if (familySnapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'FAMILY MEMBERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                      letterSpacing: 0.05,
                    ),
                  ),
                  Text(
                    '0 active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
          );
        }

        final families = familySnapshot.data ?? const [];

        if (families.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'FAMILY MEMBERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                      letterSpacing: 0.05,
                    ),
                  ),
                  Text(
                    '0 active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No family members yet.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        }

        late QueryDocumentSnapshot<Map<String, dynamic>> selectedFamily;
        try {
          selectedFamily = families.firstWhere((family) => family.id == _activeFamilyId);
        } catch (_) {
          selectedFamily = families.first;
        }

        final familyData = selectedFamily.data();
        final memberUids = (familyData['member_uids'] as List<dynamic>? ?? const [])
            .map((memberUid) => memberUid.toString().trim())
            .where((memberUid) => memberUid.isNotEmpty)
            .toList(growable: false);

        if (memberUids.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'FAMILY MEMBERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                      letterSpacing: 0.05,
                    ),
                  ),
                  Text(
                    '0 active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No family members yet.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        }

        final queryUids = memberUids.take(10).toList(growable: false);

        return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: queryUids)
              .snapshots()
              .map((snapshot) {
            final docs = snapshot.docs.toList(growable: false);
            docs.sort((left, right) {
              final leftIndex = memberUids.indexOf(left.id);
              final rightIndex = memberUids.indexOf(right.id);
              return leftIndex.compareTo(rightIndex);
            });
            return docs;
          }),
          builder: (context, membersSnapshot) {
            final members = membersSnapshot.data ?? const [];
            final activeCount = members.where((member) => _isMemberActiveNow(member)).length;
            final visibleMembers = members.take(3).toList(growable: false);
            final hiddenCount = members.length - visibleMembers.length;

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
                    Text(
                      '$activeCount active',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'No family members yet.',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 48,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var index = 0; index < visibleMembers.length; index++)
                          Positioned(
                            left: index * 36,
                            child: _buildAvatarBubbleFromMember(
                              memberDoc: visibleMembers[index],
                              index: index,
                            ),
                          ),
                        if (hiddenCount > 0)
                          Positioned(
                            left: visibleMembers.length * 36,
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
                              child: Center(
                                child: Text(
                                  '+$hiddenCount',
                                  style: const TextStyle(
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
                  ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isMemberActiveNow(QueryDocumentSnapshot<Map<String, dynamic>> memberDoc) {
    final memberData = memberDoc.data();
    final currentUid = _authService.currentUser?.uid;
    final memberUid = ((memberData['uid'] as String?)?.trim().isNotEmpty == true)
        ? (memberData['uid'] as String).trim()
        : memberDoc.id;
    if (currentUid != null && memberUid == currentUid) {
      return true;
    }

    if (memberData['is_online'] != true) {
      return false;
    }

    final lastSeenAt = memberData['last_seen_at'];
    if (lastSeenAt is! Timestamp) {
      return false;
    }

    final lastSeen = lastSeenAt.toDate();
    return DateTime.now().difference(lastSeen) <= const Duration(minutes: 2);
  }

  Widget _buildAvatarBubbleFromMember({
    required QueryDocumentSnapshot<Map<String, dynamic>> memberDoc,
    required int index,
  }) {
    final memberData = memberDoc.data();
    final profileAvatarId = (memberData['profile_avatar_id'] as String?)?.trim();
    final resolvedAvatarId = resolveUserAvatar(profileAvatarId).id;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _surfaceContainer,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: buildUserAvatarVisual(
          avatarId: resolvedAvatarId,
          size: 48,
          borderRadius: BorderRadius.circular(24),
          emojiSize: 18,
        ),
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
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ManageFamilyScreen(),
              ),
            );

            await _loadActivePetContext();
          },
        ),
        const SizedBox(height: 12),
        _buildPreferenceItem(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Manage push and email alerts',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildPreferenceItem(
          icon: Icons.settings,
          title: 'Account Settings',
          subtitle: 'Email, password and security',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AccountSettingsScreen(),
              ),
            );
            await _loadUserData();
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
