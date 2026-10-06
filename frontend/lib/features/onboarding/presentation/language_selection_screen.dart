import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/language_provider.dart';
import '../../auth/presentation/login_screen.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Icon
              const Icon(
                Icons.language,
                size: 80,
                color: AppColors.turmeric,
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Choose your language\nஉங்கள் மொழியைத் தேர்ந்தெடுக்கவும்',
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: AppColors.ink,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 48),
              
              // English Button
              _LanguageButton(
                title: 'English',
                subtitle: 'HarvestLink',
                color: AppColors.tileIndigo,
                textColor: AppColors.textLight,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('en');
                  _navigateToLogin(context);
                },
              ),
              
              const SizedBox(height: 20),
              
              // Tamil Button
              _LanguageButton(
                title: 'தமிழ்',
                subtitle: 'ஹார்வெஸ்ட்லிங்க்',
                color: AppColors.tileGold,
                textColor: AppColors.ink,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('ta');
                  _navigateToLogin(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppColors.ink, width: 2.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: textColor),
          ],
        ),
      ),
    );
  }
}
