import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../models/movie.dart';
import '../use_cases/review_use_case.dart';

class ReviewViewModel extends ChangeNotifier {
  final ReviewUseCase _useCase;

  Review? _myReview;
  List<Review> _friendReviews = [];
  bool _isLoading = false;
  String? _error;

  ReviewViewModel({ReviewUseCase? useCase})
      : _useCase = useCase ?? ReviewUseCase();

  Review? get myReview => _myReview;
  List<Review> get friendReviews => _friendReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMyReview => _myReview != null;

  Future<void> loadReviews({
    required Movie movie,
    required AppUser currentUser,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _useCase.loadReviewsForItem(
        itemId: movie.uniqueId,
        currentUser: currentUser,
      );

      _myReview = result['myReview'];
      _friendReviews = result['friendReviews'];

      print('✅ Loaded reviews: ${_friendReviews.length} friend reviews');
    } catch (e) {
      _error = 'Failed to load reviews';
      print('❌ Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveReview({
    required Movie movie,
    required AppUser currentUser,
    required double rating,
    required String comment,
  }) async {
    try {
      final success = await _useCase.createOrUpdateReview(
        userId: currentUser.id,
        userName: currentUser.name,
        itemId: movie.uniqueId,
        itemTitle: movie.title,
        itemType: movie.mediaType,
        rating: rating,
        comment: comment,
        existingReviewId: _myReview?.id,
      );

      if (success) {
        _myReview = Review(
          id: _myReview?.id ?? '${currentUser.id}_${movie.uniqueId}',
          userId: currentUser.id,
          userName: currentUser.name,
          itemId: movie.uniqueId,
          itemTitle: movie.title,
          itemType: movie.mediaType,
          rating: rating,
          comment: comment,
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReview() async {
    if (_myReview == null) return false;

    try {
      final success = await _useCase.deleteReview(_myReview!.id);

      if (success) {
        _myReview = null;
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Failed to delete review';
      notifyListeners();
      return false;
    }
  }

  String formatDate(DateTime date) {
    return _useCase.formatTimeAgo(date);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _myReview = null;
    _friendReviews = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}