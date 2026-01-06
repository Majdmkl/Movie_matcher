import '../models/user.dart';
import '../repositories/auth_repository.dart';

class AuthUseCase {
  final AuthRepository _repository;

  AuthUseCase({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  Future<AppUser?> initializeSession() async {
    final userId = _repository.currentUserId;
    if (userId != null) {
      return await _repository.getUser(userId);
    }
    return null;
  }

  String? validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String password, {bool isRegistration = false}) {
    if (password.isEmpty) {
      return 'Please enter your password';
    }
    if (isRegistration && password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    final emailError = validateEmail(email);
    if (emailError != null) throw Exception(emailError);

    final passwordError = validatePassword(password, isRegistration: true);
    if (passwordError != null) throw Exception(passwordError);

    final nameError = validateName(name);
    if (nameError != null) throw Exception(nameError);

    return await _repository.register(
      email: email,
      password: password,
      name: name,
    );
  }

  Future<AppUser?> loginUser({
    required String email,
    required String password,
  }) async {
    final emailError = validateEmail(email);
    if (emailError != null) throw Exception(emailError);

    final passwordError = validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);

    return await _repository.login(
      email: email,
      password: password,
    );
  }

  Future<void> logoutUser() async {
    await _repository.logout();
  }

  Future<void> updateUserName(String userId, String newName) async {
    final nameError = validateName(newName);
    if (nameError != null) throw Exception(nameError);

    _repository.updateUserName(userId, newName);
  }

  Future<List<AppUser>> loadFriends(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];
    return await _repository.getFriends(friendIds);
  }

  Future<AppUser?> searchUser(String email) async {
    if (email.trim().isEmpty) return null;

    final emailError = validateEmail(email);
    if (emailError != null) return null;

    return await _repository.searchUserByEmail(email);
  }

  Future<bool> addFriend({
    required AppUser currentUser,
    required AppUser friendToAdd,
  }) async {
    if (currentUser.id == friendToAdd.id) {
      throw Exception('You cannot add yourself as a friend');
    }

    if (currentUser.friendIds.contains(friendToAdd.id)) {
      throw Exception('Already friends with this user');
    }

    return await _repository.addFriend(currentUser.id, friendToAdd.id);
  }

  Future<bool> removeFriend(String userId, String friendId) async {
    return await _repository.removeFriend(userId, friendId);
  }

  AppUser updateUserWithNewFriend(AppUser currentUser, String friendId) {
    final updatedFriendIds = List<String>.from(currentUser.friendIds)..add(friendId);
    return currentUser.copyWith(friendIds: updatedFriendIds);
  }

  AppUser updateUserWithRemovedFriend(AppUser currentUser, String friendId) {
    final updatedFriendIds = List<String>.from(currentUser.friendIds)..remove(friendId);
    return currentUser.copyWith(friendIds: updatedFriendIds);
  }

  String getErrorMessage(dynamic error) {
    return _repository.getErrorMessage(error);
  }
}