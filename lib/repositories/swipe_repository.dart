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

  Future<void> saveLikedItem(String userId, String uniqueId) async {
    print('🔵 SwipeRepository.saveLikedItem: userId=$userId, uniqueId=$uniqueId');
    await _authService.addLikedItem(userId, uniqueId);
    print('✅ SwipeRepository.saveLikedItem completed');
  }

  Future<void> removeLikedItem(String userId, String uniqueId) async {
    print('🔵 SwipeRepository.removeLikedItem: userId=$userId, uniqueId=$uniqueId');
    await _authService.removeLikedItem(userId, uniqueId);
    print('✅ SwipeRepository.removeLikedItem completed');
  }
}