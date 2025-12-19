import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final List<int> likedMovieIds;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    List<int>? likedMovieIds,
    DateTime? createdAt,
  })  : likedMovieIds = likedMovieIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['created_at'] is Timestamp) {
      createdAt = (json['created_at'] as Timestamp).toDate();
    } else if (json['created_at'] is String) {
      createdAt = DateTime.parse(json['created_at']);
    } else {
      createdAt = DateTime.now();
    }

    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      likedMovieIds: List<int>.from(json['liked_movie_ids'] ?? []),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'liked_movie_ids': likedMovieIds,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    List<int>? likedMovieIds,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      likedMovieIds: likedMovieIds ?? this.likedMovieIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}