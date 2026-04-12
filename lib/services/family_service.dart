import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _families =>
      _firestore.collection('families');
  CollectionReference<Map<String, dynamic>> get _invitations =>
      _firestore.collection('invitations');

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email?.toLowerCase();

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamFamiliesForCurrentUser() {
    final uid = currentUid;

    if (uid == null) {
      return const Stream.empty();
    }

    return _families
        .where('member_uids', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> createFamily(String familyName) async {
    final uid = currentUid;

    if (uid == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    await _families.add({
      'name': familyName.trim(),
      'owner_uid': uid,
      'member_uids': [uid],
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFamilyName({
    required String familyId,
    required String familyName,
  }) async {
    await _families.doc(familyId).update({
      'name': familyName.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFamily(String familyId) async {
    final familyRef = _families.doc(familyId);
    final pets = await familyRef.collection('pets').get();

    for (final petDoc in pets.docs) {
      await petDoc.reference.delete();
    }

    await familyRef.delete();

    final invitations = await _invitations.where('family_id', isEqualTo: familyId).get();
    for (final doc in invitations.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> inviteByEmail({
    required String familyId,
    required String familyName,
    required String email,
  }) async {
    final uid = currentUid;

    if (uid == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final existing = await _invitations
        .where('family_id', isEqualTo: familyId)
        .where('to_email_lower', isEqualTo: normalizedEmail)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'invitation-exists',
        message: 'Ya existe una invitación pendiente para ese correo.',
      );
    }

    await _invitations.add({
      'family_id': familyId,
      'family_name': familyName,
      'to_email_lower': normalizedEmail,
      'invited_by_uid': uid,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamPendingInvitationsForCurrentUser() {
    final email = currentEmail;

    if (email == null) {
      return const Stream.empty();
    }

    return _invitations
        .where('to_email_lower', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> acceptInvitation({required String invitationId}) async {
    final uid = currentUid;

    if (uid == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final inviteRef = _invitations.doc(invitationId);

    await _firestore.runTransaction((tx) async {
      final inviteSnap = await tx.get(inviteRef);
      if (!inviteSnap.exists) {
        throw FirebaseAuthException(code: 'invitation-not-found');
      }

      final inviteData = inviteSnap.data()!;
      if (inviteData['status'] != 'pending') {
        throw FirebaseAuthException(code: 'invitation-not-pending');
      }

      final familyId = inviteData['family_id'] as String;
      final familyRef = _families.doc(familyId);
      final familySnap = await tx.get(familyRef);

      if (!familySnap.exists) {
        throw FirebaseAuthException(code: 'family-not-found');
      }

      tx.update(familyRef, {
        'member_uids': FieldValue.arrayUnion([uid]),
        'updated_at': FieldValue.serverTimestamp(),
      });

      tx.update(inviteRef, {
        'status': 'accepted',
        'accepted_by_uid': uid,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectInvitation({required String invitationId}) async {
    final uid = currentUid;

    if (uid == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final inviteRef = _invitations.doc(invitationId);

    await inviteRef.update({
      'status': 'rejected',
      'rejected_by_uid': uid,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptAllPendingInvitationsForCurrentUser() async {
    final pending = await streamPendingInvitationsForCurrentUser().first;

    for (final invite in pending) {
      await acceptInvitation(invitationId: invite.id);
    }
  }

  String getReadableError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invitation-exists':
        return 'Ese correo ya tiene una invitación pendiente.';
      case 'invitation-not-found':
        return 'La invitación ya no existe.';
      case 'invitation-not-pending':
        return 'La invitación ya fue procesada.';
      case 'family-not-found':
        return 'La familia no existe o fue eliminada.';
      case 'user-not-found':
        return 'No hay una sesión activa para esta operación.';
      default:
        return error.message ?? 'No se pudo completar la operación.';
    }
  }
}
