import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/family_service.dart';
import 'manage_pets_screen.dart';

class ManageFamilyScreen extends StatefulWidget {
  const ManageFamilyScreen({super.key});

  @override
  State<ManageFamilyScreen> createState() => _ManageFamilyScreenState();
}

class _ManageFamilyScreenState extends State<ManageFamilyScreen> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    final families = await _familyService.streamFamiliesForCurrentUser().first;
    if (families.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No family found')),
      );
      return;
    }

    final family = families.first;
    final familyName = (family.data()['name'] as String?) ?? 'My Family';

    try {
      await _familyService.inviteByEmail(
        familyId: family.id,
        familyName: familyName,
        email: email,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Invite sent successfully')),
      );

      _emailController.clear();
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<List<_MemberData>> _loadMembers(
      List<dynamic> memberUids, String ownerUid) async {
    final docs = await Future.wait(
      memberUids.map(
        (uid) => _firestore.collection('users').doc(uid as String).get(),
      ),
    );

    return docs.map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final username = (data['username'] as String?)?.trim();
      return _MemberData(
        uid: doc.id,
        name: (username != null && username.isNotEmpty) ? username : 'Member',
        subtitle: doc.id == ownerUid ? 'ADMIN' : 'CARETAKER',
        isAdmin: doc.id == ownerUid,
      );
    }).toList();
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
                      const Expanded(
                        child: Text(
                          'Manage Family',
                          style: TextStyle(
                            color: _textMain,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert, color: _textMuted),
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
                              const Text(
                                'Expand the pack',
                                style: TextStyle(
                                  color: _textMain,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Invite caretakers or family members to help manage Fido\'s daily routine.',
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: _textMain),
                                  decoration: const InputDecoration(
                                    hintText: 'Email address',
                                    hintStyle: TextStyle(
                                        color: Color(0xFF4D5F82), fontSize: 16),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2D66D8),
                                      Color(0xFF1E4A9E)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: ElevatedButton(
                                  onPressed: _sendInvite,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: const Text(
                                    'Send Invite',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
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

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CURRENT MEMBERS',
                                      style: const TextStyle(
                                        color: _textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      '${memberUids.length} active members',
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
                                      _loadMembers(memberUids, ownerUid),
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
                                                  Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      color: _surfaceHigh,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(12),
                                                    ),
                                                    child: Icon(
                                                      Icons.person,
                                                      color: _primary,
                                                      size: 28,
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
                                                                  ? ' (You)'
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
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Manage Pets',
                                        style: TextStyle(
                                          color: _textMain,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'View and edit shared pet profiles',
                                        style: TextStyle(
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

  const _MemberData({
    required this.uid,
    required this.name,
    required this.subtitle,
    required this.isAdmin,
  });
}
