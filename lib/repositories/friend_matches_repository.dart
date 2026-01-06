import '../models/movie.dart';
import '../models/user.dart';
import '../services/tmdb_service.dart';
import '../services/auth_service.dart';

class FriendMatchesRepository {
  final TMDBService _tmdbService;
  final AuthService _authService;

  FriendMatchesRepository({
    TMDBService? tmdbService,
    AuthService? authService,
  })  : _tmdbService = tmdbService ?? TMDBService(),
        _authService = authService ?? AuthService();

  Future<AppUser?> getFriendDetails(String friendId) async {
    return await _authService.getUser(friendId);
  }

  Future<List<Movie>> loadFriendItems(List<String> uniqueIds) async {
    if (uniqueIds.isEmpty) return [];
    return await _tmdbService.getItemsByUniqueIds(uniqueIds);
  }
}