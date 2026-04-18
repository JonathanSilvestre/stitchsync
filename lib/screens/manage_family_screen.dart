import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_i18n.dart';
import '../services/family_service.dart';
import '../utils/user_avatar_catalog.dart';
import 'manage_pets_screen.dart';

class ManageFamilyScreen extends StatefulWidget {
  const ManageFamilyScreen({super.key});

  @override
  State<ManageFamilyScreen> createState() => _ManageFamilyScreenState();
}

class _ManageFamilyScreenState extends State<ManageFamilyScreen> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);
  static const Color _errorRed = Color(0xFFD32F2F);

  String _buildInviteCode(String familyName, String familyId) {
    final prefix = familyName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final shortPrefix = prefix.isEmpty ? 'STITCH' : prefix;
    final left = shortPrefix.substring(0, shortPrefix.length.clamp(0, 6));
    final right = familyId.substring(0, 3).toUpperCase();
    return '$left-$right';
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Invitation code copied.'))),
    );
  }

  Future<List<_MemberData>> _loadMembers(
      List<dynamic> memberUids, String ownerUid, List<dynamic> adminUids) async {
    final adminSet = adminUids.map((e) => e.toString()).toSet();
    
    final docs = await Future.wait(
      memberUids.map(
        (uid) => _firestore.collection('users').doc(uid as String).get(),
      ),
    );

    return docs.map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final username = (data['username'] as String?)?.trim();
      final avatarId = (data['profile_avatar_id'] as String?)?.trim();
      final isOwner = doc.id == ownerUid;
      final isAdmin = isOwner || adminSet.contains(doc.id);
      
      return _MemberData(
        uid: doc.id,
        name: (username != null && username.isNotEmpty)
            ? username
            : context.tr('Member'),
        subtitle: isOwner
            ? context.tr('Family Owner')
            : isAdmin
                ? context.tr('Family Administrator')
                : context.tr('Member'),
        isAdmin: isAdmin,
        avatarId: resolveUserAvatar(avatarId).id,
      );
    }).toList();
  }

  Future<void> _deleteFamilyFlow({
    required String familyId,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: Text(
          context.tr('Delete Family'),
          style: const TextStyle(color: _textMain, fontWeight: FontWeight.w700),
        ),
        content: Text(
          context.tr('This action will permanently delete the family and its pets. Continue?'),
          style: const TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.tr('Delete'),
              style: const TextStyle(color: _errorRed),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _familyService.deleteFamily(familyId);

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('Family deleted successfully.'))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('${context.tr('Could not delete family.')} $e')),
      );
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
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFF0A1730),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: _textMuted),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.pets, color: _primary, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('Manage Family'),
                          style: const TextStyle(
                            color: _textMain,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _surfaceHigh,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Expand the pack'),
                                style: const TextStyle(
                                  color: _textMain,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('Share this family code so others can join your pack.'),
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                                stream: _familyService.streamFamiliesForCurrentUser(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final families = snapshot.data ?? const [];
                                  if (families.isEmpty) {
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: _surface,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        context.tr('No family found.'),
                                        style: const TextStyle(color: _textMuted, fontSize: 16),
                                      ),
                                    );
                                  }

                                  final family = families.first;
                                  final familyData = family.data();
                                    final familyName =
                                      (familyData['name'] as String?) ?? context.tr('My Family');
                                  final storedCode = (familyData['invite_code'] as String?)?.trim() ?? '';
                                  final inviteCode = storedCode.isNotEmpty
                                      ? storedCode
                                      : _buildInviteCode(familyName, family.id);

                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _surfaceHigh,
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Text(
                                              inviteCode,
                                              style: const TextStyle(
                                                color: _textMain,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          onPressed: () => _copyInviteCode(inviteCode),
                                          icon: const Icon(Icons.copy_rounded, color: _primary),
                                          tooltip: context.tr('Copy code'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        StreamBuilder<List<
                            QueryDocumentSnapshot<Map<String, dynamic>>>>(
                          stream:
                              _familyService.streamFamiliesForCurrentUser(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final families = snapshot.data ?? [];
                            if (families.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final family = families.first;
                            final data = family.data();
                            final memberUids =
                                (data['member_uids'] as List<dynamic>?) ?? [];
                            final ownerUid =
                                (data['owner_uid'] as String?) ?? '';
                            final adminUids =
                                (data['admin_uids'] as List<dynamic>?) ?? [];
                            final currentUid =
                              FirebaseAuth.instance.currentUser?.uid ?? '';
                            final canDeleteFamily =
                              currentUid.isNotEmpty && ownerUid == currentUid;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.tr('CURRENT MEMBERS'),
                                      style: const TextStyle(
                                        color: _textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      '${memberUids.length} ${context.tr('active members')}',
                                      style: const TextStyle(
                                        color: _textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                FutureBuilder<List<_MemberData>>(
                                  future:
                                      _loadMembers(memberUids, ownerUid, adminUids),
                                  builder: (context, membersSnapshot) {
                                    if (membersSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child:
                                              CircularProgressIndicator());
                                    }

                                    final members = membersSnapshot.data ?? [];

                                    return Column(
                                      children: members
                                          .map(
                                            (member) => Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              padding:
                                                  const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: _surface,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    child: buildUserAvatarVisual(
                                                      avatarId: member.avatarId,
                                                      size: 56,
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                      emojiSize: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          member.name +
                                                              (member.uid ==
                                                                      FirebaseAuth
                                                                          .instance
                                                                          .currentUser
                                                                          ?.uid
                                                              ? ' (${context.tr('You')})'
                                                                  : ''),
                                                          style: const TextStyle(
                                                            color: _textMain,
                                                            fontSize: 17,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          member.subtitle,
                                                          style: const TextStyle(
                                                            color: _textMuted,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (member.isAdmin)
                                                    const Icon(
                                                      Icons.lock,
                                                      color: _textMuted,
                                                    )
                                                  else
                                                    const Icon(
                                                      Icons
                                                          .person_remove_outlined,
                                                      color: _textMuted,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                                if (canDeleteFamily) ...[
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _deleteFamilyFlow(
                                        familyId: family.id,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _errorRed,
                                        side: BorderSide(
                                          color: _errorRed.withValues(alpha: 0.65),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                      label: Text(
                                        context.tr('Delete Family'),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ManagePetsScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _surfaceHigh,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.pets,
                                      color: _primary, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('Manage Pets'),
                                        style: const TextStyle(
                                          color: _textMain,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.tr('View and edit shared pet profiles'),
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: _textMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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

class _MemberData {
  final String uid;
  final String name;
  final String subtitle;
  final bool isAdmin;
  final String avatarId;

  const _MemberData({
    required this.uid,
    required this.name,
    required this.subtitle,
    required this.isAdmin,
    required this.avatarId,
  });
}
