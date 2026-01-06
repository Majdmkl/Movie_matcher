import '../models/user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  /// Get current Firebase user
  String? get currentUserId => _authService.currentFirebaseUser?.uid;

  /// Register new user
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

  /// Login existing user
  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    return await _authService.login(
      email: email,
      password: password,
    );
  }

  /// Logout current user
  Future<void> logout() async {
    await _authService.logout();
  }

  /// Get user by ID
  Future<AppUser?> getUser(String userId) async {
    return await _authService.getUser(userId);
  }

  /// Update user name
  void updateUserName(String userId, String newName) {
    _authService.updateName(userId, newName);
  }

  /// Search user by email
  Future<AppUser?> searchUserByEmail(String email) async {
    return await _authService.searchUserByEmail(email);
  }

  /// Add friend relationship
  Future<bool> addFriend(String userId, String friendId) async {
    return await _authService.addFriend(userId, friendId);
  }

  /// Remove friend relationship
  Future<bool> removeFriend(String userId, String friendId) async {
    return await _authService.removeFriend(userId, friendId);
  }

  /// Get list of friends
  Future<List<AppUser>> getFriends(List<String> friendIds) async {
    return await _authService.getFriends(friendIds);
  }

  /// Get error message from FirebaseAuthException
  String getErrorMessage(dynamic error) {
    return _authService.getErrorMessage(error);
  }
}