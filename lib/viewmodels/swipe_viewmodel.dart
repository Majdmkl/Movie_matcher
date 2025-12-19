import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/auth_service.dart';

enum MediaType { movies, tvShows }

class SwipeViewModel extends ChangeNotifier {
  final TMDBService _tmdbService = TMDBService();
  final AuthService _authService = AuthService();
  final Random _random = Random();

  // Separata listor för filmer och serier
  List<Movie> _movies = [];
  List<Movie> _tvShows = [];

  int _movieIndex = 0;
  int _tvIndex = 0;

  List<Movie> _likedMovies = [];
  List<Movie> _likedTVShows = [];

  final Set<String> _seenIds = {};
  final Set<String> _likedIds = {};

  bool _isLoading = false;
  bool _isLoadingLiked = false;
  String? _error;

  String? _currentUserId;
  MediaType _currentMediaType = MediaType.movies;

  // Getters
  MediaType get currentMediaType => _currentMediaType;
  
  List<Movie> get currentList => _currentMediaType == MediaType.movies ? _movies : _tvShows;
  int get currentIndex => _currentMediaType == MediaType.movies ? _movieIndex : _tvIndex;
  
  Movie? get currentItem => currentIndex < currentList.length ? currentList[currentIndex] : null;
  
  List<Movie> get likedMovies => _likedMovies;
  List<Movie> get likedTVShows => _likedTVShows;
  
  int get likedMoviesCount => _likedMovies.length;
  int get likedTVShowsCount => _likedTVShows.length;
  int get totalLikedCount => _likedMovies.length + _likedTVShows.length;

  bool get hasItems => currentIndex < currentList.length;
  bool get isLoading => _isLoading;
  bool get isLoadingLiked => _isLoadingLiked;
  String? get error => _error;

  // Byt mellan filmer och serier
  void setMediaType(MediaType type) {
    if (_currentMediaType != type) {
      _currentMediaType = type;
      notifyListeners();

      // Ladda om det behövs
      if (currentList.isEmpty && !_isLoading) {
        loadItems();
      }
    }
  }

  // Sätt användare och ladda sparade likes
  Future<void> setUser(String userId, List<String> savedLikedIds) async {
    _currentUserId = userId;
    _likedIds.addAll(savedLikedIds);

    if (savedLikedIds.isNotEmpty) {
      await _loadLikedItems(savedLikedIds);
    }
  }

  Future<void> _loadLikedItems(List<String> uniqueIds) async {
    _isLoadingLiked = true;
    notifyListeners();

    try {
      final items = await _tmdbService.getItemsByUniqueIds(uniqueIds);

      _likedMovies = items.where((m) => m.mediaType == 'movie').toList();
      _likedTVShows = items.where((m) => m.mediaType == 'tv').toList();

      print('✅ Loaded ${_likedMovies.length} movies and ${_likedTVShows.length} TV shows');
    } catch (e) {
      print('❌ Error loading liked items: $e');
    }

    _isLoadingLiked = false;
    notifyListeners();
  }

  // Ladda items
  Future<void> loadItems({bool reset = false}) async {
    if (_isLoading) return;

    if (reset) {
      if (_currentMediaType == MediaType.movies) {
        _movies.clear();
        _movieIndex = 0;
      } else {
        _tvShows.clear();
        _tvIndex = 0;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<Movie> newItems;

      if (_currentMediaType == MediaType.movies) {
        newItems = await _tmdbService.getPopularMovies();
      } else {
        newItems = await _tmdbService.getPopularTVShows();
      }

      // Filtrera bort sedda och redan likade
      final filteredItems = newItems.where((item) {
        return !_seenIds.contains(item.uniqueId) &&
            !_likedIds.contains(item.uniqueId) &&
            item.posterUrl.isNotEmpty;
      }).toList();

      for (var item in filteredItems) {
        _seenIds.add(item.uniqueId);
      }

      // Extra shuffle
      filteredItems.shuffle(_random);

      if (_currentMediaType == MediaType.movies) {
        _movies.addAll(filteredItems);
      } else {
        _tvShows.addAll(filteredItems);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Could not load content. Check your internet connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Swipe höger (gilla)
  Future<void> swipeRight() async {
    if (currentItem == null) return;

    final item = currentItem!;

    if (!_likedIds.contains(item.uniqueId)) {
      _likedIds.add(item.uniqueId);

      if (item.mediaType == 'movie') {
        _likedMovies.add(item);
      } else {
        _likedTVShows.add(item);
      }

      if (_currentUserId != null) {
        _authService.addLikedItem(_currentUserId!, item.uniqueId);
      }
    }

    _moveToNext();
  }

  // Swipe vänster (ogilla)
  void swipeLeft() {
    if (currentItem == null) return;
    _moveToNext();
  }

  void _moveToNext() {
    if (_currentMediaType == MediaType.movies) {
      _movieIndex++;
    } else {
      _tvIndex++;
    }
    notifyListeners();

    // Ladda fler om vi närmar oss slutet
    if (currentIndex >= currentList.length - 5 && !_isLoading) {
      loadItems();
    }
  }

  // Ta bort liked
  Future<void> removeLikedItem(Movie item) async {
    if (item.mediaType == 'movie') {
      _likedMovies.removeWhere((m) => m.uniqueId == item.uniqueId);
    } else {
      _likedTVShows.removeWhere((m) => m.uniqueId == item.uniqueId);
    }
    _likedIds.remove(item.uniqueId);

    if (_currentUserId != null) {
      _authService.removeLikedItem(_currentUserId!, item.uniqueId);
    }

    notifyListeners();
  }

  void reset() {
    _movieIndex = 0;
    _tvIndex = 0;
    _movies.clear();
    _tvShows.clear();
    _seenIds.clear();
    _likedMovies.clear();
    _likedTVShows.clear();
    _likedIds.clear();
    _currentUserId = null;
    _error = null;
    _currentMediaType = MediaType.movies;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}