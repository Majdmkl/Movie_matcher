import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/swipe_viewmodel.dart';
import 'views/home_view.dart';
import 'views/matches_view.dart';
import 'views/profile_view.dart';
import 'views/onboarding_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppLoader());
}

class AppLoader extends StatefulWidget {
  const AppLoader({Key? key}) : super(key: key);

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Timeout efter 10 sekunder
      await Firebase.initializeApp().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firebase connection timeout');
        },
      );
      
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      print('❌ Firebase error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Connection Error',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                      });
                      _initializeFirebase();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Loading state
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.movie_filter, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.purple),
                const SizedBox(height: 16),
                Text('Connecting...', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          ),
        ),
      );
    }

    return const MovieMatcherApp();
  }
}

class MovieMatcherApp extends StatelessWidget {
  const MovieMatcherApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // VIKTIGT: Använd INTE cascade (..) här!
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => SwipeViewModel()),
      ],
      child: MaterialApp(
        title: 'Movie Matcher',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.purple,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Timeout efter 5 sekunder
      await context.read<AuthViewModel>().initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Auth check timeout - continuing as guest');
        },
      );
    } catch (e) {
      print('❌ Auth check error: $e');
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (!authViewModel.isLoggedIn) {
          return const OnboardingView();
        }

        // Sätt user i SwipeViewModel
        context.read<SwipeViewModel>().setUser(authViewModel.currentUser!.id);

        return const MainNavigation();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeView(),
    const MatchesView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Swipe'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}