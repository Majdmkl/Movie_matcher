import '../models/movie.dart';
import '../models/user.dart';
import '../repositories/friend_matches_repository.dart';

class FriendMatchesData {
  final List<Movie> movies;
  final List<Movie> tvShows;
  final List<Movie> commonMovies;
  final List<Movie> commonTVShows;
  final int totalItems;
  final int totalCommon;

  FriendMatchesData({
    required this.movies,
    required this.tvShows,
    required this.commonMovies,
    required this.commonTVShows,
  })  : totalItems = movies.length + tvShows.length,
        totalCommon = commonMovies.length + commonTVShows.length;
}

class FriendMatchesUseCase {
  final FriendMatchesRepository _repository;

  FriendMatchesUseCase({FriendMatchesRepository? repository})
      : _repository = repository ?? FriendMatchesRepository();

  Future<AppUser?> loadLatestFriendData(String friendId) async {
    return await _repository.getFriendDetails(friendId);
  }

  Future<FriendMatchesData> loadFriendMatches({
    required AppUser friend,
    required List<String> myLikedIds,
  }) async {
    if (friend.likedMovieIds.isEmpty) {
      return FriendMatchesData(
        movies: [],
        tvShows: [],
        commonMovies: [],
        commonTVShows: [],
      );
    }

    final items = await _repository.loadFriendItems(friend.likedMovieIds);

    final movies = items.where((m) => m.mediaType == 'movie').toList();
    final tvShows = items.where((m) => m.mediaType == 'tv').toList();

    final commonMovies = movies
        .where((movie) => myLikedIds.contains(movie.uniqueId))
        .toList();
    final commonTVShows = tvShows
        .where((show) => myLikedIds.contains(show.uniqueId))
        .toList();

    return FriendMatchesData(
      movies: movies,
      tvShows: tvShows,
      commonMovies: commonMovies,
      commonTVShows: commonTVShows,
    );
  }

  bool isCommonMatch(String uniqueId, List<String> myLikedIds) {
    return myLikedIds.contains(uniqueId);
  }
}