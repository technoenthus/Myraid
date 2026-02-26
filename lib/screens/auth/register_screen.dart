import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    // Save account to local storage so the user can log in with these credentials.
    await ref.read(storageServiceProvider).registerLocalUser(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Account created! Please sign in.'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut),
                ),
                const SizedBox(height: 24),
                Text(
                  'Personal Info',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'First Name',
                        controller: _firstNameCtrl,
                        prefixIcon: Icons.badge_outlined,
                        validator: (v) =>
                            Validators.validateRequired(v, fieldName: 'First name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Last Name',
                        controller: _lastNameCtrl,
                        prefixIcon: Icons.badge_outlined,
                        validator: (v) =>
                            Validators.validateRequired(v, fieldName: 'Last name'),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                )
                    .animate()
                    .fadeIn(delay: 150.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 24),
                Text(
                  'Account Details',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Username',
                  hint: 'Choose a username',
                  controller: _usernameCtrl,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: Validators.validateUsername,
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  hint: 'Min. 6 characters',
                  controller: _passwordCtrl,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: Validators.validatePassword,
                )
                    .animate()
                    .fadeIn(delay: 250.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm Password',
                  controller: _confirmCtrl,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (v) =>
                      Validators.validateConfirmPassword(v, _passwordCtrl.text),
                  textInputAction: TextInputAction.done,
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Create Account',
                  onPressed: _register,
                  isLoading: _isLoading,
                  icon: Icons.person_add_rounded,
                )
                    .animate()
                    .fadeIn(delay: 350.ms),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Note: This app uses DummyJSON for authentication. Registration is a UI demo — use the demo credentials on the login screen to sign in.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                    textAlign: TextAlign.center,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
