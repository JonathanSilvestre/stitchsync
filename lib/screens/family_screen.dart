import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_i18n.dart';
import 'create_family_screen.dart';
import '../utils/user_avatar_catalog.dart';
import '../viewmodels/screens/family_view_model.dart';

class FamilyTabContent extends StatefulWidget {
  const FamilyTabContent({super.key});

  @override
  State<FamilyTabContent> createState() => _FamilyTabContentState();
}

class _FamilyTabContentState extends State<FamilyTabContent> {
  final FamilyViewModel _viewModel = FamilyViewModel();
  FirebaseFirestore get _firestore => _viewModel.firestore;
  FirebaseAuth get _auth => _viewModel.auth;

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);

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

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _syncMembershipIndex();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _syncMembershipIndex() async {
    try {
      await _viewModel.syncMembershipIndex();
    } catch (_) {
      // Best-effort sync; UI can continue with existing data.
    }
  }

  Future<void> _openCreateFamilyScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateFamilyScreen(),
      ),
    );

    await _syncMembershipIndex();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showJoinByCodeDialog() async {
    String codeValue = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceHigh,
          title: Text(
            context.tr('Unirme con código'),
            style: const TextStyle(color: _textMain),
          ),
          content: TextFormField(
            onChanged: (value) => codeValue = value,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: _textMain),
            decoration: InputDecoration(
              labelText: context.tr('Invitation code'),
              hintText: context.tr('e.g. STITCH-ABC'),
              labelStyle: const TextStyle(color: _textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = codeValue.trim();
                if (code.isEmpty) {
                  return;
                }

                final joined = await _viewModel.joinFamilyByInviteCodeWithFeedback(
                  code: code,
                  successMessage: 'Te uniste a la familia correctamente.',
                  fallbackErrorMessage: 'Could not join family.',
                );
                if (!joined) {
                  return;
                }
                await _syncMembershipIndex();

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();

                if (!mounted) {
                  return;
                }

                setState(() {});
              },
              child: Text(context.tr('Unirme')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMemberActions({
    required String familyId,
    required _MemberData member,
    required bool canManage,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || member.uid == currentUid || !canManage || member.isOwner) {
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, 'make_admin'),
                    icon: const Icon(Icons.shield_outlined, color: _primary),
                    label: Text(
                      context.tr('Assign as administrator'),
                      style: const TextStyle(
                        color: _textMain,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, 'remove_member'),
                    icon: const Icon(Icons.person_remove_outlined, color: Color(0xFFFF9A9A)),
                    label: Text(
                      context.tr('Remove from family'),
                      style: const TextStyle(
                        color: Color(0xFFFFB0B0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'make_admin') {
      final ok = await _viewModel.promoteMemberToAdminWithFeedback(
        familyId: familyId,
        memberUid: member.uid,
        successMessage: 'Miembro promovido a administrador.',
      );
      if (ok && mounted) {
        setState(() {});
      }
      return;
    }

    if (action != 'remove_member') {
      return;
    }

    final ok = await _viewModel.removeMemberFromFamilyWithFeedback(
      familyId: familyId,
      memberUid: member.uid,
      successMessage: 'Miembro eliminado de la familia.',
    );
    if (ok && mounted) {
      setState(() {});
    }
  }

  Future<void> _leaveCurrentFamily({
    required String familyId,
    required bool isCurrentUserAdmin,
    required bool hasAnotherAdmin,
  }) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surfaceHigh,
        title: Text(context.tr('Salir de la familia'), style: const TextStyle(color: _textMain)),
        content: Text(
          isCurrentUserAdmin && !hasAnotherAdmin
              ? context.tr('You are the only administrator. Assign another administrator before leaving.')
              : context.tr('Are you sure you want to leave this family?'),
          style: const TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Leave')),
          ),
        ],
      ),
    );

    if (shouldLeave != true) return;

    if (isCurrentUserAdmin && !hasAnotherAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Debes asignar otro administrador antes de salir.'))),
      );
      return;
    }

    final ok = await _viewModel.leaveFamilyWithFeedback(
      familyId: familyId,
      successMessage: 'Saliste de la familia.',
    );
    if (!ok) {
      return;
    }
    await _syncMembershipIndex();
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<_MemberData>> _loadMembers(
    List<dynamic> memberUids,
    String ownerUid,
    List<dynamic> adminUids,
  ) async {
    final adminSet = adminUids.map((e) => e.toString()).toSet();

    final docs = await _viewModel.loadMemberProfiles(memberUids);

    return docs.map((doc) {
      final data = doc['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final username = (data['username'] as String?)?.trim();
      final avatarId = (data['profile_avatar_id'] as String?)?.trim();
      final uid = (doc['uid'] as String?) ?? '';
      final isOwner = uid == ownerUid;
      final isAdmin = isOwner || adminSet.contains(uid);
      return _MemberData(
        uid: uid,
        name: (username != null && username.isNotEmpty) ? username : context.tr('Member'),
        subtitle: isOwner
          ? context.tr('Owner')
            : isAdmin
            ? context.tr('Admin')
            : context.tr('Member'),
        isOwner: isOwner,
        isAdmin: isAdmin,
        avatarId: resolveUserAvatar(avatarId).id,
      );
    }).toList();
  }

  String _buildInviteCode(String familyName, String familyId) {
    final prefix = familyName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final shortPrefix = prefix.isEmpty ? 'STITCH' : prefix;
    final left = shortPrefix.substring(0, shortPrefix.length.clamp(0, 6));
    final right = familyId.substring(0, 3).toUpperCase();
    return '$left-$right';
  }

  bool _isFeedingEvent(Map<String, dynamic> data) {
    final title = ((data['title'] as String?) ?? '').toLowerCase();
    final category = ((data['category'] as String?) ?? '').toLowerCase();
    final lookup = '$title $category';

    return lookup.contains('feed') ||
        lookup.contains('food') ||
        lookup.contains('meal') ||
        lookup.contains('comida') ||
        lookup.contains('aliment');
  }

  String _formatShortTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    final paddedMinute = minute.toString().padLeft(2, '0');
    return '$normalizedHour:$paddedMinute $suffix';
  }

  Widget _buildPetHealthPulse({
    required String familyId,
  }) {
    final currentUid = _auth.currentUser?.uid;

    if (currentUid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(currentUid).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? const <String, dynamic>{};
        final activeFamilyId = ((userData['active_family_id'] as String?) ?? '').trim();
        final activePetId = ((userData['active_pet_id'] as String?) ?? '').trim();
        final selectedPetId = activeFamilyId == familyId ? activePetId : '';

        return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _firestore
              .collection('families')
              .doc(familyId)
              .collection('pets')
              .orderBy('created_at', descending: true)
              .snapshots()
              .map((snapshot) => snapshot.docs),
          builder: (context, petsSnapshot) {
            final pets = petsSnapshot.data ?? const [];

            String petName = context.tr('your pet');
            String petIdForLookup = selectedPetId;

            if (pets.isNotEmpty) {
              QueryDocumentSnapshot<Map<String, dynamic>> petDoc = pets.first;
              if (selectedPetId.isNotEmpty) {
                try {
                  petDoc = pets.firstWhere((doc) => doc.id == selectedPetId);
                } catch (_) {
                  petDoc = pets.first;
                }
              }

              final petData = petDoc.data();
              final resolvedName = (petData['name'] as String?)?.trim();
                petName = (resolvedName != null && resolvedName.isNotEmpty)
                  ? resolvedName
                  : context.tr('your pet');
              petIdForLookup = petDoc.id;
            }

            if (petIdForLookup.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F3A35),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: Color(0xFF7FC8A8)),
                        SizedBox(width: 8),
                        Text(
                          'PET HEALTH PULSE',
                          style: TextStyle(
                            color: Color(0xFF9FD6BD),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('No active pet to show feeding history.'),
                      style: const TextStyle(
                        color: Color(0xFFC9E9D9),
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _viewModel.streamTodayEvents(
                familyId: familyId,
                petId: petIdForLookup,
              ),
              builder: (context, eventsSnapshot) {
                final events = eventsSnapshot.data ?? const [];

                QueryDocumentSnapshot<Map<String, dynamic>>? latestFeedingCompleted;
                DateTime? latestCompletedAt;

                for (final eventDoc in events) {
                  final data = eventDoc.data();
                  if (data['completed'] != true || !_isFeedingEvent(data)) {
                    continue;
                  }

                  final completedAt = data['completed_at'];
                  if (completedAt is! Timestamp) {
                    continue;
                  }

                  final completedDate = completedAt.toDate();
                  if (latestCompletedAt == null || completedDate.isAfter(latestCompletedAt)) {
                    latestCompletedAt = completedDate;
                    latestFeedingCompleted = eventDoc;
                  }
                }

                String pulseMessage;
                if (latestFeedingCompleted == null || latestCompletedAt == null) {
                  pulseMessage = '${context.tr('No feeding events completed today for')} $petName.';
                } else {
                  final feedingData = latestFeedingCompleted.data();
                  final completedBy = ((feedingData['completed_by_username'] as String?) ?? '').trim();
                  final completedByLabel = completedBy.isNotEmpty
                      ? completedBy
                      : context.tr('someone in the family');
                  final timeLabel = _formatShortTime(latestCompletedAt);
                  pulseMessage =
                      '$petName ${context.tr('was last fed by')} $completedByLabel ${context.tr('at')} $timeLabel.';
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3A35),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: Color(0xFF7FC8A8)),
                          SizedBox(width: 8),
                          Text(
                            'PET HEALTH PULSE',
                            style: TextStyle(
                              color: Color(0xFF9FD6BD),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pulseMessage,
                        style: const TextStyle(
                          color: Color(0xFFC9E9D9),
                          fontSize: 16,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _viewModel.streamFamiliesForCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Container(
            color: _bg,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${context.tr('Error loading families')}:\n${snapshot.error}',
                  style: const TextStyle(color: _textMuted),
                ),
              ),
            ),
          );
        }

        final families = snapshot.data ?? [];
        final hasFamily = families.isNotEmpty;
        final family = hasFamily ? families.first : null;
        final data = family?.data() ?? <String, dynamic>{};
        final familyName = hasFamily ? (data['name'] as String?) ?? 'My Family' : 'My Family';
        final ownerUid = (data['owner_uid'] as String?) ?? '';
        final memberUids = (data['member_uids'] as List<dynamic>? ?? const []);
        final adminUids =
            (data['admin_uids'] as List<dynamic>? ?? <dynamic>[ownerUid]).toSet().toList();
        final currentUid = _auth.currentUser?.uid ?? '';
        final isCurrentUserAdmin = adminUids.contains(currentUid) || ownerUid == currentUid;
        final hasAnotherAdmin =
            adminUids.any((uid) => uid.toString() != currentUid) || ownerUid != currentUid;
        final inviteCode = hasFamily ? _buildInviteCode(familyName, family!.id) : '-- -- --';

        return Container(
          color: _bg,
          child: Stack(
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: _surfaceHigh.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: Image.asset(
                                'assets/icon/StitchSyncIcon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'StitchSync',
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.pets_rounded,
                              color: _textMuted,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.tr('My Family'),
                        style: const TextStyle(
                          color: _textMain,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasFamily
                          ? context.tr('Manage everyone who helps take care of your pet.')
                          : context.tr('No family available. Create one to get started.'),
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E67B1), Color(0xFF2D7BC9)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(11, 53, 100, 0.35),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('SHARE INVITE CODE'),
                              style: const TextStyle(
                                color: Color(0xFFD8EAFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A80C7),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      inviteCode,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2.2,
                                      ),
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: hasFamily
                                        ? () async {
                                            final copiedMessage = context.tr('Invitation code copied.');
                                            final messenger = ScaffoldMessenger.of(context);
                                            await Clipboard.setData(
                                              ClipboardData(text: inviteCode),
                                            );
                                            if (!mounted) {
                                              return;
                                            }
                                            messenger.showSnackBar(
                                              SnackBar(content: Text(copiedMessage)),
                                            );
                                          }
                                        : () async {
                                            await _openCreateFamilyScreen();
                                          },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF0C53A1),
                                    ),
                                    child: Text(hasFamily ? context.tr('Copy') : context.tr('Create')),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              hasFamily
                                  ? context.tr('Send this code to family members to sync your pet\'s schedule.')
                                  : context.tr('Create a family to enable invites and sync.'),
                              style: const TextStyle(
                                color: Color(0xFFE3F0FF),
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                            if (!hasFamily) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _showJoinByCodeDialog,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.40),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.group_add_rounded),
                                  label: Text(
                                    context.tr('Join with code'),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (hasFamily) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('Active Members'),
                                style: const TextStyle(
                                  color: _textMain,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<_MemberData>>(
                          future: _loadMembers(memberUids, ownerUid, adminUids),
                          builder: (context, membersSnapshot) {
                            if (membersSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final members = membersSnapshot.data ?? [];

                            return Column(
                              children: [
                                ...members.map(
                                  (member) => Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(13),
                                          child: buildUserAvatarVisual(
                                            avatarId: member.avatarId,
                                            size: 52,
                                            borderRadius: BorderRadius.circular(13),
                                            emojiSize: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member.name +
                                                    (member.uid == _auth.currentUser?.uid
                                                        ? ' (${context.tr('You')})'
                                                        : ''),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: _textMain,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                member.subtitle,
                                                style: const TextStyle(
                                                  color: _textMuted,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (member.isAdmin)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2A3752),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'ADMIN',
                                              style: TextStyle(
                                                color: Color(0xFFAFBAD0),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          )
                                        else
                                          InkWell(
                                            onTap: () {
                                              _showMemberActions(
                                                familyId: family!.id,
                                                member: member,
                                                canManage: isCurrentUserAdmin,
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(10),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.more_vert,
                                                color: Color(0xFF7D889E),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _leaveCurrentFamily(
                                familyId: family!.id,
                                isCurrentUserAdmin: isCurrentUserAdmin,
                                hasAnotherAdmin: hasAnotherAdmin,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFFA3A3),
                              side: const BorderSide(color: Color(0xFFFF8E8E)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.exit_to_app_rounded),
                            label: Text(
                              context.tr('Leave family'),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (hasFamily && family != null)
                        _buildPetHealthPulse(familyId: family.id),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemberData {
  final String uid;
  final String name;
  final String subtitle;
  final bool isOwner;
  final bool isAdmin;
  final String avatarId;

  const _MemberData({
    required this.uid,
    required this.name,
    required this.subtitle,
    required this.isOwner,
    required this.isAdmin,
    required this.avatarId,
  });
}
