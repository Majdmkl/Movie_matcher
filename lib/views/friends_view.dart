import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/friends_viewmodel.dart';
import '../models/user.dart';
import 'friend_matches_view.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({Key? key}) : super(key: key);

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  late FriendsViewModel _friendsViewModel;

  @override
  void initState() {
    super.initState();
    _friendsViewModel = FriendsViewModel();
    _loadFriends();
  }

  @override
  void dispose() {
    _friendsViewModel.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final authViewModel = context.read<AuthViewModel>();
    final friendIds = authViewModel.currentUser?.friendIds ?? [];
    await _friendsViewModel.loadFriends(friendIds);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _friendsViewModel,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Friends',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showAddFriendDialog(context),
            ),
          ],
        ),
        body: Consumer<FriendsViewModel>(
          builder: (context, friendsVM, child) {
            if (friendsVM.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              );
            }

            if (!friendsVM.hasFriends) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: friendsVM.friends.length,
              itemBuilder: (context, index) {
                final friend = friendsVM.friends[index];
                return _buildFriendCard(context, friend);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 50,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No friends yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to see their movie matches\nand find movies to watch together!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddFriendDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Friend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, AppUser friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.purple,
          child: Text(
            friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          friend.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              friend.email,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.favorite, size: 14, color: Colors.red[400]),
                const SizedBox(width: 4),
                Text(
                  '${friend.likedMovieIds.length} liked movies',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.movie, color: Colors.purple),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendMatchesView(friend: friend),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person_remove, color: Colors.red[400]),
              onPressed: () => _showRemoveFriendDialog(context, friend),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    final emailController = TextEditingController();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: _friendsViewModel,
        child: Consumer<FriendsViewModel>(
          builder: (context, friendsVM, child) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.person_add, color: Colors.purple),
                  SizedBox(width: 12),
                  Text('Add Friend', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter friend\'s email',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.email, color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (value) {
                      if (friendsVM.searchState != FriendSearchState.searching) {
                        friendsVM.searchFriend(
                          email: emailController.text,
                          currentUser: currentUser,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Loading state
                  if (friendsVM.isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: Colors.purple),
                    ),

                  // Error state
                  if (friendsVM.searchState == FriendSearchState.error &&
                      friendsVM.searchError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              friendsVM.searchError!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Found user state
                  if (friendsVM.searchState == FriendSearchState.found &&
                      friendsVM.foundUser != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.purple,
                            child: Text(
                              friendsVM.foundUser!.name.isNotEmpty
                                  ? friendsVM.foundUser!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friendsVM.foundUser!.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  friendsVM.foundUser!.email,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    friendsVM.resetSearchDialog();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                if (friendsVM.searchState != FriendSearchState.found)
                  ElevatedButton(
                    onPressed: friendsVM.isSearching
                        ? null
                        : () {
                      friendsVM.searchFriend(
                        email: emailController.text,
                        currentUser: currentUser,
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: const Text('Search', style: TextStyle(color: Colors.white)),
                  ),
                if (friendsVM.searchState == FriendSearchState.found &&
                    friendsVM.foundUser != null)
                  ElevatedButton(
                    onPressed: () async {
                      final success = await friendsVM.addFriend(
                        currentUser: currentUser,
                        friendToAdd: friendsVM.foundUser!,
                      );

                      if (success) {
                        // Update AuthViewModel's friend list
                        await authViewModel.addFriend(friendsVM.foundUser!);

                        friendsVM.resetSearchDialog();
                        Navigator.pop(dialogContext);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${friendsVM.foundUser!.name} added as friend!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Add Friend', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        ),
      ),
    ).then((_) {
      // Reset search state when dialog closes
      _friendsViewModel.resetSearchDialog();
    });
  }

  void _showRemoveFriendDialog(BuildContext context, AppUser friend) {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${friend.name} from your friends?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _friendsViewModel.removeFriend(
                userId: currentUser.id,
                friendId: friend.id,
              );

              if (success) {
                // Update AuthViewModel
                await authViewModel.removeFriend(friend.id);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}