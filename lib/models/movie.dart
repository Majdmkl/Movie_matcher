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

  // För att jämföra filmer (undvika dubletter)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movie && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}