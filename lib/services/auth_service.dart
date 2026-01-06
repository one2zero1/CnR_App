import 'dart:async';
import '../models/user_model.dart';

abstract class AuthService {
  Future<UserModel> signInAnonymously(String nickname);
  Future<void> signOut();
  Stream<UserModel?> get userStream;
  UserModel? get currentUser;
}

class MockAuthService implements AuthService {
  UserModel? _currentUser;
  final _userController = StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> get userStream => _userController.stream;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> signInAnonymously(String nickname) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Network delay simulation

    final newUser = UserModel(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      nickname: nickname,
      stats: UserStats(),
    );

    _currentUser = newUser;
    _userController.add(newUser);
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _userController.add(null);
  }
}
