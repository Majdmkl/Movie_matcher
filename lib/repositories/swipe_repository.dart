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

  Future<List<Movie>> fetchMovies() async {
    return await _tmdbService.getPopularMovies();
  }

  Future<List<Movie>> fetchTVShows() async {
    return await _tmdbService.getPopularTVShows();
  }

  Future<List<Movie>> loadLikedItems(List<String> uniqueIds) async {
    if (uniqueIds.isEmpty) return [];
    return await _tmdbService.getItemsByUniqueIds(uniqueIds);
  }

  void saveLikedItem(String userId, String uniqueId) {
    _authService.addLikedItem(userId, uniqueId);
  }

  void removeLikedItem(String userId, String uniqueId) {
    _authService.removeLikedItem(userId, uniqueId);
  }
}