import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String itemId;
  final String itemTitle;
  final String itemType;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.itemId,
    required this.itemTitle,
    required this.itemType,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['created_at'] is Timestamp) {
      createdAt = (json['created_at'] as Timestamp).toDate();
    } else if (json['created_at'] is String) {
      createdAt = DateTime.parse(json['created_at']);
    } else {
      createdAt = DateTime.now();
    }

    return Review(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      itemId: json['item_id'] ?? json['movie_id']?.toString() ?? '',
      itemTitle: json['item_title'] ?? json['movie_title'] ?? '',
      itemType: json['item_type'] ?? 'movie',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'item_id': itemId,
      'item_title': itemTitle,
      'item_type': itemType,
      'rating': rating,
      'comment': comment,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}