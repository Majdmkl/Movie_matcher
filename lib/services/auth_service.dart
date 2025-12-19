import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrera ny användare
  Future<AppUser?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Skapa Firebase Auth användare (med timeout)
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Registration timeout'),
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      // 2. Skapa AppUser objekt
      final appUser = AppUser(
        id: credential.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      // 3. Spara till Firestore (med timeout, men fortsätt även om det misslyckas)
      try {
        await _firestore
            .collection(_collection)
            .doc(appUser.id)
            .set(appUser.toJson())
            .timeout(const Duration(seconds: 5));
        print('✅ User saved to Firestore');
      } catch (e) {
        print('⚠️ Could not save to Firestore (will retry later): $e');
        // Fortsätt ändå - användaren är skapad i Auth
      }

      print('✅ User registered: ${appUser.email}');
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Register error: $e');
      rethrow;
    }
  }

  // Logga in
  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Login timeout'),
      );

      if (credential.user == null) {
        throw Exception('Failed to login');
      }

      // Försök hämta från Firestore med timeout
      AppUser? appUser;
      try {
        appUser = await getUser(credential.user!.uid);
      } catch (e) {
        print('⚠️ Could not fetch user data from Firestore: $e');
      }

      // Om vi inte fick data från Firestore, skapa ett lokalt objekt
      if (appUser == null) {
        appUser = AppUser(
          id: credential.user!.uid,
          email: email,
          name: email.split('@')[0], // Använd email-prefix som namn
        );
      }

      print('✅ User logged in: ${appUser.email}');
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  // Logga ut
  Future<void> logout() async {
    await _auth.signOut();
    print('✅ User logged out');
  }

  // Hämta användare från Firestore (med timeout)
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 5));
      
      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  // Lägg till liked movie (fire and forget - ingen väntan)
  Future<void> addLikedMovie(String userId, int movieId) async {
    try {
      _firestore.collection(_collection).doc(userId).update({
        'liked_movie_ids': FieldValue.arrayUnion([movieId]),
      }).timeout(const Duration(seconds: 3)).catchError((e) {
        print('⚠️ Could not save like: $e');
      });
      print('✅ Added liked movie: $movieId');
    } catch (e) {
      print('⚠️ Error adding liked movie: $e');
    }
  }

  // Ta bort liked movie
  Future<void> removeLikedMovie(String userId, int movieId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'liked_movie_ids': FieldValue.arrayRemove([movieId]),
      }).timeout(const Duration(seconds: 3));
    } catch (e) {
      print('⚠️ Error removing liked movie: $e');
    }
  }

  // Uppdatera namn
  Future<void> updateName(String userId, String newName) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'name': newName,
      }).timeout(const Duration(seconds: 3));
    } catch (e) {
      print('⚠️ Error updating name: $e');
    }
  }

  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}