import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _eventsCollection(String familyId) {
    return _firestore.collection('families').doc(familyId).collection('events');
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamTodayEvents({
    required String familyId,
    String? petId,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return _eventsCollection(familyId)
        .where('scheduled_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduled_at', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduled_at')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      if (petId == null || petId.isEmpty) {
        return docs;
      }

      return docs.where((doc) {
        final data = doc.data();
        final eventPetId = (data['pet_id'] as String?) ?? '';
        return eventPetId == petId;
      }).toList(growable: false);
    });
  }

  Future<void> addEvent({
    required String familyId,
    String? petId,
    required String title,
    required DateTime scheduledAt,
    String note = '',
    String category = 'general',
  }) async {
    final uid = _auth.currentUser?.uid;

    await _eventsCollection(familyId).add({
      'family_id': familyId,
      'pet_id': (petId ?? '').trim(),
      'title': title.trim(),
      'note': note.trim(),
      'category': category.trim(),
      'scheduled_at': Timestamp.fromDate(scheduledAt),
      'created_by_uid': uid,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
