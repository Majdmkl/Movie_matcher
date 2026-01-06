import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../use_cases/friend_matches_use_case.dart';

class FriendMatchesViewModel extends ChangeNotifier {
  final FriendMatchesUseCase _useCase;

  AppUser? _latestFriendData;
  List<Movie> _movies = [];
  List<Movie> _tvShows = [];
  List<Movie> _commonMovies = [];
  List<Movie> _commonTVShows = [];
  bool _isLoading = false;
  String? _error;

  FriendMatchesViewModel({FriendMatchesUseCase? useCase})
      : _useCase = useCase ?? FriendMatchesUseCase();

  AppUser? get latestFriendData => _latestFriendData;
  List<Movie> get movies => _movies;
  List<Movie> get tvShows => _tvShows;
  List<Movie> get commonMovies => _commonMovies;
  List<Movie> get commonTVShows => _commonTVShows;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalItems => _movies.length + _tvShows.length;
  int get totalCommon => _commonMovies.length + _commonTVShows.length;

  Future<void> loadFriendMatches({
    required AppUser friend,
    required List<String> myLikedIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _latestFriendData = await _useCase.loadLatestFriendData(friend.id);
      final friendToUse = _latestFriendData ?? friend;

      final matchesData = await _useCase.loadFriendMatches(
        friend: friendToUse,
        myLikedIds: myLikedIds,
      );

      _movies = matchesData.movies;
      _tvShows = matchesData.tvShows;
      _commonMovies = matchesData.commonMovies;
      _commonTVShows = matchesData.commonTVShows;

      print('✅ Loaded ${_movies.length} movies, ${_tvShows.length} TV shows');
      print('✅ Common: ${_commonMovies.length} movies, ${_commonTVShows.length} shows');
    } catch (e) {
      _error = 'Failed to load friend matches';
      print('❌ Error loading friend matches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isCommonMatch(String uniqueId, List<String> myLikedIds) {
    return _useCase.isCommonMatch(uniqueId, myLikedIds);
  }

  void reset() {
    _latestFriendData = null;
    _movies = [];
    _tvShows = [];
    _commonMovies = [];
    _commonTVShows = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}