import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/language_selection_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // DEV MODE: Always bypass to home screen
    return const HomeScreen();
  }
}
