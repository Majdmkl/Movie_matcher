import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/movie.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/tmdb_service.dart';

class FriendMatchesView extends StatefulWidget {
  final AppUser friend;

  const FriendMatchesView({Key? key, required this.friend}) : super(key: key);

  @override
  State<FriendMatchesView> createState() => _FriendMatchesViewState();
}

class _FriendMatchesViewState extends State<FriendMatchesView> {
  final TMDBService _tmdbService = TMDBService();
  List<Movie> _friendMovies = [];
  bool _isLoading = true;
  AppUser? _latestFriendData;

  @override
  void initState() {
    super.initState();
    _loadFriendMovies();
  }

  Future<void> _loadFriendMovies() async {
    setState(() => _isLoading = true);

    // Hämta senaste datan för vännen
    final authViewModel = context.read<AuthViewModel>();
    _latestFriendData = await authViewModel.getFriendDetails(widget.friend.id);

    final friendData = _latestFriendData ?? widget.friend;

    if (friendData.likedMovieIds.isNotEmpty) {
      _friendMovies = await _tmdbService.getMoviesByIds(friendData.likedMovieIds);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final friendData = _latestFriendData ?? widget.friend;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple,
              child: Text(
                friendData.name.isNotEmpty ? friendData.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${friendData.name}'s Matches",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_friendMovies.length} movies',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFriendMovies,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 16),
                  Text('Loading matches...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _friendMovies.isEmpty
              ? _buildEmptyState()
              : _buildMovieGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            '${widget.friend.name} hasn\'t liked any movies yet',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieGrid() {
    // Hitta gemensamma filmer
    final currentUser = context.read<AuthViewModel>().currentUser;
    final myLikedIds = currentUser?.likedMovieIds ?? [];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _friendMovies.length,
      itemBuilder: (context, index) {
        final movie = _friendMovies[index];
        final isCommon = myLikedIds.contains(movie.id);
        return _buildMovieTile(movie, isCommon);
      },
    );
  }

  Widget _buildMovieTile(Movie movie, bool isCommon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isCommon
            ? Border.all(color: Colors.green, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: isCommon
                ? Colors.green.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster
            movie.posterUrl.isNotEmpty
                ? Image.network(
                    movie.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Icon(Icons.movie, color: Colors.grey, size: 40),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(Icons.movie, color: Colors.grey, size: 40),
                  ),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Match badge
            if (isCommon)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'MATCH!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}