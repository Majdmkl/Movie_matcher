import '../models/review.dart';
import '../models/user.dart';
import '../repositories/review_repository.dart';

class ReviewUseCase {
  final ReviewRepository _repository;

  ReviewUseCase({ReviewRepository? repository})
      : _repository = repository ?? ReviewRepository();

  Future<bool> createOrUpdateReview({
    required String userId,
    required String userName,
    required String itemId,
    required String itemTitle,
    required String itemType,
    required double rating,
    required String comment,
    String? existingReviewId,
  }) async {
    if (rating <= 0 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    final reviewId = existingReviewId ?? '${userId}_$itemId';

    final review = Review(
      id: reviewId,
      userId: userId,
      userName: userName,
      itemId: itemId,
      itemTitle: itemTitle,
      itemType: itemType,
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );

    return await _repository.saveReview(review);
  }

  Future<Map<String, dynamic>> loadReviewsForItem({
    required String itemId,
    required AppUser currentUser,
  }) async {

    final allReviews = await _repository.getReviewsForItem(itemId);

    final userIds = [currentUser.id, ...currentUser.friendIds];
    final filteredReviews = allReviews
        .where((review) => userIds.contains(review.userId))
        .toList();

    final myReview = filteredReviews
        .where((review) => review.userId == currentUser.id)
        .firstOrNull;

    final friendReviews = filteredReviews
        .where((review) => review.userId != currentUser.id)
        .toList();

    return {
      'myReview': myReview,
      'friendReviews': friendReviews,
      'allReviews': filteredReviews,
    };
  }

  Future<bool> deleteReview(String reviewId) async {
    return await _repository.deleteReview(reviewId);
  }

  Future<List<Review>> getUserReviews(String userId) async {
    return await _repository.getUserReviews(userId);
  }

  String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String? validateRating(double rating) {
    if (rating <= 0) {
      return 'Please select a rating';
    }
    if (rating > 5) {
      return 'Rating cannot be more than 5 stars';
    }
    return null;
  }
}