import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/api_service.dart';
import '../data/services/storage_service.dart';

// ── Infrastructure providers ──────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Override at ProviderScope'),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(
    ref.read(secureStorageProvider),
    ref.read(sharedPreferencesProvider),
  );
});

final apiServiceProvider = Provider<ApiService>((_) => ApiService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiServiceProvider),
    ref.read(storageServiceProvider),
  );
});

// ── Auth state ────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthInitial());

  Future<void> checkAuth() async {
    state = const AuthLoading();
    try {
      final user = await _repo.restoreSession();
      state =
          user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<bool> login(String username, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repo.login(username, password);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  void clearError() {
    if (state is AuthError) state = const AuthUnauthenticated();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
