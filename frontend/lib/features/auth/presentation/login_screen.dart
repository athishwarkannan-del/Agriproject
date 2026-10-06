import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/presentation/providers/language_provider.dart';
import 'providers/auth_providers.dart';
import 'register_screen.dart';
import '../../home/presentation/home_screen.dart'; // Keep dev bypass for now

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final authState = ref.watch(authNotifierProvider);

    // Show error listener
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo/Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.tileGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
                    ],
                  ),
                  child: const Icon(Icons.eco, size: 50, color: AppColors.ink),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  isTamil ? 'உள்நுழைய' : 'Welcome Back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: isTamil ? 'மின்னஞ்சல்' : 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: 20),
                
                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: isTamil ? 'கடவுச்சொல்' : 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                
                const SizedBox(height: 40),
                
                // Login Button
                GestureDetector(
                  onTap: authState.isLoading ? null : () {
                    if (_formKey.currentState!.validate()) {
                      ref.read(authNotifierProvider.notifier).signIn(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.leaf,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
                      ],
                    ),
                    child: authState.isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.textLight))
                        : Text(
                            isTamil ? 'உள்நுழை' : 'Login',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Register Link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: Text(
                    isTamil ? 'கணக்கு இல்லையா? பதிவு செய்' : 'Don\'t have an account? Register',
                    style: const TextStyle(
                      color: AppColors.indigo,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Dev Mode Bypass
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'DEVELOPER MODE: Skip Login',
                    style: TextStyle(
                      color: AppColors.sub,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.ink, width: 2.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.sub, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: AppColors.ink),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }
}
