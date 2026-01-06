import '../models/user.dart';
import '../repositories/auth_repository.dart';

class AuthUseCase {
  final AuthRepository _repository;

  AuthUseCase({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  /// Initialize and restore user session
  Future<AppUser?> initializeSession() async {
    final userId = _repository.currentUserId;
    if (userId != null) {
      return await _repository.getUser(userId);
    }
    return null;
  }

  /// Validate email format
  String? validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String password, {bool isRegistration = false}) {
    if (password.isEmpty) {
      return 'Please enter your password';
    }
    if (isRegistration && password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate name
  String? validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  /// Register new user with validation
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

  /// Login user with validation
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

  /// Logout current user
  Future<void> logoutUser() async {
    await _repository.logout();
  }

  /// Update user's display name with validation
  Future<void> updateUserName(String userId, String newName) async {
    final nameError = validateName(newName);
    if (nameError != null) throw Exception(nameError);

    _repository.updateUserName(userId, newName);
  }

  /// Load user's friends
  Future<List<AppUser>> loadFriends(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];
    return await _repository.getFriends(friendIds);
  }

  /// Search for user by email with validation
  Future<AppUser?> searchUser(String email) async {
    if (email.trim().isEmpty) return null;

    final emailError = validateEmail(email);
    if (emailError != null) return null;

    return await _repository.searchUserByEmail(email);
  }

  /// Validate and add friend
  Future<bool> addFriend({
    required AppUser currentUser,
    required AppUser friendToAdd,
  }) async {
    // Validation logic
    if (currentUser.id == friendToAdd.id) {
      throw Exception('You cannot add yourself as a friend');
    }

    if (currentUser.friendIds.contains(friendToAdd.id)) {
      throw Exception('Already friends with this user');
    }

    return await _repository.addFriend(currentUser.id, friendToAdd.id);
  }

  /// Remove friend
  Future<bool> removeFriend(String userId, String friendId) async {
    return await _repository.removeFriend(userId, friendId);
  }

  /// Update user object after friend is added
  AppUser updateUserWithNewFriend(AppUser currentUser, String friendId) {
    final updatedFriendIds = List<String>.from(currentUser.friendIds)..add(friendId);
    return currentUser.copyWith(friendIds: updatedFriendIds);
  }

  /// Update user object after friend is removed
  AppUser updateUserWithRemovedFriend(AppUser currentUser, String friendId) {
    final updatedFriendIds = List<String>.from(currentUser.friendIds)..remove(friendId);
    return currentUser.copyWith(friendIds: updatedFriendIds);
  }

  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    return _repository.getErrorMessage(error);
  }
}