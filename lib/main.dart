import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/theme/app_theme.dart';
import 'data/services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prevent CORS font-fetch errors on web; fonts fall back to system Poppins.
  GoogleFonts.config.allowRuntimeFetching = false;
  final prefs = await SharedPreferences.getInstance();

  // Pre-seed the demo account so "Use Demo Credentials" works on a fresh install.
  await _seedDemoAccount(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

/// Seeds the demo account once so "Use Demo Credentials" always works.
Future<void> _seedDemoAccount(SharedPreferences prefs) async {
  const key = 'local_registered_users';
  final existing = prefs.getString(key);
  // Only seed if 'disha' isn't already registered.
  if (existing != null && existing.contains('"disha"')) return;

  // Reuse StorageService directly — no Riverpod needed at this point.
  const secure = AndroidOptions(encryptedSharedPreferences: true);
  final storage = StorageService(
    const FlutterSecureStorage(aOptions: secure),
    prefs,
  );
  await storage.registerLocalUser(
    username: 'Disha',
    password: 'Dishapass',
    firstName: 'Disha',
    lastName: 'Demo',
    email: 'disha@myraid.app',
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Myraid Tasks',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
