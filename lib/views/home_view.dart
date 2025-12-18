import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/swipe_viewmodel.dart';
import '../widgets/movie_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.movie_filter, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'Movie Matcher',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SwipeViewModel>().reset();
              context.read<SwipeViewModel>().loadMovies();
            },
          ),
        ],
      ),
      body: Consumer<SwipeViewModel>(
        builder: (context, viewModel, child) {
          if (!viewModel.hasMovies) {
            return _buildEmptyState(context, viewModel);
          }

          return Column(
            children: [
              // Movie Card
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      // Swipe right - like
                      viewModel.swipeRight();
                    } else if (details.primaryVelocity! < 0) {
                      // Swipe left - dislike
                      viewModel.swipeLeft();
                    }
                  },
                  child: MovieCard(movie: viewModel.currentMovie!),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.close,
                      color: Colors.red,
                      onPressed: () => viewModel.swipeLeft(),
                    ),
                    const SizedBox(width: 32),
                    _buildActionButton(
                      icon: Icons.favorite,
                      color: Colors.green,
                      onPressed: () => viewModel.swipeRight(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SwipeViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No more movies!',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You liked ${viewModel.likedCount} movies',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              viewModel.reset();
              viewModel.loadMovies();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Start Over'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
        ),
        child: Icon(icon, size: 30, color: Colors.white),
      ),
    );
  }
}