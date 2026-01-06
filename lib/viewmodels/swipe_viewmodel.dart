import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../use_cases/swipe_use_case.dart';

export '../use_cases/swipe_use_case.dart' show MediaType;

class SwipeViewModel extends ChangeNotifier {
  final SwipeUseCase _useCase;

  List<Movie> _movies = [];
  List<Movie> _tvShows = [];
  List<Movie> _likedMovies = [];
  List<Movie> _likedTVShows = [];

  final Set<String> _swipedIds = {};
  final Set<String> _likedIds = {};

  bool _isLoading = false;
  bool _isLoadingLiked = false;
  String? _error;
  String? _currentUserId;
  MediaType _currentMediaType = MediaType.movies;
  String? _selectedGenre;

  SwipeViewModel({SwipeUseCase? useCase})
      : _useCase = useCase ?? SwipeUseCase();

  MediaType get currentMediaType => _currentMediaType;
  String? get selectedGenre => _selectedGenre;
  List<Movie> get currentList => _currentMediaType == MediaType.movies ? _movies : _tvShows;
  List<Movie> get likedMovies => _likedMovies;
  List<Movie> get likedTVShows => _likedTVShows;
  int get likedMoviesCount => _likedMovies.length;
  int get likedTVShowsCount => _likedTVShows.length;
  int get totalLikedCount => _likedMovies.length + _likedTVShows.length;
  bool get isLoading => _isLoading;
  bool get isLoadingLiked => _isLoadingLiked;
  String? get error => _error;

  List<Movie> get _filteredList {
    return _useCase.filterItems(
      items: currentList,
      swipedIds: _swipedIds,
      selectedGenre: _selectedGenre,
    );
  }

  Movie? get currentItem => _filteredList.isNotEmpty ? _filteredList.first : null;
  Movie? get nextItem => _filteredList.length > 1 ? _filteredList[1] : null;
  bool get hasItems => currentItem != null;

  void setGenreFilter(String? genre) {
    _selectedGenre = genre;
    notifyListeners();

    if (_useCase.shouldLoadMore(_filteredList.length) && !_isLoading) {
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
    _swipedIds.addAll(savedLikedIds);

    if (savedLikedIds.isNotEmpty) {
      await _loadLikedItems(savedLikedIds);
    }
  }

  Future<void> _loadLikedItems(List<String> uniqueIds) async {
    _isLoadingLiked = true;
    notifyListeners();

    try {
      final result = await _useCase.loadLikedItems(uniqueIds);
      _likedMovies = result['movies'] ?? [];
      _likedTVShows = result['tvShows'] ?? [];
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
      final newItems = await _useCase.loadContent(_currentMediaType);

      if (_currentMediaType == MediaType.movies) {
        _movies.addAll(newItems);
      } else {
        _tvShows.addAll(newItems);
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

    _swipedIds.add(item.uniqueId);

    if (!_likedIds.contains(item.uniqueId)) {
      _likedIds.add(item.uniqueId);

      if (item.mediaType == 'movie') {
        _likedMovies.add(item);
      } else {
        _likedTVShows.add(item);
      }

      if (_currentUserId != null) {
        _useCase.processLike(
          userId: _currentUserId!,
          item: item,
          likedIds: _likedIds,
        );
      }
    }

    notifyListeners();
    _checkAndLoadMore();
  }

  void swipeLeft() {
    final item = currentItem;
    if (item == null) return;

    _swipedIds.add(item.uniqueId);
    notifyListeners();
    _checkAndLoadMore();
  }

  void _checkAndLoadMore() {
    if (_useCase.shouldLoadMore(_filteredList.length) && !_isLoading) {
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
      _useCase.processRemoveLike(
        userId: _currentUserId!,
        item: item,
      );
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