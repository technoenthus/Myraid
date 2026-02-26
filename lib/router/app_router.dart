import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/task_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/task/task_form_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const TaskFormScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final task = state.extra as TaskModel;
              return TaskFormScreen(task: task);
            },
          ),
        ],
      ),
    ],
  );
});
