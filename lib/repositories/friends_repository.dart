import '../models/user.dart';
import '../services/auth_service.dart';

class FriendsRepository {
  final AuthService _authService;

  FriendsRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

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
}