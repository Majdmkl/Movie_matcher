import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Initiera - kolla om användare redan är inloggad
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await _storageService.getUserId();
      
      if (userId != null && userId.isNotEmpty) {
        // Försök hämta från Firebase med timeout
        try {
          _currentUser = await _userService.getUser(userId).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⚠️ Firebase timeout - using local data');
              return null;
            },
          );
          
          // Om Firebase inte hittade användaren, skapa lokal user
          if (_currentUser == null) {
            final userName = await _storageService.getUserName();
            if (userName != null) {
              _currentUser = User(
                id: userId,
                name: userName,
              );
            }
          }
        } catch (e) {
          print('⚠️ Could not fetch user from Firebase: $e');
          // Använd lokal data som fallback
          final userName = await _storageService.getUserName();
          if (userName != null) {
            _currentUser = User(
              id: userId,
              name: userName,
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Skapa ny användare
  Future<bool> createUser(String name) async {
    if (name.trim().isEmpty) {
      _error = 'Name cannot be empty';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      final newUser = User(
        id: userId,
        name: name.trim(),
        createdAt: DateTime.now(),
      );

      // Spara lokalt FÖRST (snabbt)
      await _storageService.saveUserId(userId);
      await _storageService.saveUserName(name.trim());

      // Sätt användare direkt så UI uppdateras
      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();

      // Spara till Firebase i bakgrunden (kan ta tid)
      _userService.createUser(newUser).then((_) {
        print('✅ User saved to Firebase');
      }).catchError((e) {
        print('⚠️ Could not save to Firebase (offline?): $e');
      });

      return true;
    } catch (e) {
      _error = 'Could not create user. Try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logga ut
  Future<void> logout() async {
    await _storageService.clearAll();
    _currentUser = null;
    notifyListeners();
  }

  // Uppdatera namn
  Future<void> updateName(String newName) async {
    if (_currentUser == null) return;

    try {
      await _storageService.saveUserName(newName);
      _currentUser = _currentUser!.copyWith(name: newName);
      notifyListeners();

      // Uppdatera Firebase i bakgrunden
      _userService.updateUserName(_currentUser!.id, newName).catchError((e) {
        print('⚠️ Could not update name in Firebase: $e');
      });
    } catch (e) {
      _error = 'Could not update name';
      notifyListeners();
    }
  }

  // Lägg till liked movie
  Future<void> addLikedMovie(int movieId) async {
    if (_currentUser == null) return;

    final updatedLikes = List<int>.from(_currentUser!.likedMovieIds)..add(movieId);
    _currentUser = _currentUser!.copyWith(likedMovieIds: updatedLikes);
    notifyListeners();

    // Spara till Firebase i bakgrunden
    _userService.addLikedMovie(_currentUser!.id, movieId).catchError((e) {
      print('⚠️ Could not save like to Firebase: $e');
    });
  }

  int get likedCount => _currentUser?.likedMovieIds.length ?? 0;

  void clearError() {
    _error = null;
    notifyListeners();
  }
}