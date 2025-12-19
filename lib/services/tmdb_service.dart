import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TMDBService {
  static const String _apiKey = '39efefeadf220160db823b7a542a2a56';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // Genre mappning
  static const Map<int, String> _genres = {
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

  // Hämta populära filmer
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/movie/popular?api_key=$_apiKey&language=en-US&page=$page',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((movie) => _parseMovie(movie)).toList();
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching movies: $e');
    }
  }

  // Hämta top-rated filmer
  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/movie/top_rated?api_key=$_apiKey&language=en-US&page=$page',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((movie) => _parseMovie(movie)).toList();
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching movies: $e');
    }
  }

  // Hämta filmer som visas nu
  Future<List<Movie>> getNowPlayingMovies({int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/movie/now_playing?api_key=$_apiKey&language=en-US&page=$page',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((movie) => _parseMovie(movie)).toList();
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching movies: $e');
    }
  }

  // Discover filmer med filter
  Future<List<Movie>> discoverMovies({
    int page = 1,
    List<int>? genreIds,
    double? minRating,
    int? year,
  }) async {
    String url = '$_baseUrl/discover/movie?api_key=$_apiKey&language=en-US&page=$page&sort_by=popularity.desc';

    if (genreIds != null && genreIds.isNotEmpty) {
      url += '&with_genres=${genreIds.join(',')}';
    }
    if (minRating != null) {
      url += '&vote_average.gte=$minRating';
    }
    if (year != null) {
      url += '&primary_release_year=$year';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((movie) => _parseMovie(movie)).toList();
      } else {
        throw Exception('Failed to discover movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error discovering movies: $e');
    }
  }

  // Sök filmer
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/search/movie?api_key=$_apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=$page',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((movie) => _parseMovie(movie)).toList();
      } else {
        throw Exception('Failed to search movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching movies: $e');
    }
  }

  // Parse movie från JSON
  Movie _parseMovie(Map<String, dynamic> json) {
    final genreIds = (json['genre_ids'] as List?)?.cast<int>() ?? [];
    final genres = genreIds
        .map((id) => _genres[id])
        .where((name) => name != null)
        .cast<String>()
        .toList();

    String? posterPath = json['poster_path'];
    String posterUrl = posterPath != null 
        ? '$_imageBaseUrl$posterPath' 
        : '';

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
    );
  }

  // Hämta alla tillgängliga genres
  Map<int, String> getGenres() => _genres;
}