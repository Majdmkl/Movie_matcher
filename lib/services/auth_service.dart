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
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      final appUser = AppUser(
        id: credential.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      // Spara till Firestore - vänta inte för länge
      _saveUserToFirestore(appUser);

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

  // Spara användare till Firestore (async, ingen väntan)
  Future<void> _saveUserToFirestore(AppUser user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
      print('✅ User saved to Firestore');
    } catch (e) {
      print('⚠️ Could not save user to Firestore: $e');
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
      );

      if (credential.user == null) {
        throw Exception('Failed to login');
      }

      AppUser? appUser = await getUser(credential.user!.uid);

      if (appUser == null) {
        appUser = AppUser(
          id: credential.user!.uid,
          email: email,
          name: email.split('@')[0],
        );
        _saveUserToFirestore(appUser);
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

  Future<void> logout() async {
    await _auth.signOut();
    print('✅ User logged out');
  }

  // Hämta användare från Firestore
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  // Lägg till liked movie - FIRE AND FORGET (ingen timeout)
  void addLikedMovie(String userId, int movieId) {
    _firestore.collection(_collection).doc(userId).update({
      'liked_movie_ids': FieldValue.arrayUnion([movieId]),
    }).then((_) {
      print('✅ Saved like to Firebase: $movieId');
    }).catchError((e) {
      print('⚠️ Could not save like to Firebase: $e');
    });
  }

  // Ta bort liked movie
  void removeLikedMovie(String userId, int movieId) {
    _firestore.collection(_collection).doc(userId).update({
      'liked_movie_ids': FieldValue.arrayRemove([movieId]),
    }).then((_) {
      print('✅ Removed like from Firebase: $movieId');
    }).catchError((e) {
      print('⚠️ Could not remove like from Firebase: $e');
    });
  }

  // Uppdatera namn
  void updateName(String userId, String newName) {
    _firestore.collection(_collection).doc(userId).update({
      'name': newName,
    }).then((_) {
      print('✅ Updated name in Firebase');
    }).catchError((e) {
      print('⚠️ Could not update name in Firebase: $e');
    });
  }

  // === FRIENDS FUNKTIONER ===

  // Sök användare via email
  Future<AppUser?> searchUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return AppUser.fromJson(query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Error searching user: $e');
      return null;
    }
  }

  // Lägg till vän
  Future<bool> addFriend(String userId, String friendId) async {
    try {
      // Lägg till i båda riktningar
      await _firestore.collection(_collection).doc(userId).update({
        'friend_ids': FieldValue.arrayUnion([friendId]),
      });
      
      await _firestore.collection(_collection).doc(friendId).update({
        'friend_ids': FieldValue.arrayUnion([userId]),
      });

      print('✅ Added friend: $friendId');
      return true;
    } catch (e) {
      print('❌ Error adding friend: $e');
      return false;
    }
  }

  // Ta bort vän
  Future<bool> removeFriend(String userId, String friendId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'friend_ids': FieldValue.arrayRemove([friendId]),
      });
      
      await _firestore.collection(_collection).doc(friendId).update({
        'friend_ids': FieldValue.arrayRemove([userId]),
      });

      print('✅ Removed friend: $friendId');
      return true;
    } catch (e) {
      print('❌ Error removing friend: $e');
      return false;
    }
  }

  // Hämta vänner
  Future<List<AppUser>> getFriends(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];

    try {
      final List<AppUser> friends = [];
      
      // Hämta i batches om 10 (Firestore begränsning)
      for (int i = 0; i < friendIds.length; i += 10) {
        final batch = friendIds.skip(i).take(10).toList();
        final query = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        friends.addAll(query.docs.map((doc) => AppUser.fromJson(doc.data())));
      }

      return friends;
    } catch (e) {
      print('❌ Error getting friends: $e');
      return [];
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