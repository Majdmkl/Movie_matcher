/*
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _userIdKey = 'current_user_id';
  static const String _userNameKey = 'current_user_name';

  // Spara user ID lokalt
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // Hämta user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Spara användarnamn lokalt
  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Hämta användarnamn
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Rensa all data (logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Kolla om användare finns
  Future<bool> hasUser() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }
}
*/