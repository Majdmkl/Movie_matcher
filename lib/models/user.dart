class User {
  final String id;
  final String name;
  final List<int> likedMovieIds;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    List<int>? likedMovieIds,
    DateTime? createdAt,
  })  : likedMovieIds = likedMovieIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      likedMovieIds: List<int>.from(json['liked_movie_ids'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'liked_movie_ids': likedMovieIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    List<int>? likedMovieIds,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      likedMovieIds: likedMovieIds ?? this.likedMovieIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}