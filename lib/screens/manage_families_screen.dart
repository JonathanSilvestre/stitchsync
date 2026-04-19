import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_i18n.dart';
import '../viewmodels/screens/manage_families_view_model.dart';

class ManageFamiliesScreen extends StatefulWidget {
  const ManageFamiliesScreen({super.key});

  @override
  State<ManageFamiliesScreen> createState() => _ManageFamiliesScreenState();
}

class _ManageFamiliesScreenState extends State<ManageFamiliesScreen> {
  final ManageFamiliesViewModel _viewModel = ManageFamiliesViewModel();
  FirebaseAuth get _auth => _viewModel.auth;
  bool _isProcessing = false;

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
      _isProcessing = _viewModel.isLoading;
    });
  }

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _showFamilyDialog({
    String? familyId,
    String initialName = '',
  }) async {
    final controller = TextEditingController(text: initialName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            familyId == null ? context.tr('Create family') : context.tr('Edit family'),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: context.tr('Family name')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }

                final ok = await _viewModel.saveFamilyWithFeedback(
                  value: value,
                  familyId: familyId,
                );

                if (!ok) {
                  return;
                }

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();
              },
              child: Text(context.tr('Save')),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _showInviteDialog({
    required String familyId,
    required String familyName,
  }) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('Invite by email')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: context.tr('Family member email'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = controller.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  return;
                }

                final ok = await _viewModel.inviteByEmailWithFeedback(
                  familyId: familyId,
                  familyName: familyName,
                  email: email,
                  successMessage: 'Invitation created successfully',
                );

                if (!ok) {
                  return;
                }

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();
              },
              child: Text(context.tr('Invite')),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _deleteFamily(String familyId) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.tr('Delete family')),
            content: Text(
              context.tr('This action will delete the family, its pets, and invitations.'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.tr('Delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) {
      return;
    }

    await _viewModel.deleteFamilyWithFeedback(
      familyId: familyId,
      errorMessage: 'Could not delete family.',
    );
  }

  Future<void> _respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    await _viewModel.respondToInvitationWithFeedback(
      invitationId: invitationId,
      accept: accept,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Manage families')),
        backgroundColor: const Color(0xFF143A5A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFamilyDialog(),
        backgroundColor: const Color(0xFF1D6A7B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.tr('New family')),
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(context.tr('My families')),
          const SizedBox(height: 8),
          StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _viewModel.streamFamiliesForCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return _InfoCard(
                  message: context.tr('You do not have families yet. Create one to get started.'),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final name = (data['name'] as String?) ?? context.tr('Unnamed');
                  final ownerUid = (data['owner_uid'] as String?) ?? '';
                  final members =
                      (data['member_uids'] as List<dynamic>? ?? const []).length;
                  final isOwner = ownerUid == currentUid;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text('${context.tr('Members')}: $members'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'invite') {
                            _showInviteDialog(familyId: doc.id, familyName: name);
                          }

                          if (value == 'edit' && isOwner) {
                            _showFamilyDialog(
                              familyId: doc.id,
                              initialName: name,
                            );
                          }

                          if (value == 'delete' && isOwner) {
                            _deleteFamily(doc.id);
                          }
                        },
                        itemBuilder: (_) {
                          final items = <PopupMenuEntry<String>>[
                            PopupMenuItem(
                              value: 'invite',
                              child: Text(context.tr('Invite by email')),
                            ),
                          ];

                          if (isOwner) {
                            items.addAll([
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(context.tr('Edit name')),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(context.tr('Delete family')),
                              ),
                            ]);
                          }

                          return items;
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          _SectionTitle(context.tr('Pending invitations')),
          const SizedBox(height: 8),
          StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _viewModel.streamPendingInvitationsForCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return _InfoCard(
                  message: context.tr('You have no pending invitations right now.'),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final familyName =
                      (data['family_name'] as String?) ?? context.tr('Unnamed family');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          familyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _respondToInvitation(
                                          invitationId: doc.id,
                                          accept: false,
                                        ),
                                child: Text(context.tr('Reject')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _respondToInvitation(
                                          invitationId: doc.id,
                                          accept: true,
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D6A7B),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(context.tr('Accept')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF17324D),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String message;

  const _InfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message),
    );
  }
}