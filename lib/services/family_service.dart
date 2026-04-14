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

  Future<void> syncCurrentUserFamilyIds() async {
    final uid = currentUid;

    if (uid == null) {
      return;
    }

    final families = await _families
        .where('member_uids', arrayContains: uid)
        .get();

    final familyIds = families.docs.map((doc) => doc.id).toList(growable: false);

    await _firestore.collection('users').doc(uid).set({
      'family_ids': familyIds,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _buildInviteCode(String familyName, String familyId) {
    final prefix = familyName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final shortPrefix = prefix.isEmpty ? 'STITCH' : prefix;
    final left = shortPrefix.substring(0, shortPrefix.length.clamp(0, 6));
    final right = familyId.substring(0, 3).toUpperCase();
    return '$left-$right';
  }

  String _normalizeInviteCode(String rawCode) {
    return rawCode.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

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

  Future<String> createFamily(String familyName) async {
    final uid = currentUid;

    if (uid == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final cleanFamilyName = familyName.trim();
    final familyRef = _families.doc();
    final inviteCode = _buildInviteCode(cleanFamilyName, familyRef.id);

    await familyRef.set({
      'name': cleanFamilyName,
      'owner_uid': uid,
      'admin_uids': [uid],
      'member_uids': [uid],
      'invite_code': inviteCode,
      'invite_code_normalized': _normalizeInviteCode(inviteCode),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(uid).set({
      'family_ids': FieldValue.arrayUnion([familyRef.id]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return familyRef.id;
  }

  Future<void> joinFamilyByInviteCode({required String inviteCode}) async {
    final uid = currentUid;

    if (uid == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final normalizedCode = _normalizeInviteCode(inviteCode);
    if (normalizedCode.isEmpty || !normalizedCode.contains('-')) {
      throw FirebaseAuthException(
        code: 'invalid-invite-code',
        message: 'Código de invitación inválido.',
      );
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? targetFamily;

    final byStoredCode = await _families
        .where('invite_code_normalized', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (byStoredCode.docs.isNotEmpty) {
      targetFamily = byStoredCode.docs.first;
    } else {
      // Fallback for old families created before invite_code fields existed.
      final allFamilies = await _families.get();
      for (final familyDoc in allFamilies.docs) {
        final data = familyDoc.data();
        final name = (data['name'] as String?) ?? 'My Family';
        final generatedCode = _normalizeInviteCode(_buildInviteCode(name, familyDoc.id));
        if (generatedCode == normalizedCode) {
          targetFamily = familyDoc;
          break;
        }
      }
    }

    if (targetFamily == null) {
      throw FirebaseAuthException(
        code: 'family-not-found-by-code',
        message: 'No existe una familia con ese código.',
      );
    }

    final memberUids =
        (targetFamily.data()['member_uids'] as List<dynamic>? ?? const <dynamic>[])
            .cast<dynamic>();
    if (memberUids.contains(uid)) {
      throw FirebaseAuthException(
        code: 'already-family-member',
        message: 'Ya eres miembro de esta familia.',
      );
    }

    // Join by code always adds the user as member; owner/admin remains unchanged.
    await _families.doc(targetFamily.id).update({
      'member_uids': FieldValue.arrayUnion([uid]),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(uid).set({
      'family_ids': FieldValue.arrayUnion([targetFamily.id]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<String> _deriveAdminUids(Map<String, dynamic> familyData) {
    final rawAdmins = (familyData['admin_uids'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList(growable: true);

    final ownerUid = (familyData['owner_uid'] as String?)?.trim();
    if (ownerUid != null && ownerUid.isNotEmpty && !rawAdmins.contains(ownerUid)) {
      rawAdmins.add(ownerUid);
    }

    return rawAdmins;
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

  Future<void> promoteMemberToAdmin({
    required String familyId,
    required String memberUid,
  }) async {
    final uid = currentUid;

    if (uid == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final familyRef = _families.doc(familyId);

    await _firestore.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      if (!familySnap.exists) {
        throw FirebaseAuthException(code: 'family-not-found');
      }

      final familyData = familySnap.data()!;
      final memberUids =
          (familyData['member_uids'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString()).toList(growable: false);
      final adminUids = _deriveAdminUids(familyData);

      if (!adminUids.contains(uid)) {
        throw FirebaseAuthException(
          code: 'not-family-admin',
          message: 'Solo un administrador puede asignar nuevos administradores.',
        );
      }

      if (!memberUids.contains(memberUid)) {
        throw FirebaseAuthException(
          code: 'member-not-found',
          message: 'Ese usuario no pertenece a esta familia.',
        );
      }

      if (adminUids.contains(memberUid)) {
        return;
      }

      tx.update(familyRef, {
        'admin_uids': FieldValue.arrayUnion([memberUid]),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> leaveFamily({required String familyId}) async {
    final uid = currentUid;

    if (uid == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final familyRef = _families.doc(familyId);
    final userRef = _firestore.collection('users').doc(uid);
    var deleteFamilyAfterLeave = false;

    await _firestore.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      if (!familySnap.exists) {
        throw FirebaseAuthException(code: 'family-not-found');
      }

      final familyData = familySnap.data()!;
      final ownerUid = (familyData['owner_uid'] as String?)?.trim() ?? '';
      final memberUids =
          (familyData['member_uids'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString()).toList(growable: true);
      final adminUids = _deriveAdminUids(familyData);

      if (!memberUids.contains(uid)) {
        throw FirebaseAuthException(
          code: 'not-family-member',
          message: 'No perteneces a esta familia.',
        );
      }

      final remainingMembers = memberUids.where((id) => id != uid).toList(growable: false);
      final remainingAdmins = adminUids.where((id) => id != uid && remainingMembers.contains(id)).toList(growable: false);
      final isCurrentAdmin = adminUids.contains(uid);

      if (remainingMembers.isEmpty) {
        deleteFamilyAfterLeave = true;
        tx.delete(familyRef);
      } else {
        if (isCurrentAdmin && remainingAdmins.isEmpty) {
          throw FirebaseAuthException(
            code: 'admin-transfer-required',
            message: 'Debes asignar otro administrador antes de salir.',
          );
        }

        final nextOwnerUid = ownerUid == uid
            ? remainingAdmins.first
            : ownerUid;

        tx.update(familyRef, {
          'owner_uid': nextOwnerUid,
          'member_uids': remainingMembers,
          'admin_uids': remainingAdmins,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      tx.set(userRef, {
        'family_ids': FieldValue.arrayRemove([familyId]),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    if (deleteFamilyAfterLeave) {
      final invitations = await _invitations.where('family_id', isEqualTo: familyId).get();
      for (final doc in invitations.docs) {
        await doc.reference.delete();
      }
    }
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

      final userRef = _firestore.collection('users').doc(uid);
      tx.set(userRef, {
        'family_ids': FieldValue.arrayUnion([familyId]),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
      case 'invalid-invite-code':
        return 'Código de invitación inválido.';
      case 'family-not-found-by-code':
        return 'No encontramos una familia con ese código.';
      case 'already-family-member':
        return 'Ya perteneces a esa familia.';
      case 'not-family-admin':
        return 'Solo un administrador puede hacer ese cambio.';
      case 'member-not-found':
        return 'Ese miembro no pertenece a la familia.';
      case 'not-family-member':
        return 'No perteneces a esa familia.';
      case 'admin-transfer-required':
        return 'Debes asignar otro administrador antes de salir.';
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
