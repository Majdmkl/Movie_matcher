import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/auth_service.dart';

enum MediaType { movies, tvShows }

class SwipeRepository {
  final TMDBService _tmdbService;
  final AuthService _authService;

  SwipeRepository({
    TMDBService? tmdbService,
    AuthService? authService,
  })  : _tmdbService = tmdbService ?? TMDBService(),
        _authService = authService ?? AuthService();

  /// Fetch movies from TMDB
  Future<List<Movie>> fetchMovies() async {
    return await _tmdbService.getPopularMovies();
  }

  /// Fetch TV shows from TMDB
  Future<List<Movie>> fetchTVShows() async {
    return await _tmdbService.getPopularTVShows();
  }

  /// Load liked items by their unique IDs
  Future<List<Movie>> loadLikedItems(List<String> uniqueIds) async {
    if (uniqueIds.isEmpty) return [];
    return await _tmdbService.getItemsByUniqueIds(uniqueIds);
  }

  /// Save liked item to Firebase
  void saveLikedItem(String userId, String uniqueId) {
    _authService.addLikedItem(userId, uniqueId);
  }

  /// Remove liked item from Firebase
  void removeLikedItem(String userId, String uniqueId) {
    _authService.removeLikedItem(userId, uniqueId);
  }
}