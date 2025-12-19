import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/auth_service.dart';

class SwipeViewModel extends ChangeNotifier {
  final TMDBService _tmdbService = TMDBService();
  final AuthService _authService = AuthService();

  List<Movie> _movies = [];
  int _currentIndex = 0;
  final List<Movie> _likedMovies = [];
  final Set<int> _seenMovieIds = {};
  final Set<int> _likedMovieIds = {}; // För att undvika dubletter

  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  String? _currentUserId;

  // Getters
  List<Movie> get movies => _movies;
  Movie? get currentMovie => _currentIndex < _movies.length ? _movies[_currentIndex] : null;
  List<Movie> get likedMovies => _likedMovies;
  int get likedCount => _likedMovies.length;
  bool get hasMovies => _currentIndex < _movies.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setUser(String userId) {
    _currentUserId = userId;
  }

  Future<void> loadMovies({bool reset = false}) async {
    if (_isLoading) return;

    if (reset) {
      _currentPage = 1;
      _movies.clear();
      _currentIndex = 0;
      _hasMorePages = true;
      _seenMovieIds.clear();
      _likedMovies.clear();
      _likedMovieIds.clear();
    }

    if (!_hasMorePages) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newMovies = await _tmdbService.getPopularMovies(page: _currentPage);

      final filteredMovies = newMovies.where((movie) {
        return !_seenMovieIds.contains(movie.id) && movie.posterUrl.isNotEmpty;
      }).toList();

      for (var movie in filteredMovies) {
        _seenMovieIds.add(movie.id);
      }

      _movies.addAll(filteredMovies);
      _currentPage++;

      if (newMovies.isEmpty) {
        _hasMorePages = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Could not load movies. Check your internet connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Swipe höger (gilla) - FIXAT: går alltid till nästa film
  Future<void> swipeRight() async {
    if (currentMovie == null) return;

    final movie = currentMovie!;

    // Undvik dubletter
    if (!_likedMovieIds.contains(movie.id)) {
      _likedMovieIds.add(movie.id);
      _likedMovies.add(movie);

      // Spara till Firebase
      if (_currentUserId != null) {
        _authService.addLikedMovie(_currentUserId!, movie.id);
      }
    }

    // GÅ TILL NÄSTA FILM
    _moveToNext();
  }

  // Swipe vänster (ogilla) - går till nästa film
  void swipeLeft() {
    if (currentMovie == null) return;
    _moveToNext();
  }

  void _moveToNext() {
    _currentIndex++;
    notifyListeners();

    // Ladda fler filmer om vi närmar oss slutet
    if (_currentIndex >= _movies.length - 3 && !_isLoading && _hasMorePages) {
      loadMovies();
    }
  }

  void reset() {
    _currentIndex = 0;
    _likedMovies.clear();
    _likedMovieIds.clear();
    _movies.clear();
    _seenMovieIds.clear();
    _currentPage = 1;
    _hasMorePages = true;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}