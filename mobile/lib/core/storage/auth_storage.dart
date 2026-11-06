import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _keyAccessToken = 'duo_access_token';
  static const String _keyRefreshToken = 'duo_refresh_token';
  static const String _keyUserData = 'duo_user_data';

  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUserData, jsonEncode(user));
  }

  static Future<void> updateAccessToken(String newAccessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, newAccessToken);
  }

  static Future<void> updateRefreshToken(String newRefreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRefreshToken, newRefreshToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserData);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserData);
  }

  static Future<void> clearAuth() async => await clear();
}

