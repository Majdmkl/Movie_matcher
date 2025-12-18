import 'package:flutter/foundation.dart';
import '../models/movie.dart';

class SwipeViewModel extends ChangeNotifier {
  List<Movie> _movies = [];
  int _currentIndex = 0;
  final List<Movie> _likedMovies = [];
  final List<Movie> _dislikedMovies = [];

  // Getters
  List<Movie> get movies => _movies;
  Movie? get currentMovie => _currentIndex < _movies.length ? _movies[_currentIndex] : null;
  List<Movie> get likedMovies => _likedMovies;
  int get likedCount => _likedMovies.length;
  bool get hasMovies => _currentIndex < _movies.length;

  // Ladda filmer (dummy data för nu)
  void loadMovies() {
    _movies = DummyMovies.getMovies();
    _currentIndex = 0;
    notifyListeners();
  }

  // Swipe höger (gilla)
  void swipeRight() {
    if (currentMovie != null) {
      _likedMovies.add(currentMovie!);
      _currentIndex++;
      notifyListeners();
    }
  }

  // Swipe vänster (ogilla)
  void swipeLeft() {
    if (currentMovie != null) {
      _dislikedMovies.add(currentMovie!);
      _currentIndex++;
      notifyListeners();
    }
  }

  // Återställ
  void reset() {
    _currentIndex = 0;
    _likedMovies.clear();
    _dislikedMovies.clear();
    notifyListeners();
  }
}