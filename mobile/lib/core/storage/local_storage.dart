import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserData = 'user_data';
  static const _keyDeviceId = 'device_id';
  static const _keyCustomHost = 'custom_host';

  static Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setString(_keyRefreshToken, refreshToken);
    } catch (_) {}
  }

  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _keyAccessToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccessToken);
    } catch (_) {}
    return null;
  }

  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _keyRefreshToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    } catch (_) {}
    return null;
  }

  static Future<void> clearSession() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserData);
    } catch (_) {}
  }

  static Future<void> saveUserData(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonString);
  }

  static Future<void> saveUser(dynamic user) async {
    if (user != null) {
      try {
        await saveUserData(jsonEncode(user.toJson()));
      } catch (_) {}
    }
  }

  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserData);
  }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_keyDeviceId);
    if (id == null) {
      final randSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
      id = 'DEV-$randSuffix';
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  static Future<void> saveCustomHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomHost, host);
  }

  static Future<String?> getCustomHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomHost);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
