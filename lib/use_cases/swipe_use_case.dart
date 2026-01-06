import 'dart:math';
import '../models/movie.dart';
import '../repositories/swipe_repository.dart';

enum MediaType { movies, tvShows }

class SwipeUseCase {
  final SwipeRepository _repository;
  final Random _random = Random();

  SwipeUseCase({SwipeRepository? repository})
      : _repository = repository ?? SwipeRepository();

  /// Filter items based on swiped IDs and genre
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

  /// Load content based on media type
  Future<List<Movie>> loadContent(MediaType mediaType) async {
    List<Movie> newItems;

    if (mediaType == MediaType.movies) {
      newItems = await _repository.fetchMovies();
    } else {
      newItems = await _repository.fetchTVShows();
    }

    // Filter out items without posters
    final validItems = newItems.where((item) => item.posterUrl.isNotEmpty).toList();

    // Shuffle for variety
    validItems.shuffle(Random(DateTime.now().millisecondsSinceEpoch));

    return validItems;
  }

  /// Load liked items from IDs
  Future<Map<String, List<Movie>>> loadLikedItems(List<String> uniqueIds) async {
    if (uniqueIds.isEmpty) {
      return {'movies': [], 'tvShows': []};
    }

    final items = await _repository.loadLikedItems(uniqueIds);
    final movies = items.where((m) => m.mediaType == 'movie').toList();
    final tvShows = items.where((m) => m.mediaType == 'tv').toList();

    return {'movies': movies, 'tvShows': tvShows};
  }

  /// Process a like action
  void processLike({
    required String userId,
    required Movie item,
    required Set<String> likedIds,
  }) {
    if (!likedIds.contains(item.uniqueId)) {
      _repository.saveLikedItem(userId, item.uniqueId);
    }
  }

  /// Process removing a liked item
  void processRemoveLike({
    required String userId,
    required Movie item,
  }) {
    _repository.removeLikedItem(userId, item.uniqueId);
  }

  /// Check if more items need to be loaded
  bool shouldLoadMore(int remainingItems, {int threshold = 5}) {
    return remainingItems < threshold;
  }

  /// Separate items by media type
  Map<String, List<Movie>> separateByMediaType(List<Movie> items) {
    return {
      'movies': items.where((m) => m.mediaType == 'movie').toList(),
      'tvShows': items.where((m) => m.mediaType == 'tv').toList(),
    };
  }
}