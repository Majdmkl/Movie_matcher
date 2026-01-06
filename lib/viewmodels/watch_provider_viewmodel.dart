import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../use_cases/watch_provider_use_case.dart';

class WatchProviderViewModel extends ChangeNotifier {
  final WatchProviderUseCase _useCase;

  Map<String, List<WatchProvider>> _providers = {
    'stream': [],
    'rent': [],
    'buy': [],
  };
  bool _isLoading = false;
  String? _error;

  WatchProviderViewModel({WatchProviderUseCase? useCase})
      : _useCase = useCase ?? WatchProviderUseCase();

  List<WatchProvider> get streamingProviders => _providers['stream'] ?? [];
  List<WatchProvider> get rentProviders => _providers['rent'] ?? [];
  List<WatchProvider> get buyProviders => _providers['buy'] ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProviders => _useCase.hasProviders(_providers);

  Future<void> loadProviders(Movie movie, {String region = 'SE'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _providers = await _useCase.loadProvidersForItem(
        movie: movie,
        region: region,
      );

      print('✅ Loaded ${streamingProviders.length} streaming providers');
    } catch (e) {
      _error = 'Failed to load watch providers';
      print('❌ Error loading providers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _providers = {'stream': [], 'rent': [], 'buy': []};
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}