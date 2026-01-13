import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';

abstract class AuthService {
  Future<UserModel> signInAnonymously(String nickname);
  Future<void> updateProfile({required String nickname});
  Future<void> signOut();
  Stream<UserModel?> get userStream;
  UserModel? get currentUser;
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _logger = Logger();

  @override
  Stream<UserModel?> get userStream {
    return _auth.userChanges().map((User? firebaseUser) {
      if (firebaseUser == null) return null;
      return UserModel(
        uid: firebaseUser.uid,
        nickname: firebaseUser.displayName ?? 'Unknown',
      );
    });
  }

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(uid: user.uid, nickname: user.displayName ?? 'Unknown');
  }

  @override
  Future<UserModel> signInAnonymously(String nickname) async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(nickname);
        // Refresh token/user to ensure displayName is propagated locally if needed
        await user.reload();
        final updatedUser = _auth.currentUser;

        return UserModel(
          uid: updatedUser!.uid,
          nickname: updatedUser.displayName ?? nickname,
        );
      } else {
        throw Exception('Firebase signInAnonymously returned null user');
      }
    } catch (e) {
      _logger.e('Sign in failed', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({required String nickname}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(nickname);
        await user.reload();
      }
    } catch (e) {
      _logger.e('Update profile failed', error: e);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
