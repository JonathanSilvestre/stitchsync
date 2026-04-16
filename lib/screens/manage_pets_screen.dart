import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/family_service.dart';
import '../services/pet_service.dart';
import '../utils/pet_avatar_catalog.dart';
import 'add_new_pet_screen.dart';

class ManagePetsScreen extends StatefulWidget {
  const ManagePetsScreen({super.key});

  @override
  State<ManagePetsScreen> createState() => _ManagePetsScreenState();
}

class _ManagePetsScreenState extends State<ManagePetsScreen> {
  final FamilyService _familyService = FamilyService();
  final PetService _petService = PetService();

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF0F1930);
  static const Color _surfaceHigh = Color(0xFF192540);
  static const Color _textMain = Color(0xFFDEE5FF);
  static const Color _textMuted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);

  Future<void> _deletePet({
    required String familyId,
    required String petId,
    required String petName,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceHigh,
          title: const Text(
            'Delete Pet',
            style: TextStyle(color: _textMain, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete $petName?',
            style: const TextStyle(color: _textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: _primary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await _petService.deletePet(familyId: familyId, petId: petId);
    }
  }

  void _editPet({
    required String familyId,
    required String petId,
    required Map<String, dynamic> petData,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddNewPetScreen(
          familyId: familyId,
          petId: petId,
          initialPetData: petData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _familyService.streamFamiliesForCurrentUser(),
      builder: (context, familiesSnapshot) {
        if (familiesSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: _bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final families = familiesSnapshot.data ?? [];
        if (families.isEmpty) {
          return Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: Text(
                'No family found',
                style: TextStyle(color: _textMuted, fontSize: 16),
              ),
            ),
          );
        }

        final family = families.first;
        final familyId = family.id;

        return FutureBuilder<bool>(
          future: _familyService.isCurrentUserFamilyAdmin(familyId: familyId),
          builder: (context, permissionSnapshot) {
            final canManagePets = permissionSnapshot.data ?? false;

            return Scaffold(
              backgroundColor: _bg,
              floatingActionButton: canManagePets
                  ? FloatingActionButton(
                      backgroundColor: _primary,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddNewPetScreen(familyId: familyId),
                        ),
                      ),
                      child: const Icon(Icons.add, color: _bg),
                    )
                  : null,
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
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: const Color(0xFF0A1730),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back, color: _textMain, size: 24),
                              ),
                              const Expanded(
                                child: Text(
                                  'Manage Pets',
                                  style: TextStyle(
                                    color: _textMain,
                                    fontSize: 28,
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
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Furry Family',
                                  style: TextStyle(
                                    color: _textMain,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Keep track of everyone in the household.',
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 16,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                                  stream: _petService.streamPets(familyId),
                                  builder: (context, petsSnapshot) {
                                    if (petsSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    final pets = petsSnapshot.data ?? [];
                                    if (pets.isEmpty) {
                                      return Column(
                                        children: [
                                          const SizedBox(height: 60),
                                          const Icon(Icons.pets_outlined, color: _textMuted, size: 52),
                                          const SizedBox(height: 12),
                                          Text(
                                            canManagePets
                                                ? 'Add all your companions to stay connected'
                                                : 'No hay mascotas en esta familia.',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: _textMuted,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 30),
                                        ],
                                      );
                                    }

                                    return Column(
                                      children: [
                                        ...pets.map((petDoc) {
                                          final petData = petDoc.data();
                                          final name = (petData['name'] as String?) ?? 'Pet';
                                          final breed = (petData['breed'] as String?) ?? 'Unknown';
                                          final age = petData['age'] as int? ?? 0;
                                          final photoUrl = (petData['photo_url'] as String?) ?? '';
                                          final avatarId = (petData['avatar_id'] as String?) ?? '';
                                          final notes = (petData['notes'] as String?) ?? '';

                                          var statusLabel = 'ACTIVE';
                                          final lowerNotes = notes.toLowerCase();
                                          if (lowerNotes.contains('sitter')) {
                                            statusLabel = 'AT SITTER\'S';
                                          } else if (lowerNotes.contains('vet')) {
                                            statusLabel = 'AT VET';
                                          }

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: _surface,
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(20),
                                                    color: _surfaceHigh,
                                                  ),
                                                  child: buildPetAvatarVisual(
                                                    photoUrl: photoUrl,
                                                    avatarId: avatarId,
                                                    size: 100,
                                                    borderRadius: BorderRadius.circular(20),
                                                    iconSize: 48,
                                                    placeholderBackground: _surfaceHigh,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: const TextStyle(
                                                          color: _textMain,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '$breed • $age Years',
                                                        style: const TextStyle(
                                                          color: _textMuted,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _surfaceHigh,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          statusLabel,
                                                          style: const TextStyle(
                                                            color: _primary,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (canManagePets)
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () => _editPet(
                                                          familyId: familyId,
                                                          petId: petDoc.id,
                                                          petData: petData,
                                                        ),
                                                        icon: const Icon(Icons.edit, color: _primary),
                                                      ),
                                                      IconButton(
                                                        onPressed: () => _deletePet(
                                                          familyId: familyId,
                                                          petId: petDoc.id,
                                                          petName: name,
                                                        ),
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Color(0xFFD32F2F),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          );
                                        }),
                                        if (!canManagePets)
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: _surface,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                  color: _textMuted.withValues(alpha: 0.25)),
                                            ),
                                            child: const Text(
                                              'Modo miembro: solo puedes visualizar mascotas.',
                                              style: TextStyle(color: _textMuted, fontSize: 13),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
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
          },
        );
      },
    );
  }
}