import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  // Skapa/uppdatera recension
  Future<bool> saveReview(Review review) async {
    try {
      await _firestore.collection(_collection).doc(review.id).set(review.toJson());
      print('✅ Review saved');
      return true;
    } catch (e) {
      print('❌ Error saving review: $e');
      return false;
    }
  }

  // Hämta recensioner för ett item (movie_123 eller tv_456)
  Future<List<Review>> getReviewsForItem(String itemId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('item_id', isEqualTo: itemId)
          .get();

      return query.docs.map((doc) => Review.fromJson(doc.data())).toList();
    } catch (e) {
      print('❌ Error getting reviews: $e');
      return [];
    }
  }

  // Hämta recensioner från specifika användare (vänner)
  Future<List<Review>> getReviewsFromUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final List<Review> reviews = [];

      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final query = await _firestore
            .collection(_collection)
            .where('user_id', whereIn: batch)
            .get();

        reviews.addAll(query.docs.map((doc) => Review.fromJson(doc.data())));
      }

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    } catch (e) {
      print('❌ Error getting reviews from users: $e');
      return [];
    }
  }

  // Hämta användarens recension för ett specifikt item
  Future<Review?> getUserReviewForItem(String userId, String itemId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .where('item_id', isEqualTo: itemId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Review.fromJson(query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Error getting user review: $e');
      return null;
    }
  }

  // Ta bort recension
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).delete();
      print('✅ Review deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting review: $e');
      return false;
    }
  }

  // Hämta alla recensioner från en användare
  Future<List<Review>> getUserReviews(String userId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .get();

      final reviews = query.docs.map((doc) => Review.fromJson(doc.data())).toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    } catch (e) {
      print('❌ Error getting user reviews: $e');
      return [];
    }
  }
}