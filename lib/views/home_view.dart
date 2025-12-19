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
    // Ladda filmer när skärmen öppnas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<SwipeViewModel>();
      if (viewModel.movies.isEmpty) {
        viewModel.loadMovies();
      }
    });
  }

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
          // Loading state
          if (viewModel.isLoading && viewModel.movies.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 16),
                  Text(
                    'Loading movies...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Error state
          if (viewModel.error != null && viewModel.movies.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        viewModel.clearError();
                        viewModel.loadMovies();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state (alla filmer swipade)
          if (!viewModel.hasMovies && !viewModel.isLoading) {
            return _buildEmptyState(context, viewModel);
          }

          // Main content
          return Column(
            children: [
              // Movie Card
              Expanded(
                child: Stack(
                  children: [
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity! > 0) {
                          viewModel.swipeRight();
                        } else if (details.primaryVelocity! < 0) {
                          viewModel.swipeLeft();
                        }
                      },
                      child: viewModel.currentMovie != null
                          ? MovieCard(movie: viewModel.currentMovie!)
                          : const SizedBox(),
                    ),
                    
                    // Loading indicator när fler laddas
                    if (viewModel.isLoading)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                  ],
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
            label: const Text('Load More Movies'),
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