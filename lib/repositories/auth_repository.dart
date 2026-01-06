import '../models/user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  String? get currentUserId => _authService.currentFirebaseUser?.uid;

  Future<AppUser?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _authService.register(
      email: email,
      password: password,
      name: name,
    );
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    return await _authService.login(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<AppUser?> getUser(String userId) async {
    return await _authService.getUser(userId);
  }

  void updateUserName(String userId, String newName) {
    _authService.updateName(userId, newName);
  }

  Future<AppUser?> searchUserByEmail(String email) async {
    return await _authService.searchUserByEmail(email);
  }

  Future<bool> addFriend(String userId, String friendId) async {
    return await _authService.addFriend(userId, friendId);
  }

  Future<bool> removeFriend(String userId, String friendId) async {
    return await _authService.removeFriend(userId, friendId);
  }

  Future<List<AppUser>> getFriends(List<String> friendIds) async {
    return await _authService.getFriends(friendIds);
  }

  String getErrorMessage(dynamic error) {
    return _authService.getErrorMessage(error);
  }
}