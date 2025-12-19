import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TMDBService {
  static const String _apiKey = '39efefeadf220160db823b7a542a2a56';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

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
      final response = await http.get(url).timeout(const Duration(seconds: 10));

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

  // Hämta en specifik film via ID
  Future<Movie?> getMovieById(int movieId) async {
    final url = Uri.parse(
      '$_baseUrl/movie/$movieId?api_key=$_apiKey&language=en-US',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMovieDetails(data);
      } else {
        print('❌ Failed to load movie $movieId: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching movie $movieId: $e');
      return null;
    }
  }

  // Hämta flera filmer via IDs
  Future<List<Movie>> getMoviesByIds(List<int> movieIds) async {
    final List<Movie> movies = [];
    
    // Hämta i batches för att inte överbelasta API
    for (int i = 0; i < movieIds.length; i++) {
      try {
        final movie = await getMovieById(movieIds[i]);
        if (movie != null) {
          movies.add(movie);
        }
        
        // Liten delay mellan anrop
        if (i < movieIds.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        print('⚠️ Could not fetch movie ${movieIds[i]}: $e');
      }
    }
    
    return movies;
  }

  // Hämta top-rated filmer
  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/movie/top_rated?api_key=$_apiKey&language=en-US&page=$page',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

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

  // Parse movie från lista-resultat
  Movie _parseMovie(Map<String, dynamic> json) {
    final genreIds = (json['genre_ids'] as List?)?.cast<int>() ?? [];
    final genres = genreIds
        .map((id) => _genres[id])
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
    );
  }

  // Parse movie från detalj-resultat (har genres som objekt istället för IDs)
  Movie _parseMovieDetails(Map<String, dynamic> json) {
    List<String> genres = [];
    if (json['genres'] != null) {
      genres = (json['genres'] as List)
          .map((g) => g['name'] as String)
          .toList();
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
    );
  }

  Map<int, String> getGenres() => _genres;
}