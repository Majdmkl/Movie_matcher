import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/review_viewmodel.dart';
import '../viewmodels/watch_provider_viewmodel.dart';
import '../services/tmdb_service.dart';

class MovieDetailView extends StatefulWidget {
  final Movie movie;
  final bool showWriteReview;

  const MovieDetailView({
    Key? key,
    required this.movie,
    this.showWriteReview = true,
  }) : super(key: key);

  @override
  State<MovieDetailView> createState() => _MovieDetailViewState();
}

class _MovieDetailViewState extends State<MovieDetailView> {
  late ReviewViewModel _reviewViewModel;
  late WatchProviderViewModel _providerViewModel;

  bool get isTV => widget.movie.mediaType == 'tv';

  @override
  void initState() {
    super.initState();
    _reviewViewModel = ReviewViewModel();
    _providerViewModel = WatchProviderViewModel();
    _loadData();
  }

  @override
  void dispose() {
    _reviewViewModel.dispose();
    _providerViewModel.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser != null) {
      await _reviewViewModel.loadReviews(
        movie: widget.movie,
        currentUser: currentUser,
      );
    }

    await _providerViewModel.loadProviders(widget.movie);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _reviewViewModel),
        ChangeNotifierProvider.value(value: _providerViewModel),
      ],
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A0A2E), Color(0xFF0D0D0D)],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(),
                      const SizedBox(height: 16),
                      _buildInfoRow(),
                      const SizedBox(height: 16),
                      _buildGenres(),
                      const SizedBox(height: 20),
                      _buildWatchProvidersSection(),
                      const SizedBox(height: 24),
                      _buildOverview(),
                      const SizedBox(height: 32),
                      if (widget.showWriteReview) ...[
                        _buildWriteReviewSection(),
                        const SizedBox(height: 24),
                      ],
                      _buildReviewsSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      backgroundColor: const Color(0xFF1A0A2E),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.movie.posterUrl.isNotEmpty
                ? Image.network(widget.movie.posterUrl, fit: BoxFit.cover)
                : Container(color: const Color(0xFF1A1A1A)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF1A0A2E).withOpacity(0.8),
                    const Color(0xFF1A0A2E),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isTV
                  ? [Colors.blue, Colors.lightBlue]
                  : [Colors.purple, Colors.deepPurple],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isTV ? Icons.tv : Icons.movie, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                isTV ? 'TV SHOW' : 'MOVIE',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.movie.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        if (widget.movie.year > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.movie.year.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                widget.movie.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenres() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.movie.genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            genre,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWatchProvidersSection() {
    return Consumer<WatchProviderViewModel>(
      builder: (context, providerVM, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.15),
                Colors.purple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_circle_filled, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Where to Watch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (providerVM.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
                  ),
                )
              else if (!providerVM.hasProviders)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No streaming info available for your region',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (providerVM.streamingProviders.isNotEmpty) ...[
                      _buildProviderCategory(
                        'Stream',
                        Icons.subscriptions,
                        Colors.green,
                        providerVM.streamingProviders,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (providerVM.rentProviders.isNotEmpty) ...[
                      _buildProviderCategory(
                        'Rent',
                        Icons.local_movies,
                        Colors.orange,
                        providerVM.rentProviders,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (providerVM.buyProviders.isNotEmpty)
                      _buildProviderCategory(
                        'Buy',
                        Icons.shopping_cart,
                        Colors.purple,
                        providerVM.buyProviders,
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Data provided by JustWatch',
                          style: TextStyle(color: Colors.grey[600], fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderCategory(
      String title,
      IconData icon,
      Color color,
      List<WatchProvider> providers,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: providers.map((provider) => _buildProviderChip(provider)).toList(),
        ),
      ],
    );
  }

  Widget _buildProviderChip(WatchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.logoPath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                provider.logoPath,
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                ),
              ),
            )
          else
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
            ),
          const SizedBox(width: 8),
          Text(
            provider.name,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.description, color: Colors.purple, size: 20),
            SizedBox(width: 8),
            Text(
              'Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.movie.overview,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildWriteReviewSection() {
    return Consumer<ReviewViewModel>(
      builder: (context, reviewVM, child) {
        final myReview = reviewVM.myReview;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rate_review, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    myReview != null ? 'Your Review' : 'Write a Review',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (myReview != null) ...[
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < myReview.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    );
                  }),
                ),
                if (myReview.comment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    myReview.comment,
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showReviewDialog(existingReview: myReview),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _deleteReview,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showReviewDialog(),
                    icon: const Icon(Icons.edit),
                    label: const Text('Write Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    return Consumer<ReviewViewModel>(
      builder: (context, reviewVM, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Friend Reviews (${reviewVM.friendReviews.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (reviewVM.isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.purple))
            else if (reviewVM.friendReviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        'No friend reviews yet',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...reviewVM.friendReviews.map((review) => _buildReviewCard(review, reviewVM)),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Review review, ReviewViewModel reviewVM) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      reviewVM.formatDate(review.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: TextStyle(color: Colors.grey[300], height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog({Review? existingReview}) {
    double rating = existingReview?.rating ?? 0;
    final commentController = TextEditingController(text: existingReview?.comment ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    existingReview != null ? 'Edit Review' : 'Write Review',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.title,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Rating',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setModalState(() => rating = index + 1.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Review (optional)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: rating > 0
                          ? () async {
                        await _saveReview(rating, commentController.text);
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        existingReview != null ? 'Update Review' : 'Submit Review',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveReview(double rating, String comment) async {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    final success = await _reviewViewModel.saveReview(
      movie: widget.movie,
      currentUser: currentUser,
      rating: rating,
      comment: comment,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Review?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _reviewViewModel.deleteReview();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}