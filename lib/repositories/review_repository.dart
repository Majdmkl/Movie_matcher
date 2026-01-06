import '../models/review.dart';
import '../services/review_service.dart';

class ReviewRepository {
  final ReviewService _reviewService;

  ReviewRepository({ReviewService? reviewService})
      : _reviewService = reviewService ?? ReviewService();

  Future<bool> saveReview(Review review) async {
    return await _reviewService.saveReview(review);
  }

  Future<List<Review>> getReviewsForItem(String itemId) async {
    return await _reviewService.getReviewsForItem(itemId);
  }

  Future<List<Review>> getReviewsFromUsers(List<String> userIds) async {
    return await _reviewService.getReviewsFromUsers(userIds);
  }

  Future<Review?> getUserReviewForItem(String userId, String itemId) async {
    return await _reviewService.getUserReviewForItem(userId, itemId);
  }

  Future<bool> deleteReview(String reviewId) async {
    return await _reviewService.deleteReview(reviewId);
  }

  Future<List<Review>> getUserReviews(String userId) async {
    return await _reviewService.getUserReviews(userId);
  }
}