import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/storage_service.dart';
import 'auth_provider.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeNotifier(this._storage, bool? savedDark)
      : super(savedDark == null
            ? ThemeMode.system
            : savedDark
                ? ThemeMode.dark
                : ThemeMode.light);

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _storage.saveThemeMode(state == ThemeMode.dark);
  }

  bool get isDark => state == ThemeMode.dark;
}

final StateNotifierProvider<ThemeNotifier, ThemeMode> themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final storage = ref.read(storageServiceProvider);
  return ThemeNotifier(storage, storage.getSavedThemeMode());
});
