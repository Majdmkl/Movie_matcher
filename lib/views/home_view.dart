import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/swipe_viewmodel.dart';
import '../models/movie.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;
  
  late AnimationController _swipeAnimationController;
  late Animation<Offset> _swipeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _swipeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<SwipeViewModel>();
      if (viewModel.currentList.isEmpty) {
        viewModel.loadItems();
      }
    });
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating) return;
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details, SwipeViewModel viewModel) {
    if (_isAnimating) return;
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    final threshold = MediaQuery.of(context).size.width * 0.25;

    if (_dragX.abs() > threshold || velocity.abs() > 500) {
      _animateSwipe(_dragX > 0 ? 1 : -1, viewModel);
    } else {
      _resetPosition();
    }
  }

  void _animateSwipe(int direction, SwipeViewModel viewModel) {
    setState(() => _isAnimating = true);

    final screenWidth = MediaQuery.of(context).size.width;
    final endX = direction * screenWidth * 1.5;

    _swipeAnimation = Tween<Offset>(
      begin: Offset(_dragX, _dragY),
      end: Offset(endX, _dragY + 50 * direction),
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeOut,
    ));

    _swipeAnimationController.forward().then((_) {
      if (direction > 0) {
        viewModel.swipeRight();
      } else {
        viewModel.swipeLeft();
      }
      _swipeAnimationController.reset();
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _isDragging = false;
        _isAnimating = false;
      });
    });
  }

  void _resetPosition() {
    setState(() {
      _dragX = 0;
      _dragY = 0;
      _isDragging = false;
    });
  }

  void _showGenreBottomSheet(BuildContext context, SwipeViewModel viewModel) {
    final genres = viewModel.currentMediaType == MediaType.movies
        ? _allMovieGenres
        : _allTVGenres;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.purple),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Genre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (viewModel.selectedGenre != null)
                    TextButton(
                      onPressed: () {
                        viewModel.setGenreFilter(null);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            // Genre grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  final isSelected = viewModel.selectedGenre == genre;
                  return GestureDetector(
                    onTap: () {
                      viewModel.setGenreFilter(genre);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF9C27B0), Color(0xFF673AB7)])
                            : null,
                        color: isSelected ? null : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0A2E),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCompactHeader(),
              _buildMediaTypeTabs(),
              _buildGenreFilter(),
              Expanded(child: _buildSwipeArea()),
              _buildActionButtons(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.movie_filter, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'WhatsNext',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  icon: Icons.movie,
                  label: 'Movies',
                  isSelected: viewModel.currentMediaType == MediaType.movies,
                  onTap: () => viewModel.setMediaType(MediaType.movies),
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  icon: Icons.tv,
                  label: 'TV Shows',
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
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF673AB7)])
              : null,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreFilter() {
    return Consumer<SwipeViewModel>(
      builder: (context, viewModel, child) {
        final quickGenres = viewModel.currentMediaType == MediaType.movies
            ? _quickMovieGenres
            : _quickTVGenres;

        return Container(
          height: 36,
          margin: const EdgeInsets.only(top: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: quickGenres.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: () => _showGenreBottomSheet(context, viewModel),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.purple.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.tune, color: Colors.purple, size: 18),
                  ),
                );
              }
              if (index == 1) {
                return _buildGenreChip(
                  'All',
                  viewModel.selectedGenre == null,
                  () => viewModel.setGenreFilter(null),
                );
              }
              final genre = quickGenres[index - 2];
              return _buildGenreChip(
                genre,
                viewModel.selectedGenre == genre,
                () => viewModel.setGenreFilter(genre),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGenreChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF673AB7)])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeArea() {
    return Consumer<SwipeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.currentList.isEmpty) {
          return _buildLoadingState();
        }

        if (viewModel.error != null && viewModel.currentList.isEmpty) {
          return _buildErrorState(viewModel);
        }

        final currentItem = viewModel.currentItem;
        if (currentItem == null) {
          return _buildEmptyState(viewModel);
        }

        return _buildCardStack(viewModel, currentItem);
      },
    );
  }

  Widget _buildCardStack(SwipeViewModel viewModel, Movie currentItem) {
    final nextItem = viewModel.nextItem;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background card
        if (nextItem != null)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
              child: Transform.scale(
                scale: 0.95,
                child: Opacity(
                  opacity: 0.6,
                  child: _buildMovieCard(nextItem, isBackground: true),
                ),
              ),
            ),
          ),
        // Main card
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: (details) => _onPanEnd(details, viewModel),
              child: AnimatedBuilder(
                animation: _swipeAnimationController,
                builder: (context, child) {
                  double x = _dragX;
                  double y = _dragY;

                  if (_isAnimating) {
                    x = _swipeAnimation.value.dx;
                    y = _swipeAnimation.value.dy;
                  }

                  return Transform(
                    transform: Matrix4.identity()
                      ..translate(x, y)
                      ..rotateZ(x * 0.0008),
                    alignment: Alignment.center,
                    child: _buildMovieCard(currentItem, dragX: _dragX),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(Movie movie, {bool isBackground = false, double dragX = 0}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isBackground
            ? null
            : [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster
            movie.posterUrl.isNotEmpty
                ? Image.network(
                    movie.posterUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.purple),
                        ),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(Icons.movie, color: Colors.grey, size: 60),
                  ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.55, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Like/Nope indicators
            if (!isBackground && dragX.abs() > 20) ...[
              Positioned(
                top: 50,
                left: 25,
                child: AnimatedOpacity(
                  opacity: dragX > 20 ? (dragX / 80).clamp(0.0, 1.0) : 0.0,
                  duration: const Duration(milliseconds: 100),
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIKE',
                        style: TextStyle(color: Colors.green, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 50,
                right: 25,
                child: AnimatedOpacity(
                  opacity: dragX < -20 ? (-dragX / 80).clamp(0.0, 1.0) : 0.0,
                  duration: const Duration(milliseconds: 100),
                  child: Transform.rotate(
                    angle: 0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NOPE',
                        style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Year and rating
                    Row(
                      children: [
                        if (movie.year > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              movie.year.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                movie.rating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Genres
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: movie.genres.take(3).map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    // Overview
                    Text(
                      movie.overview,
                      style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Media type badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: movie.mediaType == 'tv'
                        ? [Colors.blue, Colors.lightBlue]
                        : [Colors.purple, Colors.deepPurple],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(movie.mediaType == 'tv' ? Icons.tv : Icons.movie, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      movie.mediaType == 'tv' ? 'TV' : 'MOVIE',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

  Widget _buildActionButtons() {
    return Consumer<SwipeViewModel>(
      builder: (context, viewModel, child) {
        final hasItems = viewModel.currentItem != null;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.close,
                gradient: const [Color(0xFFFF5252), Color(0xFFFF1744)],
                size: 58,
                iconSize: 28,
                onTap: hasItems ? () => _animateSwipe(-1, viewModel) : null,
              ),
              _buildActionButton(
                icon: Icons.favorite,
                gradient: const [Color(0xFF69F0AE), Color(0xFF00E676)],
                size: 66,
                iconSize: 32,
                onTap: hasItems ? () => _animateSwipe(1, viewModel) : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required List<Color> gradient,
    required double size,
    required double iconSize,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onTap != null ? gradient : [Colors.grey, Colors.grey],
          ),
          boxShadow: onTap != null
              ? [BoxShadow(color: gradient[0].withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 16),
          Text('Finding great content...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(SwipeViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(viewModel.error ?? 'Error', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.loadItems(reset: true),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SwipeViewModel viewModel) {
    final hasFilter = viewModel.selectedGenre != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(hasFilter ? Icons.filter_list_off : Icons.movie_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No ${viewModel.selectedGenre} content' : 'No more content',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasFilter)
                ElevatedButton(
                  onPressed: () => viewModel.setGenreFilter(null),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('Clear Filter', style: TextStyle(color: Colors.white)),
                ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => viewModel.loadItems(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                child: const Text('Load More', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<String> _quickMovieGenres = [
    'Action', 'Comedy', 'Drama', 'Horror', 'Sci-Fi', 'Romance', 'Thriller', 'Animation',
  ];

  static const List<String> _quickTVGenres = [
    'Drama', 'Comedy', 'Crime', 'Animation', 'Reality', 'Documentary',
  ];

  static const List<String> _allMovieGenres = [
    'Action', 'Adventure', 'Animation', 'Comedy', 'Crime', 'Documentary',
    'Drama', 'Family', 'Fantasy', 'History', 'Horror', 'Music', 'Mystery',
    'Romance', 'Sci-Fi', 'Thriller', 'War', 'Western', 'Arabic', 'Turkish',
  ];

  static const List<String> _allTVGenres = [
    'Action & Adventure', 'Animation', 'Comedy', 'Crime', 'Documentary',
    'Drama', 'Family', 'Kids', 'Mystery', 'Reality', 'Sci-Fi & Fantasy',
    'Soap', 'Talk', 'War & Politics', 'Western', 'Arabic', 'Turkish',
  ];
}