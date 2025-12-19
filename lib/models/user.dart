import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final List<String> likedMovieIds; // Format: "movie_123" eller "tv_456"
  final List<String> friendIds;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    List<String>? likedMovieIds,
    List<String>? friendIds,
    DateTime? createdAt,
  })  : likedMovieIds = likedMovieIds ?? [],
        friendIds = friendIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Hjälpmetoder för att filtrera
  List<String> get likedMovies => likedMovieIds.where((id) => id.startsWith('movie_')).toList();
  List<String> get likedTVShows => likedMovieIds.where((id) => id.startsWith('tv_')).toList();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['created_at'] is Timestamp) {
      createdAt = (json['created_at'] as Timestamp).toDate();
    } else if (json['created_at'] is String) {
      createdAt = DateTime.parse(json['created_at']);
    } else {
      createdAt = DateTime.now();
    }

    // Hantera både gamla (int) och nya (String) format
    List<String> likedIds = [];
    if (json['liked_movie_ids'] != null) {
      for (var id in json['liked_movie_ids']) {
        if (id is int) {
          // Gammalt format - anta att det är en film
          likedIds.add('movie_$id');
        } else if (id is String) {
          likedIds.add(id);
        }
      }
    }

    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      likedMovieIds: likedIds,
      friendIds: List<String>.from(json['friend_ids'] ?? []),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'liked_movie_ids': likedMovieIds,
      'friend_ids': friendIds,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    List<String>? likedMovieIds,
    List<String>? friendIds,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      likedMovieIds: likedMovieIds ?? this.likedMovieIds,
      friendIds: friendIds ?? this.friendIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}