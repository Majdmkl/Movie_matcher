import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../repositories/watch_provider_repository.dart';

class WatchProviderUseCase {
  final WatchProviderRepository _repository;

  WatchProviderUseCase({WatchProviderRepository? repository})
      : _repository = repository ?? WatchProviderRepository();

  Future<Map<String, List<WatchProvider>>> loadProvidersForItem({
    required Movie movie,
    String region = 'SE',
  }) async {
    List<WatchProvider> providers;

    if (movie.mediaType == 'tv') {
      providers = await _repository.getTVProviders(movie.id, region: region);
    } else {
      providers = await _repository.getMovieProviders(movie.id, region: region);
    }

    final streaming = providers.where((p) => p.type == 'stream').toList();
    final rent = providers.where((p) => p.type == 'rent').toList();
    final buy = providers.where((p) => p.type == 'buy').toList();

    return {
      'stream': streaming,
      'rent': rent,
      'buy': buy,
    };
  }

  bool hasProviders(Map<String, List<WatchProvider>> providers) {
    return providers.values.any((list) => list.isNotEmpty);
  }
}