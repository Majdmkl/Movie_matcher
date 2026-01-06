import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../use_cases/auth_use_case.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthUseCase _useCase;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  List<AppUser> _friends = [];
  bool _isLoadingFriends = false;

  AuthViewModel({AuthUseCase? useCase})
      : _useCase = useCase ?? AuthUseCase();

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  List<AppUser> get friends => _friends;
  bool get isLoadingFriends => _isLoadingFriends;
  int get likedCount => _currentUser?.likedMovieIds.length ?? 0;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _useCase.initializeSession();

      if (_currentUser != null && _currentUser!.friendIds.isNotEmpty) {
        await loadFriends();
      }

      print('✅ User restored: ${_currentUser?.email}');
    } catch (e) {
      print('❌ Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _useCase.registerUser(
        email: email,
        password: password,
        name: name,
      );

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _useCase.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _useCase.loginUser(
        email: email,
        password: password,
      );

      if (_currentUser != null && _currentUser!.friendIds.isNotEmpty) {
        await loadFriends();
      }

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _useCase.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _useCase.logoutUser();
    _currentUser = null;
    _friends.clear();
    notifyListeners();
  }

  void addLikedItem(String uniqueId) {
    if (_currentUser == null) return;

    if (!_currentUser!.likedMovieIds.contains(uniqueId)) {
      final updatedLikes = List<String>.from(_currentUser!.likedMovieIds)..add(uniqueId);
      _currentUser = _currentUser!.copyWith(likedMovieIds: updatedLikes);
      notifyListeners();
    }
  }

  void updateName(String newName) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(name: newName);
    notifyListeners();

    _useCase.updateUserName(_currentUser!.id, newName);
  }

  Future<void> loadFriends() async {
    if (_currentUser == null) return;

    _isLoadingFriends = true;
    notifyListeners();

    try {
      _friends = await _useCase.loadFriends(_currentUser!.friendIds);
      print('✅ Loaded ${_friends.length} friends');
    } catch (e) {
      print('❌ Error loading friends: $e');
    }

    _isLoadingFriends = false;
    notifyListeners();
  }

  Future<AppUser?> searchUser(String email) async {
    if (email.trim().isEmpty) return null;
    return await _useCase.searchUser(email);
  }

  Future<bool> addFriend(AppUser friend) async {
    if (_currentUser == null) return false;

    try {
      final success = await _useCase.addFriend(
        currentUser: _currentUser!,
        friendToAdd: friend,
      );

      if (success) {
        _currentUser = _useCase.updateUserWithNewFriend(_currentUser!, friend.id);
        _friends.add(friend);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFriend(String friendId) async {
    if (_currentUser == null) return false;

    final success = await _useCase.removeFriend(_currentUser!.id, friendId);

    if (success) {
      _currentUser = _useCase.updateUserWithRemovedFriend(_currentUser!, friendId);
      _friends.removeWhere((f) => f.id == friendId);
      notifyListeners();
    }

    return success;
  }

  Future<AppUser?> getFriendDetails(String friendId) async {
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}