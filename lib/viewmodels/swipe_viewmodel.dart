import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/auth_service.dart';

class SwipeViewModel extends ChangeNotifier {
  final TMDBService _tmdbService = TMDBService();
  final AuthService _authService = AuthService();

  List<Movie> _movies = [];
  int _currentIndex = 0;
  List<Movie> _likedMovies = [];
  final Set<int> _seenMovieIds = {};
  final Set<int> _likedMovieIds = {};

  bool _isLoading = false;
  bool _isLoadingLikedMovies = false;
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
  bool get isLoadingLikedMovies => _isLoadingLikedMovies;
  String? get error => _error;

  // Sätt användare och ladda sparade likes
  Future<void> setUser(String userId, List<int> savedLikedMovieIds) async {
    _currentUserId = userId;
    _likedMovieIds.addAll(savedLikedMovieIds);
    
    if (savedLikedMovieIds.isNotEmpty) {
      await _loadLikedMoviesFromIds(savedLikedMovieIds);
    }
  }

  Future<void> _loadLikedMoviesFromIds(List<int> movieIds) async {
    _isLoadingLikedMovies = true;
    notifyListeners();

    try {
      final movies = await _tmdbService.getMoviesByIds(movieIds);
      _likedMovies = movies;
      print('✅ Loaded ${movies.length} liked movies from Firebase');
    } catch (e) {
      print('❌ Error loading liked movies: $e');
    }

    _isLoadingLikedMovies = false;
    notifyListeners();
  }

  Future<void> loadMovies({bool reset = false}) async {
    if (_isLoading) return;

    if (reset) {
      _currentPage = 1;
      _movies.clear();
      _currentIndex = 0;
      _hasMorePages = true;
      _seenMovieIds.clear();
    }

    if (!_hasMorePages) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newMovies = await _tmdbService.getPopularMovies(page: _currentPage);

      final filteredMovies = newMovies.where((movie) {
        return !_seenMovieIds.contains(movie.id) && 
               !_likedMovieIds.contains(movie.id) &&
               movie.posterUrl.isNotEmpty;
      }).toList();

      for (var movie in filteredMovies) {
        _seenMovieIds.add(movie.id);
      }

      // SHUFFLE!
      filteredMovies.shuffle(Random());

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

  Future<void> swipeRight() async {
    if (currentMovie == null) return;

    final movie = currentMovie!;

    if (!_likedMovieIds.contains(movie.id)) {
      _likedMovieIds.add(movie.id);
      _likedMovies.add(movie);

      if (_currentUserId != null) {
        _authService.addLikedMovie(_currentUserId!, movie.id);
      }
    }

    _moveToNext();
  }

  void swipeLeft() {
    if (currentMovie == null) return;
    _moveToNext();
  }

  void _moveToNext() {
    _currentIndex++;
    notifyListeners();

    if (_currentIndex >= _movies.length - 3 && !_isLoading && _hasMorePages) {
      loadMovies();
    }
  }

  Future<void> removeLikedMovie(int movieId) async {
    _likedMovies.removeWhere((m) => m.id == movieId);
    _likedMovieIds.remove(movieId);
    
    if (_currentUserId != null) {
      _authService.removeLikedMovie(_currentUserId!, movieId);
    }
    
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    _movies.clear();
    _seenMovieIds.clear();
    _currentPage = 1;
    _hasMorePages = true;
    _error = null;
    _likedMovies.clear();
    _likedMovieIds.clear();
    _currentUserId = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}