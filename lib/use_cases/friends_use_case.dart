import '../models/user.dart';
import '../repositories/friends_repository.dart';

enum FriendSearchError {
  notFound,
  cannotAddSelf,
  alreadyFriends,
  invalidEmail,
}

class FriendSearchResult {
  final AppUser? user;
  final FriendSearchError? error;
  final String? errorMessage;

  FriendSearchResult.success(this.user)
      : error = null,
        errorMessage = null;

  FriendSearchResult.failure(this.error, this.errorMessage)
      : user = null;

  bool get isSuccess => user != null;
  bool get hasError => error != null;
}

class FriendsUseCase {
  final FriendsRepository _repository;

  FriendsUseCase({FriendsRepository? repository})
      : _repository = repository ?? FriendsRepository();

  String? validateEmail(String email) {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return 'Please enter an email';
    }

    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      return 'Please enter a valid email';
    }

    return null;
  }

  Future<FriendSearchResult> searchAndValidateFriend({
    required String email,
    required AppUser currentUser,
  }) async {
    final emailError = validateEmail(email);
    if (emailError != null) {
      return FriendSearchResult.failure(
        FriendSearchError.invalidEmail,
        emailError,
      );
    }

    final user = await _repository.searchUserByEmail(email);

    if (user == null) {
      return FriendSearchResult.failure(
        FriendSearchError.notFound,
        'No user found with this email',
      );
    }

    if (user.id == currentUser.id) {
      return FriendSearchResult.failure(
        FriendSearchError.cannotAddSelf,
        'You cannot add yourself as a friend',
      );
    }

    if (currentUser.friendIds.contains(user.id)) {
      return FriendSearchResult.failure(
        FriendSearchError.alreadyFriends,
        'Already friends with this user',
      );
    }

    return FriendSearchResult.success(user);
  }

  Future<bool> addFriend({
    required AppUser currentUser,
    required AppUser friendToAdd,
  }) async {
    return await _repository.addFriend(currentUser.id, friendToAdd.id);
  }

  Future<bool> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    return await _repository.removeFriend(userId, friendId);
  }

  Future<List<AppUser>> loadFriends(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];
    return await _repository.getFriends(friendIds);
  }

  String getErrorMessage(FriendSearchError error) {
    switch (error) {
      case FriendSearchError.notFound:
        return 'No user found with this email';
      case FriendSearchError.cannotAddSelf:
        return 'You cannot add yourself';
      case FriendSearchError.alreadyFriends:
        return 'Already friends';
      case FriendSearchError.invalidEmail:
        return 'Invalid email address';
    }
  }
}