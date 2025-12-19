import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/swipe_viewmodel.dart';
import '../widgets/movie_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<SwipeViewModel>();
      if (viewModel.currentList.isEmpty) {
        viewModel.loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Movie Matcher', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Media Type Tabs
          _buildMediaTypeTabs(),

          // Swipe Area
          Expanded(
            child: Consumer<SwipeViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading && viewModel.currentList.isEmpty) {
                  return _buildLoadingState(viewModel.currentMediaType);
                }

                if (viewModel.error != null && viewModel.currentList.isEmpty) {
                  return _buildErrorState(viewModel);
                }

                if (!viewModel.hasItems) {
                  return _buildEmptyState(viewModel);
                }

                return _buildSwipeArea(viewModel);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeTabs() {
    return Consumer<SwipeViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  label: '🎬 Movies',
                  isSelected: viewModel.currentMediaType == MediaType.movies,
                  onTap: () => viewModel.setMediaType(MediaType.movies),
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  label: '📺 TV Shows',
                  isSelected: viewModel.currentMediaType == MediaType.tvShows,
                  onTap: () => viewModel.setMediaType(MediaType.tvShows),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(MediaType type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.purple),
          const SizedBox(height: 16),
          Text(
            type == MediaType.movies ? 'Loading movies...' : 'Loading TV shows...',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SwipeViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              viewModel.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                viewModel.clearError();
                viewModel.loadItems(reset: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(SwipeViewModel viewModel) {
    final isMovies = viewModel.currentMediaType == MediaType.movies;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMovies ? Icons.movie_outlined : Icons.tv_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              isMovies ? 'No more movies!' : 'No more TV shows!',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.loadItems(reset: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Load More', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeArea(SwipeViewModel viewModel) {
    return Column(
      children: [
        // Movie Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MovieCard(movie: viewModel.currentItem!),
          ),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Dislike Button
              _buildActionButton(
                icon: Icons.close,
                color: Colors.red,
                onTap: () => viewModel.swipeLeft(),
              ),

              // Like Button
              _buildActionButton(
                icon: Icons.favorite,
                color: Colors.green,
                size: 72,
                onTap: () => viewModel.swipeRight(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 3),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}