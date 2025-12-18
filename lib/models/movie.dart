class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterUrl;
  final double rating;
  final int year;
  final List<String> genres;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.rating,
    required this.year,
    required this.genres,
  });
}

// Dummy data för testning (ersätts med API senare)
class DummyMovies {
  static List<Movie> getMovies() {
    return [
      Movie(
        id: 1,
        title: 'Inception',
        overview: 'A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.',
        posterUrl: 'https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Ber.jpg',
        rating: 8.8,
        year: 2010,
        genres: ['Action', 'Sci-Fi', 'Thriller'],
      ),
      Movie(
        id: 2,
        title: 'The Dark Knight',
        overview: 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.',
        posterUrl: 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
        rating: 9.0,
        year: 2008,
        genres: ['Action', 'Crime', 'Drama'],
      ),
      Movie(
        id: 3,
        title: 'Interstellar',
        overview: 'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
        posterUrl: 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        rating: 8.6,
        year: 2014,
        genres: ['Adventure', 'Drama', 'Sci-Fi'],
      ),
      Movie(
        id: 4,
        title: 'Pulp Fiction',
        overview: 'The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.',
        posterUrl: 'https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg',
        rating: 8.9,
        year: 1994,
        genres: ['Crime', 'Drama'],
      ),
      Movie(
        id: 5,
        title: 'The Matrix',
        overview: 'A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers.',
        posterUrl: 'https://image.tmdb.org/t/p/w500/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
        rating: 8.7,
        year: 1999,
        genres: ['Action', 'Sci-Fi'],
      ),
    ];
  }
}