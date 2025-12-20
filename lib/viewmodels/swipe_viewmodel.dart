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

  List<Movie> _movies = [];
  List<Movie> _tvShows = [];

  List<Movie> _likedMovies = [];
  List<Movie> _likedTVShows = [];

  final Set<String> _swipedIds = {}; // IDs vi redan swipat på
  final Set<String> _likedIds = {};

  bool _isLoading = false;
  bool _isLoadingLiked = false;
  String? _error;

  String? _currentUserId;
  MediaType _currentMediaType = MediaType.movies;
  String? _selectedGenre;

  // Getters
  MediaType get currentMediaType => _currentMediaType;
  String? get selectedGenre => _selectedGenre;

  List<Movie> get currentList => _currentMediaType == MediaType.movies ? _movies : _tvShows;

  // Filtrerad lista - exkluderar swipade och applicerar genre-filter
  List<Movie> get _filteredList {
    var list = currentList.where((m) => !_swipedIds.contains(m.uniqueId)).toList();
    
    if (_selectedGenre != null) {
      // Special hantering för Arabic och Turkish (språk, inte genre)
      if (_selectedGenre == 'Arabic') {
        list = list.where((m) => m.originalLanguage == 'ar').toList();
      } else if (_selectedGenre == 'Turkish') {
        list = list.where((m) => m.originalLanguage == 'tr').toList();
      } else {
        list = list.where((m) => m.genres.contains(_selectedGenre)).toList();
      }
    }
    
    return list;
  }

  Movie? get currentItem => _filteredList.isNotEmpty ? _filteredList.first : null;
  Movie? get nextItem => _filteredList.length > 1 ? _filteredList[1] : null;

  List<Movie> get likedMovies => _likedMovies;
  List<Movie> get likedTVShows => _likedTVShows;

  int get likedMoviesCount => _likedMovies.length;
  int get likedTVShowsCount => _likedTVShows.length;
  int get totalLikedCount => _likedMovies.length + _likedTVShows.length;

  bool get hasItems => currentItem != null;
  bool get isLoading => _isLoading;
  bool get isLoadingLiked => _isLoadingLiked;
  String? get error => _error;

  void setGenreFilter(String? genre) {
    _selectedGenre = genre;
    notifyListeners();

    // Ladda fler om vi inte har tillräckligt
    if (_filteredList.length < 5 && !_isLoading) {
      loadItems();
    }
  }

  void setMediaType(MediaType type) {
    if (_currentMediaType != type) {
      _currentMediaType = type;
      _selectedGenre = null;
      notifyListeners();

      if (currentList.isEmpty && !_isLoading) {
        loadItems();
      }
    }
  }

  Future<void> setUser(String userId, List<String> savedLikedIds) async {
    _currentUserId = userId;
    _likedIds.addAll(savedLikedIds);
    _swipedIds.addAll(savedLikedIds); // Markera redan likade som swipade

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

  Future<void> loadItems({bool reset = false}) async {
    if (_isLoading) return;

    if (reset) {
      if (_currentMediaType == MediaType.movies) {
        _movies.clear();
      } else {
        _tvShows.clear();
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

      // Filtrera bort items utan poster
      final validItems = newItems.where((item) => item.posterUrl.isNotEmpty).toList();

      // Shuffle
      validItems.shuffle(Random(DateTime.now().millisecondsSinceEpoch));

      if (_currentMediaType == MediaType.movies) {
        _movies.addAll(validItems);
      } else {
        _tvShows.addAll(validItems);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Could not load content. Check your internet connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> swipeRight() async {
    final item = currentItem;
    if (item == null) return;

    // Markera som swipad
    _swipedIds.add(item.uniqueId);

    // Lägg till i likes om inte redan där
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

    notifyListeners();
    _checkAndLoadMore();
  }

  void swipeLeft() {
    final item = currentItem;
    if (item == null) return;

    // Markera som swipad
    _swipedIds.add(item.uniqueId);

    notifyListeners();
    _checkAndLoadMore();
  }

  void _checkAndLoadMore() {
    // Ladda fler om vi har få kvar
    if (_filteredList.length < 5 && !_isLoading) {
      loadItems();
    }
  }

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
    _movies.clear();
    _tvShows.clear();
    _swipedIds.clear();
    _likedMovies.clear();
    _likedTVShows.clear();
    _likedIds.clear();
    _currentUserId = null;
    _error = null;
    _currentMediaType = MediaType.movies;
    _selectedGenre = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}