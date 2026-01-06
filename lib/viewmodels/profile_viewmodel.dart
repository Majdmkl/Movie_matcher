import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../use_cases/profile_use_case.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileUseCase _useCase;

  ProfileStats? _stats;

  ProfileViewModel({ProfileUseCase? useCase})
      : _useCase = useCase ?? ProfileUseCase();

  ProfileStats? get stats => _stats;
  int get level => _stats?.level ?? 1;
  double get progress => _stats?.progress ?? 0.0;
  int get moviesCount => _stats?.moviesCount ?? 0;
  int get tvShowsCount => _stats?.tvShowsCount ?? 0;
  int get totalLiked => _stats?.totalLiked ?? 0;
  int get friendsCount => _stats?.friendsCount ?? 0;
  int get moviesPercentage => _stats?.moviesPercentage ?? 0;
  int get tvShowsPercentage => _stats?.tvShowsPercentage ?? 0;
  String get nextLevelAt => _stats?.nextLevelAt ?? '';

  void updateStats({
    required AppUser user,
    required int moviesCount,
    required int tvShowsCount,
  }) {
    _stats = _useCase.calculateStats(
      user: user,
      moviesCount: moviesCount,
      tvShowsCount: tvShowsCount,
    );
    notifyListeners();
  }

  String formatMemberSince(DateTime createdAt) {
    return _useCase.formatMemberSince(createdAt);
  }

  String getLevelTitle() {
    return _useCase.getLevelTitle(level);
  }

  List<int> getLevelGradientColors() {
    return _useCase.getLevelGradient(level);
  }

  void reset() {
    _stats = null;
    notifyListeners();
  }
}