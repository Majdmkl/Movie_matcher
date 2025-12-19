import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/swipe_viewmodel.dart';
import '../models/movie.dart';
import 'movie_detail_view.dart';

class MatchesView extends StatefulWidget {
  const MatchesView({Key? key}) : super(key: key);

  @override
  State<MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<MatchesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Matches', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Consumer<SwipeViewModel>(
              builder: (context, vm, _) => Tab(
                text: '🎬 Movies (${vm.likedMoviesCount})',
              ),
            ),
            Consumer<SwipeViewModel>(
              builder: (context, vm, _) => Tab(
                text: '📺 TV Shows (${vm.likedTVShowsCount})',
              ),
            ),
          ],
        ),
      ),
      body: Consumer<SwipeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoadingLiked) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 16),
                  Text('Loading your matches...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildGrid(viewModel.likedMovies, viewModel, 'movie'),
              _buildGrid(viewModel.likedTVShows, viewModel, 'tv'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<Movie> items, SwipeViewModel viewModel, String type) {
    if (items.isEmpty) {
      return _buildEmptyState(type);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemTile(context, item, viewModel);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    final isMovie = type == 'movie';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMovie ? Icons.movie_outlined : Icons.tv_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            isMovie ? 'No liked movies yet' : 'No liked TV shows yet',
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Start swiping to find ${isMovie ? 'movies' : 'shows'} you like!',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, Movie item, SwipeViewModel viewModel) {
    final isTV = item.mediaType == 'tv';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailView(movie: item),
          ),
        );
      },
      onLongPress: () {
        _showRemoveDialog(context, item, viewModel);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
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
              item.posterUrl.isNotEmpty
                  ? Image.network(
                      item.posterUrl,
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
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const Spacer(),
                          const Icon(Icons.rate_review, size: 14, color: Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Type badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTV ? Colors.blue : Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isTV ? 'TV' : 'MOVIE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Like icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, Movie item, SwipeViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Remove from matches?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${item.title}" from your matches?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.removeLikedItem(item);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}