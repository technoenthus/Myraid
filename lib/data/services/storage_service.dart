import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'cached_user';
  static const _tasksKey = 'cached_tasks';
  static const _themeKey = 'is_dark_mode';
  static const _localUsersKey = 'local_registered_users';

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  StorageService(this._secure, this._prefs);

  // ── Secure token storage ──────────────────────────────────────────────────

  Future<void> saveToken(String token) =>
      _secure.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _secure.read(key: _tokenKey);

  Future<void> saveRefreshToken(String token) =>
      _secure.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _secure.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _secure.delete(key: _tokenKey);
    await _secure.delete(key: _refreshTokenKey);
  }

  // ── User data (SharedPreferences) ─────────────────────────────────────────

  Future<void> saveUser(Map<String, dynamic> userJson) =>
      _prefs.setString(_userKey, jsonEncode(userJson));

  Map<String, dynamic>? getUser() {
    final data = _prefs.getString(_userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearUser() => _prefs.remove(_userKey);

  // ── Local registered users ─────────────────────────────────────────────────

  Future<void> registerLocalUser({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final users = _localUsersMap;
    final id = 900000 + users.length + 1;
    users[username.toLowerCase()] = {
      'id': id,
      'username': username,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
    await _prefs.setString(_localUsersKey, jsonEncode(users));
  }

  Map<String, dynamic>? getLocalUser(String username) =>
      _localUsersMap[username.toLowerCase()] as Map<String, dynamic>?;

  Map<String, dynamic> get _localUsersMap {
    final data = _prefs.getString(_localUsersKey);
    if (data == null) return {};
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // ── Task cache ────────────────────────────────────────────────────────────

  Future<void> saveTasks(List<TaskModel> tasks) {
    final list = tasks.map((t) => t.toLocalJson()).toList();
    return _prefs.setString(_tasksKey, jsonEncode(list));
  }

  List<TaskModel> getCachedTasks() {
    final data = _prefs.getString(_tasksKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list
        .map((e) => TaskModel.fromLocalJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearTasks() => _prefs.remove(_tasksKey);

  // ── Theme ─────────────────────────────────────────────────────────────────

  Future<void> saveThemeMode(bool isDark) =>
      _prefs.setBool(_themeKey, isDark);

  bool? getSavedThemeMode() => _prefs.getBool(_themeKey);

  // ── Full logout ───────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
    await clearTasks();
  }
}
