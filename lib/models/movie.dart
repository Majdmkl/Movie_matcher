class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterUrl;
  final double rating;
  final int year;
  final List<String> genres;
  final String mediaType;
  final String originalLanguage;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.rating,
    required this.year,
    required this.genres,
    this.mediaType = 'movie',
    this.originalLanguage = '',
  });

  String get uniqueId => '${mediaType}_$id';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Movie && other.id == id && other.mediaType == mediaType;
  }

  @override
  int get hashCode => id.hashCode ^ mediaType.hashCode;
}