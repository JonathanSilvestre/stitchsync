import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'family_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FamilyService _familyService = FamilyService();

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _usernamesCollection =>
      _firestore.collection('usernames');

  // Registro
  Future<User?> register({
    required String username,
    required String email,
    required String password,
    required int age,
    required String country,
  }) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();
      final normalizedEmail = email.trim().toLowerCase();

      final result = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = result.user;
      if (user == null) {
        return null;
      }

      final usernameRef = _usernamesCollection.doc(normalizedUsername);
      final userRef = _usersCollection.doc(user.uid);

      try {
        await _firestore.runTransaction((tx) async {
          final usernameSnap = await tx.get(usernameRef);
          if (usernameSnap.exists) {
            throw FirebaseAuthException(
              code: 'username-already-in-use',
              message: 'El nombre de usuario ya está en uso.',
            );
          }

          tx.set(usernameRef, {
            'uid': user.uid,
            'email': normalizedEmail,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });

          tx.set(userRef, {
            'uid': user.uid,
            'username': username.trim(),
            'username_lower': normalizedUsername,
            'email': normalizedEmail,
            'age': age,
            'country': country.trim(),
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        });
      } on FirebaseAuthException {
        await user.delete();
        rethrow;
      }

      await result.user?.sendEmailVerification();
      await _familyService.acceptAllPendingInvitationsForCurrentUser();
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  // Login
  Future<User?> login(String usernameOrEmail, String password) async {
    try {
      final email = await _resolveEmailFromIdentifier(usernameOrEmail);

      if (email == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No existe una cuenta con ese usuario o correo.',
        );
      }

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _familyService.acceptAllPendingInvitationsForCurrentUser();
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> refreshCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> sendPasswordReset(String usernameOrEmail) async {
    final email = await _resolveEmailFromIdentifier(usernameOrEmail);

    if (email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se encontró un usuario con ese identificador.',
      );
    }

    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateAccount({
    required String newUsername,
    required String currentPassword,
    String? newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No hay sesión activa.',
      );
    }

    final normalizedNewUsername = newUsername.trim().toLowerCase();
    final currentUserDoc = await _usersCollection.doc(user.uid).get();
    final currentUsername =
        (currentUserDoc.data()?['username_lower'] as String?) ?? '';

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    if (newPassword != null && newPassword.trim().isNotEmpty) {
      await user.updatePassword(newPassword.trim());
    }

    final userRef = _usersCollection.doc(user.uid);
    final newUsernameRef = _usernamesCollection.doc(normalizedNewUsername);
    final oldUsernameRef = currentUsername.isEmpty
        ? null
        : _usernamesCollection.doc(currentUsername);

    await _firestore.runTransaction((tx) async {
      if (normalizedNewUsername != currentUsername) {
        final newUsernameSnap = await tx.get(newUsernameRef);
        if (newUsernameSnap.exists) {
          throw FirebaseAuthException(
            code: 'username-already-in-use',
            message: 'Ese nombre de usuario ya está ocupado.',
          );
        }

        tx.set(newUsernameRef, {
          'uid': user.uid,
          'email': user.email!.toLowerCase(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (oldUsernameRef != null) {
          tx.delete(oldUsernameRef);
        }
      }

      tx.set(userRef, {
        'username': newUsername.trim(),
        'username_lower': normalizedNewUsername,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateUserProfile({required String username}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No hay sesión activa.',
      );
    }

    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-argument',
        message: 'El nombre de usuario no puede estar vacío.',
      );
    }

    final userRef = _usersCollection.doc(user.uid);
    final usernameRef = _usernamesCollection.doc(normalizedUsername);
    final currentUserDoc = await userRef.get();
    final currentUsername =
        (currentUserDoc.data()?['username_lower'] as String?) ?? '';
    final oldUsernameRef = currentUsername.isEmpty
        ? null
        : _usernamesCollection.doc(currentUsername);

    await _firestore.runTransaction((tx) async {
      if (normalizedUsername != currentUsername) {
        final usernameSnap = await tx.get(usernameRef);
        if (usernameSnap.exists) {
          throw FirebaseAuthException(
            code: 'username-already-in-use',
            message: 'Ese nombre de usuario ya está en uso.',
          );
        }

        tx.set(usernameRef, {
          'uid': user.uid,
          'email': user.email?.toLowerCase(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (oldUsernameRef != null) {
          tx.delete(oldUsernameRef);
        }
      }

      tx.set(userRef, {
        'username': username.trim(),
        'username_lower': normalizedUsername,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await user.updateDisplayName(username.trim());
    await refreshCurrentUser();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return null;
    }

    final doc = await _usersCollection.doc(uid).get();
    return doc.data();
  }

  Future<void> saveActivePetSelection({
    required String familyId,
    required String petId,
  }) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No hay sesión activa.',
      );
    }

    await _usersCollection.doc(uid).set({
      'active_family_id': familyId,
      'active_pet_id': petId,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> _resolveEmailFromIdentifier(String usernameOrEmail) async {
    final identifier = usernameOrEmail.trim();

    if (identifier.isEmpty) {
      return null;
    }

    if (identifier.contains('@')) {
      return identifier.toLowerCase();
    }

    final usernameDoc =
        await _usernamesCollection.doc(identifier.toLowerCase()).get();

    if (!usernameDoc.exists) {
      return null;
    }

    return usernameDoc.data()?['email'] as String?;
  }

  String getReadableAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'user-not-found':
        return 'No existe una cuenta con esos datos.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Usuario o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta de nuevo más tarde.';
      case 'requires-recent-login':
        return 'Vuelve a iniciar sesión y repite la operación.';
      case 'username-already-in-use':
        return 'Ese nombre de usuario ya está en uso.';
      default:
        return error.message ?? 'Ocurrió un error de autenticación.';
    }
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}