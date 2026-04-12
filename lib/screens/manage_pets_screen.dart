import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/family_service.dart';
import '../services/pet_service.dart';

class ManagePetsScreen extends StatefulWidget {
  const ManagePetsScreen({super.key});

  @override
  State<ManagePetsScreen> createState() => _ManagePetsScreenState();
}

class _ManagePetsScreenState extends State<ManagePetsScreen> {
  final FamilyService _familyService = FamilyService();
  final PetService _petService = PetService();
  String? _selectedFamilyId;

  Future<void> _showPetDialog({
    required String familyId,
    String? petId,
    Map<String, dynamic>? initialData,
  }) async {
    final nameController = TextEditingController(text: initialData?['name'] as String? ?? '');
    final breedController =
        TextEditingController(text: initialData?['breed'] as String? ?? '');
    final ageController = TextEditingController(
      text: (initialData?['age'] as int?)?.toString() ?? '',
    );
    final notesController =
        TextEditingController(text: initialData?['notes'] as String? ?? '');
    final photoController =
        TextEditingController(text: initialData?['photo_url'] as String? ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(petId == null ? 'Agregar mascota' : 'Editar mascota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: breedController,
                  decoration: const InputDecoration(labelText: 'Raza o tipo'),
                ),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Edad'),
                ),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notas'),
                ),
                TextField(
                  controller: photoController,
                  decoration: const InputDecoration(
                    labelText: 'URL de foto (opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final breed = breedController.text.trim();
                final notes = notesController.text.trim();
                final photoUrl = photoController.text.trim();
                final age = int.tryParse(ageController.text.trim());

                if (name.isEmpty || breed.isEmpty || age == null) {
                  return;
                }

                if (petId == null) {
                  await _petService.addPet(
                    familyId: familyId,
                    name: name,
                    breed: breed,
                    age: age,
                    notes: notes,
                    photoUrl: photoUrl,
                  );
                } else {
                  await _petService.updatePet(
                    familyId: familyId,
                    petId: petId,
                    name: name,
                    breed: breed,
                    age: age,
                    notes: notes,
                    photoUrl: photoUrl,
                  );
                }

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    breedController.dispose();
    ageController.dispose();
    notesController.dispose();
    photoController.dispose();
  }

  Future<void> _deletePet({required String familyId, required String petId}) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Eliminar mascota'),
              content: const Text('¿Seguro que quieres eliminar esta mascota?'),
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
            );
          },
        ) ??
        false;

    if (!confirm) {
      return;
    }

    await _petService.deletePet(familyId: familyId, petId: petId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar mascotas'),
        backgroundColor: const Color(0xFF143A5A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _familyService.streamFamiliesForCurrentUser(),
        builder: (context, familiesSnapshot) {
          if (familiesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final families = familiesSnapshot.data ?? [];
          if (families.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Primero crea o acepta una familia para empezar a registrar mascotas.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final selectedId = _selectedFamilyId ?? families.first.id;
          if (_selectedFamilyId == null ||
              !families.any((family) => family.id == _selectedFamilyId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _selectedFamilyId = families.first.id;
              });
            });
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedId,
                      isExpanded: true,
                      hint: const Text('Selecciona una familia'),
                      items: families.map((familyDoc) {
                        final data = familyDoc.data();
                        final familyName =
                            (data['name'] as String?) ?? 'Familia sin nombre';
                        return DropdownMenuItem<String>(
                          value: familyDoc.id,
                          child: Text(familyName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedFamilyId = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  stream: _petService.streamPets(selectedId),
                  builder: (context, petSnapshot) {
                    if (petSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final pets = petSnapshot.data ?? [];
                    if (pets.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'No hay mascotas en esta familia todavía.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _showPetDialog(familyId: selectedId),
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar mascota'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D6A7B),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final petDoc = pets[index];
                        final pet = petDoc.data();
                        final name = (pet['name'] as String?) ?? 'Sin nombre';
                        final breed = (pet['breed'] as String?) ?? 'Sin tipo';
                        final notes = (pet['notes'] as String?) ?? '';
                        final age = pet['age']?.toString() ?? '-';
                        final photoUrl = (pet['photo_url'] as String?) ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE9F3F7),
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl.isEmpty
                                  ? const Icon(Icons.pets, color: Color(0xFF1D6A7B))
                                  : null,
                            ),
                            title: Text(name),
                            subtitle: Text('Raza/tipo: $breed\nEdad: $age\n$notes'),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showPetDialog(
                                    familyId: selectedId,
                                    petId: petDoc.id,
                                    initialData: pet,
                                  );
                                }

                                if (value == 'delete') {
                                  _deletePet(familyId: selectedId, petId: petDoc.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedFamilyId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showPetDialog(familyId: _selectedFamilyId!),
              backgroundColor: const Color(0xFF1D6A7B),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Mascota'),
            ),
    );
  }
}