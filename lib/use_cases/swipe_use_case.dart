import 'dart:math';
import '../models/movie.dart';
import '../repositories/swipe_repository.dart';

enum MediaType { movies, tvShows }

class SwipeUseCase {
  final SwipeRepository _repository;
  final Random _random = Random();

  SwipeUseCase({SwipeRepository? repository})
      : _repository = repository ?? SwipeRepository();

  List<Movie> filterItems({
    required List<Movie> items,
    required Set<String> swipedIds,
    String? selectedGenre,
  }) {
    var filtered = items.where((m) => !swipedIds.contains(m.uniqueId)).toList();

    if (selectedGenre != null) {
      if (selectedGenre == 'Arabic') {
        filtered = filtered.where((m) => m.originalLanguage == 'ar').toList();
      } else if (selectedGenre == 'Turkish') {
        filtered = filtered.where((m) => m.originalLanguage == 'tr').toList();
      } else {
        filtered = filtered.where((m) => m.genres.contains(selectedGenre)).toList();
      }
    }

    return filtered;
  }

  Future<List<Movie>> loadContent(MediaType mediaType) async {
    List<Movie> newItems;

    if (mediaType == MediaType.movies) {
      newItems = await _repository.fetchMovies();
    } else {
      newItems = await _repository.fetchTVShows();
    }

    final validItems = newItems.where((item) => item.posterUrl.isNotEmpty).toList();

    validItems.shuffle(Random(DateTime.now().millisecondsSinceEpoch));

    return validItems;
  }

  Future<Map<String, List<Movie>>> loadLikedItems(List<String> uniqueIds) async {
    if (uniqueIds.isEmpty) {
      return {'movies': [], 'tvShows': []};
    }

    final items = await _repository.loadLikedItems(uniqueIds);
    final movies = items.where((m) => m.mediaType == 'movie').toList();
    final tvShows = items.where((m) => m.mediaType == 'tv').toList();

    return {'movies': movies, 'tvShows': tvShows};
  }

  Future<void> processLike({
    required String userId,
    required Movie item,
    required Set<String> likedIds,
  }) async {
    print('🔵 SwipeUseCase.processLike: ${item.uniqueId}');

    if (!likedIds.contains(item.uniqueId)) {
      print('⚠️ processLike called but item not in likedIds set');
    }

    await _repository.saveLikedItem(userId, item.uniqueId);
    print('✅ SwipeUseCase.processLike completed');
  }

  Future<void> processRemoveLike({
    required String userId,
    required Movie item,
  }) async {
    print('🔵 SwipeUseCase.processRemoveLike: ${item.uniqueId}');

    await _repository.removeLikedItem(userId, item.uniqueId);
    print('✅ SwipeUseCase.processRemoveLike completed');
  }

  bool shouldLoadMore(int remainingItems, {int threshold = 5}) {
    return remainingItems < threshold;
  }

  Map<String, List<Movie>> separateByMediaType(List<Movie> items) {
    return {
      'movies': items.where((m) => m.mediaType == 'movie').toList(),
      'tvShows': items.where((m) => m.mediaType == 'tv').toList(),
    };
  }
}