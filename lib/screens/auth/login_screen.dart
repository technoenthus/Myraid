import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authProvider.notifier).login(
          _usernameCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (success && mounted) {
      // Trigger initial task load
      ref.read(taskProvider.notifier).loadTasks(refresh: true);
      context.go('/home');
    }
  }

  void _fillDemoCredentials() {
    _usernameCtrl.text = 'Disha';
    _passwordCtrl.text = 'Dishapass';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final errorMsg =
        authState is AuthError ? (authState).message : null;

    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.08),
                // Logo + title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.task_alt_rounded,
                          size: 44,
                          color: colorScheme.primary,
                        ),
                      )
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      )
                          .animate()
                          .fadeIn(delay: 150.ms)
                          .slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to continue managing your tasks',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.06),
                // Error banner
                if (errorMsg != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: colorScheme.onErrorContainer, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMsg,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: colorScheme.onErrorContainer, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              ref.read(authProvider.notifier).clearError(),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.3, end: 0),
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Username',
                        hint: 'Enter your username',
                        controller: _usernameCtrl,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: Validators.validateUsername,
                        textInputAction: TextInputAction.next,
                      )
                          .animate()
                          .fadeIn(delay: 250.ms)
                          .slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordCtrl,
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: Validators.validatePassword,
                        textInputAction: TextInputAction.done,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _fillDemoCredentials,
                          child: const Text('Use Demo Credentials'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Sign In',
                        onPressed: _login,
                        isLoading: isLoading,
                        icon: Icons.login_rounded,
                      )
                          .animate()
                          .fadeIn(delay: 350.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Demo credentials info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: colorScheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Demo: username: Disha  •  password: Dishapass',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push('/login/register'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 450.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
