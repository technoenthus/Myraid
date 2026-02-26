import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';

class AuthRepository {
  final ApiService _api;
  final StorageService _storage;

  AuthRepository(this._api, this._storage);

  Future<UserModel> login(String username, String password) async {
    // Check locally registered users first (e.g. accounts created via Register screen).
    final localData = _storage.getLocalUser(username);
    if (localData != null) {
      if (localData['password'] != password) {
        throw AppException.unknown('Invalid username or password.');
      }
      final token = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final user = UserModel(
        id: localData['id'] as int,
        username: localData['username'] as String,
        email: localData['email'] as String,
        firstName: localData['firstName'] as String,
        lastName: localData['lastName'] as String,
        token: token,
      );
      await _storage.saveToken(token);
      await _storage.saveUser(user.toJson());
      return user;
    }

    // Fall back to DummyJSON API for pre-seeded accounts (emilys, etc.).
    final response = await _api.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
        'expiresInMins': 60,
      },
    );

    final user = UserModel.fromJson(response);

    if (user.token != null) {
      await _storage.saveToken(user.token!);
      _api.updateToken(user.token!);
    }
    if (user.refreshToken != null) {
      await _storage.saveRefreshToken(user.refreshToken!);
    }
    await _storage.saveUser(user.toJson());
    return user;
  }

  Future<UserModel?> restoreSession() async {
    final token = await _storage.getToken();
    if (token == null) return null;

    // Local accounts don't need API verification — just restore from cache.
    if (token.startsWith('local_')) {
      final cached = _storage.getUser();
      return cached != null ? UserModel.fromJson(cached) : null;
    }

    _api.updateToken(token);

    try {
      final response = await _api.get(ApiConstants.currentUser);
      final data = response as Map<String, dynamic>;
      // Merge token back (GET /auth/me doesn't return tokens)
      data['accessToken'] = token;
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) data['refreshToken'] = refreshToken;
      final user = UserModel.fromJson(data);
      await _storage.saveUser(user.toJson());
      return user;
    } on AppException catch (e) {
      if (e.statusCode == 401) {
        await logout();
        return null;
      }
      // Network error – return cached user
      final cached = _storage.getUser();
      return cached != null ? UserModel.fromJson(cached) : null;
    }
  }

  Future<void> logout() async {
    _api.clearToken();
    // Only clear auth data — task cache is kept so tasks survive logout/login.
    // Tasks are filtered by userId in TaskRepository, so users can't see each other's data.
    await _storage.clearTokens();
    await _storage.clearUser();
  }
}
