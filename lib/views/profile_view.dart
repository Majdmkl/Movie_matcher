import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/swipe_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Consumer2<AuthViewModel, SwipeViewModel>(
        builder: (context, authViewModel, swipeViewModel, child) {
          final user = authViewModel.currentUser;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.purple,
                  child: Text(
                    user?.name.isNotEmpty == true 
                        ? user!.name[0].toUpperCase() 
                        : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name
                Text(
                  user?.name ?? 'Guest User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Member since
                if (user != null)
                  Text(
                    'Member since ${_formatDate(user.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 32),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'Likes',
                      swipeViewModel.likedCount.toString(),
                      Icons.favorite,
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Saved',
                      (user?.likedMovieIds.length ?? 0).toString(),
                      Icons.bookmark,
                      Colors.blue,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Edit name button
                OutlinedButton.icon(
                  onPressed: () => _showEditNameDialog(context, authViewModel),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Name'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),

                const Spacer(),

                // Success indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Steg 5 fungerar!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showEditNameDialog(BuildContext context, AuthViewModel authViewModel) {
    final controller = TextEditingController(text: authViewModel.currentUser?.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.purple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                authViewModel.updateName(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthViewModel>().logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}