import '../models/user.dart';

class ProfileStats {
  final int level;
  final double progress;
  final int moviesCount;
  final int tvShowsCount;
  final int totalLiked;
  final int friendsCount;
  final int moviesPercentage;
  final int tvShowsPercentage;
  final String nextLevelAt;

  ProfileStats({
    required this.level,
    required this.progress,
    required this.moviesCount,
    required this.tvShowsCount,
    required this.totalLiked,
    required this.friendsCount,
    required this.moviesPercentage,
    required this.tvShowsPercentage,
    required this.nextLevelAt,
  });
}

class ProfileUseCase {
  static const List<int> _levelThresholds = [0, 10, 25, 50, 100, 200, 500];

  ProfileStats calculateStats({
    required AppUser user,
    required int moviesCount,
    required int tvShowsCount,
  }) {
    final totalLiked = moviesCount + tvShowsCount;
    final level = _calculateLevel(totalLiked);
    final progress = _calculateProgress(totalLiked, level);

    final moviesPercentage = totalLiked > 0
        ? ((moviesCount / totalLiked) * 100).round()
        : 0;
    final tvShowsPercentage = totalLiked > 0
        ? ((tvShowsCount / totalLiked) * 100).round()
        : 0;

    final nextLevelAt = _getNextLevelInfo(level);

    return ProfileStats(
      level: level,
      progress: progress,
      moviesCount: moviesCount,
      tvShowsCount: tvShowsCount,
      totalLiked: totalLiked,
      friendsCount: user.friendIds.length,
      moviesPercentage: moviesPercentage,
      tvShowsPercentage: tvShowsPercentage,
      nextLevelAt: nextLevelAt,
    );
  }

  int _calculateLevel(int totalLiked) {
    if (totalLiked < 10) return 1;
    if (totalLiked < 25) return 2;
    if (totalLiked < 50) return 3;
    if (totalLiked < 100) return 4;
    if (totalLiked < 200) return 5;
    return 6;
  }

  double _calculateProgress(int totalLiked, int level) {
    if (level >= 6) return 1.0;

    final prevThreshold = _levelThresholds[level - 1];
    final nextThreshold = _levelThresholds[level];

    return (totalLiked - prevThreshold) / (nextThreshold - prevThreshold);
  }

  String _getNextLevelInfo(int level) {
    if (level >= 6) return 'Max level reached!';
    return '${_levelThresholds[level]} items';
  }

  String formatMemberSince(DateTime createdAt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.year}';
  }

  String getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Casual Viewer';
      case 3:
        return 'Movie Fan';
      case 4:
        return 'Cinephile';
      case 5:
        return 'Expert Critic';
      case 6:
        return 'Master Curator';
      default:
        return 'Viewer';
    }
  }

  List<int> getLevelGradient(int level) {
    switch (level) {
      case 1:
        return [0xFF9E9E9E, 0xFF757575]; // Grey
      case 2:
        return [0xFF4CAF50, 0xFF8BC34A]; // Green
      case 3:
        return [0xFF2196F3, 0xFF00BCD4]; // Blue
      case 4:
        return [0xFF9C27B0, 0xFF673AB7]; // Purple
      case 5:
        return [0xFFFF9800, 0xFFFF5722]; // Orange
      case 6:
        return [0xFFFFD700, 0xFFFFA000]; // Gold
      default:
        return [0xFF9E9E9E, 0xFF757575];
    }
  }
}