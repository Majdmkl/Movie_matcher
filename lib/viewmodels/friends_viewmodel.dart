import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../use_cases/friends_use_case.dart';

enum FriendSearchState {
  initial,
  searching,
  found,
  error,
}

class FriendsViewModel extends ChangeNotifier {
  final FriendsUseCase _useCase;

  List<AppUser> _friends = [];
  bool _isLoading = false;
  String? _error;

  FriendSearchState _searchState = FriendSearchState.initial;
  AppUser? _foundUser;
  String? _searchError;
  bool _isSearching = false;

  FriendsViewModel({FriendsUseCase? useCase})
      : _useCase = useCase ?? FriendsUseCase();

  List<AppUser> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFriends => _friends.isNotEmpty;

  FriendSearchState get searchState => _searchState;
  AppUser? get foundUser => _foundUser;
  String? get searchError => _searchError;
  bool get isSearching => _isSearching;

  Future<void> loadFriends(List<String> friendIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _friends = await _useCase.loadFriends(friendIds);
      print('✅ Loaded ${_friends.length} friends');
    } catch (e) {
      _error = 'Failed to load friends';
      print('❌ Error loading friends: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchFriend({
    required String email,
    required AppUser currentUser,
  }) async {
    _isSearching = true;
    _searchState = FriendSearchState.searching;
    _foundUser = null;
    _searchError = null;
    notifyListeners();

    try {
      final result = await _useCase.searchAndValidateFriend(
        email: email,
        currentUser: currentUser,
      );

      if (result.isSuccess) {
        _foundUser = result.user;
        _searchState = FriendSearchState.found;
        _searchError = null;
      } else {
        _searchState = FriendSearchState.error;
        _searchError = result.errorMessage;
        _foundUser = null;
      }
    } catch (e) {
      _searchState = FriendSearchState.error;
      _searchError = 'An error occurred';
      print('❌ Error searching friend: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<bool> addFriend({
    required AppUser currentUser,
    required AppUser friendToAdd,
  }) async {
    try {
      final success = await _useCase.addFriend(
        currentUser: currentUser,
        friendToAdd: friendToAdd,
      );

      if (success) {
        _friends.add(friendToAdd);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Failed to add friend';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      final success = await _useCase.removeFriend(
        userId: userId,
        friendId: friendId,
      );

      if (success) {
        _friends.removeWhere((f) => f.id == friendId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Failed to remove friend';
      notifyListeners();
      return false;
    }
  }

  void resetSearchDialog() {
    _searchState = FriendSearchState.initial;
    _foundUser = null;
    _searchError = null;
    _isSearching = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _friends = [];
    _isLoading = false;
    _error = null;
    resetSearchDialog();
    notifyListeners();
  }
}