import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Initiera - kolla om användare redan är inloggad
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentFirebaseUser;
      
      if (firebaseUser != null) {
        _currentUser = await _authService.getUser(firebaseUser.uid);
        print('✅ User restored: ${_currentUser?.email}');
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Registrera ny användare
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
    notifyListeners();
  }

  // Lägg till liked movie
  Future<void> addLikedMovie(int movieId) async {
    if (_currentUser == null) return;

    // Uppdatera lokalt först
    if (!_currentUser!.likedMovieIds.contains(movieId)) {
      final updatedLikes = List<int>.from(_currentUser!.likedMovieIds)..add(movieId);
      _currentUser = _currentUser!.copyWith(likedMovieIds: updatedLikes);
      notifyListeners();

      // Spara till Firebase
      await _authService.addLikedMovie(_currentUser!.id, movieId);
    }
  }

  // Uppdatera namn
  Future<void> updateName(String newName) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(name: newName);
    notifyListeners();

    await _authService.updateName(_currentUser!.id, newName);
  }

  int get likedCount => _currentUser?.likedMovieIds.length ?? 0;

  void clearError() {
    _error = null;
    notifyListeners();
  }
}