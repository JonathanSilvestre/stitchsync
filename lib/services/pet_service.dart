import 'package:cloud_firestore/cloud_firestore.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _petsCollection(String familyId) {
    return _firestore.collection('families').doc(familyId).collection('pets');
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamPets(String familyId) {
    return _petsCollection(familyId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> addPet({
    required String familyId,
    required String name,
    required String breed,
    required int age,
    required String notes,
    String? photoUrl,
  }) async {
    await _petsCollection(familyId).add({
      'name': name.trim(),
      'breed': breed.trim(),
      'age': age,
      'notes': notes.trim(),
      'photo_url': (photoUrl ?? '').trim(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePet({
    required String familyId,
    required String petId,
    required String name,
    required String breed,
    required int age,
    required String notes,
    String? photoUrl,
  }) async {
    await _petsCollection(familyId).doc(petId).update({
      'name': name.trim(),
      'breed': breed.trim(),
      'age': age,
      'notes': notes.trim(),
      'photo_url': (photoUrl ?? '').trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePet({required String familyId, required String petId}) async {
    await _petsCollection(familyId).doc(petId).delete();
  }
}
