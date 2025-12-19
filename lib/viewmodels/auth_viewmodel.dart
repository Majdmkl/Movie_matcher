import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  // Friends
  List<AppUser> _friends = [];
  bool _isLoadingFriends = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  
  List<AppUser> get friends => _friends;
  bool get isLoadingFriends => _isLoadingFriends;

  // Initiera
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentFirebaseUser;
      
      if (firebaseUser != null) {
        _currentUser = await _authService.getUser(firebaseUser.uid);
        
        // Ladda vänner
        if (_currentUser != null && _currentUser!.friendIds.isNotEmpty) {
          await loadFriends();
        }
        
        print('✅ User restored: ${_currentUser?.email}');
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Registrera
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        name: name,
      );

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _authService.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Could not create account. Try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logga in
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );

      // Ladda vänner efter inloggning
      if (_currentUser != null && _currentUser!.friendIds.isNotEmpty) {
        await loadFriends();
      }

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _authService.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Could not login. Try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logga ut
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _friends.clear();
    notifyListeners();
  }

  // Lägg till liked movie
  void addLikedMovie(int movieId) {
    if (_currentUser == null) return;

    if (!_currentUser!.likedMovieIds.contains(movieId)) {
      final updatedLikes = List<int>.from(_currentUser!.likedMovieIds)..add(movieId);
      _currentUser = _currentUser!.copyWith(likedMovieIds: updatedLikes);
      notifyListeners();

      _authService.addLikedMovie(_currentUser!.id, movieId);
    }
  }

  // Uppdatera namn
  void updateName(String newName) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(name: newName);
    notifyListeners();

    _authService.updateName(_currentUser!.id, newName);
  }

  // === FRIENDS ===

  // Ladda vänner
  Future<void> loadFriends() async {
    if (_currentUser == null) return;

    _isLoadingFriends = true;
    notifyListeners();

    try {
      _friends = await _authService.getFriends(_currentUser!.friendIds);
      print('✅ Loaded ${_friends.length} friends');
    } catch (e) {
      print('❌ Error loading friends: $e');
    }

    _isLoadingFriends = false;
    notifyListeners();
  }

  // Sök användare
  Future<AppUser?> searchUser(String email) async {
    if (email.trim().isEmpty) return null;
    return await _authService.searchUserByEmail(email);
  }

  // Lägg till vän
  Future<bool> addFriend(AppUser friend) async {
    if (_currentUser == null) return false;
    if (_currentUser!.id == friend.id) return false; // Kan inte lägga till sig själv
    if (_currentUser!.friendIds.contains(friend.id)) return false; // Redan vän

    final success = await _authService.addFriend(_currentUser!.id, friend.id);

    if (success) {
      final updatedFriendIds = List<String>.from(_currentUser!.friendIds)..add(friend.id);
      _currentUser = _currentUser!.copyWith(friendIds: updatedFriendIds);
      _friends.add(friend);
      notifyListeners();
    }

    return success;
  }

  // Ta bort vän
  Future<bool> removeFriend(String friendId) async {
    if (_currentUser == null) return false;

    final success = await _authService.removeFriend(_currentUser!.id, friendId);

    if (success) {
      final updatedFriendIds = List<String>.from(_currentUser!.friendIds)..remove(friendId);
      _currentUser = _currentUser!.copyWith(friendIds: updatedFriendIds);
      _friends.removeWhere((f) => f.id == friendId);
      notifyListeners();
    }

    return success;
  }

  // Hämta uppdaterad vändata (för att se deras senaste likes)
  Future<AppUser?> getFriendDetails(String friendId) async {
    return await _authService.getUser(friendId);
  }

  int get likedCount => _currentUser?.likedMovieIds.length ?? 0;

  void clearError() {
    _error = null;
    notifyListeners();
  }
}