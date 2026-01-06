import '../services/tmdb_service.dart';

class WatchProviderRepository {
  final TMDBService _tmdbService;

  WatchProviderRepository({TMDBService? tmdbService})
      : _tmdbService = tmdbService ?? TMDBService();

  Future<List<WatchProvider>> getMovieProviders(
      int movieId, {
        String region = 'SE',
      }) async {
    return await _tmdbService.getMovieWatchProviders(movieId, region: region);
  }

  Future<List<WatchProvider>> getTVProviders(
      int tvId, {
        String region = 'SE',
      }) async {
    return await _tmdbService.getTVWatchProviders(tvId, region: region);
  }
}