import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/family_service.dart';

class ManageFamiliesScreen extends StatefulWidget {
  const ManageFamiliesScreen({super.key});

  @override
  State<ManageFamiliesScreen> createState() => _ManageFamiliesScreenState();
}

class _ManageFamiliesScreenState extends State<ManageFamiliesScreen> {
  final FamilyService _familyService = FamilyService();
  bool _isProcessing = false;

  Future<void> _showFamilyDialog({
    String? familyId,
    String initialName = '',
  }) async {
    final controller = TextEditingController(text: initialName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(familyId == null ? 'Crear familia' : 'Editar familia'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nombre de familia'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }

                try {
                  if (familyId == null) {
                    await _familyService.createFamily(value);
                  } else {
                    await _familyService.updateFamilyName(
                      familyId: familyId,
                      familyName: value,
                    );
                  }

                  if (!mounted) {
                    return;
                  }

                  Navigator.of(context).pop();
                } on FirebaseAuthException catch (e) {
                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_familyService.getReadableError(e))),
                  );
                }
              },
              child: const Text('Guardar'),
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
          title: const Text('Invitar por correo'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo del familiar',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = controller.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  return;
                }

                try {
                  await _familyService.inviteByEmail(
                    familyId: familyId,
                    familyName: familyName,
                    email: email,
                  );

                  if (!mounted) {
                    return;
                  }

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invitación creada correctamente'),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_familyService.getReadableError(e))),
                  );
                }
              },
              child: const Text('Invitar'),
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
            title: const Text('Eliminar familia'),
            content: const Text(
              'Esta acción eliminará la familia, sus mascotas e invitaciones.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) {
      return;
    }

    try {
      await _familyService.deleteFamily(familyId);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la familia')),
      );
    }
  }

  Future<void> _respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      if (accept) {
        await _familyService.acceptInvitation(invitationId: invitationId);
      } else {
        await _familyService.rejectInvitation(invitationId: invitationId);
      }
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
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar familias'),
        backgroundColor: const Color(0xFF143A5A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFamilyDialog(),
        backgroundColor: const Color(0xFF1D6A7B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva familia'),
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Mis familias'),
          const SizedBox(height: 8),
          StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _familyService.streamFamiliesForCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return const _InfoCard(
                  message: 'Aún no tienes familias. Crea una para empezar.',
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final name = (data['name'] as String?) ?? 'Sin nombre';
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
                      subtitle: Text('Miembros: $members'),
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
                            const PopupMenuItem(
                              value: 'invite',
                              child: Text('Invitar por correo'),
                            ),
                          ];

                          if (isOwner) {
                            items.addAll([
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar nombre'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar familia'),
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
          const _SectionTitle('Invitaciones pendientes'),
          const SizedBox(height: 8),
          StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _familyService.streamPendingInvitationsForCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return const _InfoCard(
                  message: 'No tienes invitaciones pendientes por ahora.',
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final familyName =
                      (data['family_name'] as String?) ?? 'Familia sin nombre';

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
                                child: const Text('Rechazar'),
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
                                child: const Text('Aceptar'),
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