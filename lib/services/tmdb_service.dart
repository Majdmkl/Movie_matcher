import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TMDBService {
  static const String _apiKey = '39efefeadf220160db823b7a542a2a56';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  final Random _random = Random();

  static const Map<int, String> _movieGenres = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  static const Map<int, String> _tvGenres = {
    10759: 'Action & Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    10762: 'Kids',
    9648: 'Mystery',
    10763: 'News',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Soap',
    10767: 'Talk',
    10768: 'War & Politics',
    37: 'Western',
  };

  // ==================== MOVIES ====================

  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    // Hämta från flera sidor och blanda för bättre randomisering
    final List<Movie> allMovies = [];
    
    // Slumpa vilka sidor vi hämtar från (1-100)
    final randomPages = _getRandomPages(3, 100);
    
    for (final p in randomPages) {
      try {
        final movies = await _fetchMovies('/movie/popular', p);
        allMovies.addAll(movies);
      } catch (e) {
        print('⚠️ Error fetching page $p: $e');
      }
    }

    // Blanda ordningen
    allMovies.shuffle(_random);
    return allMovies;
  }

  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    final randomPages = _getRandomPages(2, 50);
    final List<Movie> allMovies = [];
    
    for (final p in randomPages) {
      try {
        final movies = await _fetchMovies('/movie/top_rated', p);
        allMovies.addAll(movies);
      } catch (e) {
        print('⚠️ Error fetching page $p: $e');
      }
    }

    allMovies.shuffle(_random);
    return allMovies;
  }

  Future<List<Movie>> _fetchMovies(String endpoint, int page) async {
    final url = Uri.parse('$_baseUrl$endpoint?api_key=$_apiKey&language=en-US&page=$page');

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((movie) => _parseMovie(movie)).toList();
    } else {
      throw Exception('Failed to load movies: ${response.statusCode}');
    }
  }

  // ==================== TV SHOWS ====================

  Future<List<Movie>> getPopularTVShows({int page = 1}) async {
    final List<Movie> allShows = [];
    
    // Slumpa vilka sidor vi hämtar från
    final randomPages = _getRandomPages(3, 100);
    
    for (final p in randomPages) {
      try {
        final shows = await _fetchTVShows('/tv/popular', p);
        allShows.addAll(shows);
      } catch (e) {
        print('⚠️ Error fetching TV page $p: $e');
      }
    }

    allShows.shuffle(_random);
    return allShows;
  }

  Future<List<Movie>> getTopRatedTVShows({int page = 1}) async {
    final randomPages = _getRandomPages(2, 50);
    final List<Movie> allShows = [];
    
    for (final p in randomPages) {
      try {
        final shows = await _fetchTVShows('/tv/top_rated', p);
        allShows.addAll(shows);
      } catch (e) {
        print('⚠️ Error fetching TV page $p: $e');
      }
    }

    allShows.shuffle(_random);
    return allShows;
  }

  Future<List<Movie>> _fetchTVShows(String endpoint, int page) async {
    final url = Uri.parse('$_baseUrl$endpoint?api_key=$_apiKey&language=en-US&page=$page');

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((show) => _parseTVShow(show)).toList();
    } else {
      throw Exception('Failed to load TV shows: ${response.statusCode}');
    }
  }

  // ==================== GET BY ID ====================

  Future<Movie?> getMovieById(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey&language=en-US');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMovieDetails(data);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching movie $movieId: $e');
      return null;
    }
  }

  Future<Movie?> getTVShowById(int tvId) async {
    final url = Uri.parse('$_baseUrl/tv/$tvId?api_key=$_apiKey&language=en-US');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseTVShowDetails(data);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching TV show $tvId: $e');
      return null;
    }
  }

  // Hämta flera items via unika IDs (movie_123 eller tv_456)
  Future<List<Movie>> getItemsByUniqueIds(List<String> uniqueIds) async {
    final List<Movie> items = [];

    for (final uniqueId in uniqueIds) {
      try {
        final parts = uniqueId.split('_');
        if (parts.length != 2) continue;

        final mediaType = parts[0];
        final id = int.tryParse(parts[1]);
        if (id == null) continue;

        Movie? item;
        if (mediaType == 'movie') {
          item = await getMovieById(id);
        } else if (mediaType == 'tv') {
          item = await getTVShowById(id);
        }

        if (item != null) {
          items.add(item);
        }

        // Liten delay
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        print('⚠️ Could not fetch $uniqueId: $e');
      }
    }

    return items;
  }

  // ==================== HELPERS ====================

  List<int> _getRandomPages(int count, int maxPage) {
    final Set<int> pages = {};
    while (pages.length < count) {
      pages.add(_random.nextInt(maxPage) + 1);
    }
    return pages.toList();
  }

  Movie _parseMovie(Map<String, dynamic> json) {
    final genreIds = (json['genre_ids'] as List?)?.cast<int>() ?? [];
    final genres = genreIds
        .map((id) => _movieGenres[id])
        .where((name) => name != null)
        .cast<String>()
        .toList();

    String? posterPath = json['poster_path'];
    String posterUrl = posterPath != null ? '$_imageBaseUrl$posterPath' : '';

    String releaseDate = json['release_date'] ?? '';
    int year = 0;
    if (releaseDate.isNotEmpty && releaseDate.length >= 4) {
      year = int.tryParse(releaseDate.substring(0, 4)) ?? 0;
    }

    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      overview: json['overview'] ?? '',
      posterUrl: posterUrl,
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      year: year,
      genres: genres,
      mediaType: 'movie',
    );
  }

  Movie _parseMovieDetails(Map<String, dynamic> json) {
    List<String> genres = [];
    if (json['genres'] != null) {
      genres = (json['genres'] as List).map((g) => g['name'] as String).toList();
    }

    String? posterPath = json['poster_path'];
    String posterUrl = posterPath != null ? '$_imageBaseUrl$posterPath' : '';

    String releaseDate = json['release_date'] ?? '';
    int year = 0;
    if (releaseDate.isNotEmpty && releaseDate.length >= 4) {
      year = int.tryParse(releaseDate.substring(0, 4)) ?? 0;
    }

    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      overview: json['overview'] ?? '',
      posterUrl: posterUrl,
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      year: year,
      genres: genres,
      mediaType: 'movie',
    );
  }

  Movie _parseTVShow(Map<String, dynamic> json) {
    final genreIds = (json['genre_ids'] as List?)?.cast<int>() ?? [];
    final genres = genreIds
        .map((id) => _tvGenres[id])
        .where((name) => name != null)
        .cast<String>()
        .toList();

    String? posterPath = json['poster_path'];
    String posterUrl = posterPath != null ? '$_imageBaseUrl$posterPath' : '';

    String firstAirDate = json['first_air_date'] ?? '';
    int year = 0;
    if (firstAirDate.isNotEmpty && firstAirDate.length >= 4) {
      year = int.tryParse(firstAirDate.substring(0, 4)) ?? 0;
    }

    return Movie(
      id: json['id'] ?? 0,
      title: json['name'] ?? 'Unknown Title', // TV uses 'name' not 'title'
      overview: json['overview'] ?? '',
      posterUrl: posterUrl,
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      year: year,
      genres: genres,
      mediaType: 'tv',
    );
  }

  Movie _parseTVShowDetails(Map<String, dynamic> json) {
    List<String> genres = [];
    if (json['genres'] != null) {
      genres = (json['genres'] as List).map((g) => g['name'] as String).toList();
    }

    String? posterPath = json['poster_path'];
    String posterUrl = posterPath != null ? '$_imageBaseUrl$posterPath' : '';

    String firstAirDate = json['first_air_date'] ?? '';
    int year = 0;
    if (firstAirDate.isNotEmpty && firstAirDate.length >= 4) {
      year = int.tryParse(firstAirDate.substring(0, 4)) ?? 0;
    }

    return Movie(
      id: json['id'] ?? 0,
      title: json['name'] ?? 'Unknown Title',
      overview: json['overview'] ?? '',
      posterUrl: posterUrl,
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      year: year,
      genres: genres,
      mediaType: 'tv',
    );
  }
}