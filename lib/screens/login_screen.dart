import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthService>().signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Top 35% Gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Welcome back 👋',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue managing your tasks.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Auth Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: 'Email Address',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                                  contentPadding: const EdgeInsets.all(18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                                  contentPadding: const EdgeInsets.all(18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (val) => (val == null || val.length < 6) ? 'Min 6 chars' : null,
                              ),
                              const SizedBox(height: 24),
                              // Sign In Button
                              Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6C63FF), Color(0xFF3B37CC)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C63FF).withAlpha(80),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: theme.dividerColor)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('OR', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                                  ),
                                  Expanded(child: Divider(color: theme.dividerColor)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Google Button
                              OutlinedButton.icon(
                                onPressed: () {}, // Add Google Auth Logic
                                icon: Image.network('https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg', width: 20, height: 20),
                                label: const Text('Continue with Google'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: theme.brightness == Brightness.dark ? Colors.transparent : Colors.white,
                                  foregroundColor: theme.colorScheme.onSurface,
                                  minimumSize: const Size(double.infinity, 54),
                                  side: BorderSide(color: theme.dividerColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?", style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(180))),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
                            },
                            child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

