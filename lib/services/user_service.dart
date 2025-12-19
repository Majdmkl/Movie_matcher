/*
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Skapa ny användare
  Future<void> createUser(User user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(user.toJson());
      print('✅ User created: ${user.name}');
    } catch (e) {
      print('❌ Error creating user: $e');
      throw Exception('Could not create user: $e');
    }
  }

  // Hämta användare
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  // Hämta alla användare
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  // Lägg till liked movie
  Future<void> addLikedMovie(String userId, int movieId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'liked_movie_ids': FieldValue.arrayUnion([movieId]),
      });
      print('✅ Added liked movie: $movieId');
    } catch (e) {
      print('❌ Error adding liked movie: $e');
    }
  }

  // Ta bort liked movie
  Future<void> removeLikedMovie(String userId, int movieId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'liked_movie_ids': FieldValue.arrayRemove([movieId]),
      });
      print('✅ Removed liked movie: $movieId');
    } catch (e) {
      print('❌ Error removing liked movie: $e');
    }
  }

  // Uppdatera användarnamn
  Future<void> updateUserName(String userId, String newName) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'name': newName,
      });
      print('✅ Updated user name: $newName');
    } catch (e) {
      print('❌ Error updating user name: $e');
    }
  }

  // Lyssna på användare (real-time)
  Stream<User?> userStream(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // Lyssna på alla användare (real-time)
  Stream<List<User>> allUsersStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
    });
  }
}
*/