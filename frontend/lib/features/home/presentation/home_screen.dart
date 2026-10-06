import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/presentation/providers/language_provider.dart';
import '../../assistant/presentation/assistant_screen.dart';
import '../../disease_detection/presentation/disease_scan_screen.dart';
import '../../dams/presentation/dams_screen.dart';
import '../../weather/presentation/weather_screen.dart';
import 'dart:math';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(languageProvider) == 'ta';

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(context, ref, isTamil),
                  const SizedBox(height: 14),
                  
                  // Hero banner with farmer image
                  _buildHeroBanner(context, isTamil),
                  
                  // Dotted divider
                  _buildDotDivider(),
                  
                  // Section label
                  _buildSectionLabel(isTamil ? 'இன்று என்ன வேண்டும்?' : 'What do you need today?'),
                  const SizedBox(height: 10),
                  
                  // 2x2 Feature Grid
                  _buildFeatureGrid(context, isTamil),
                  
                  // Dotted divider
                  _buildDotDivider(),
                  
                  // Farming tip card
                  _buildTipCard(context, isTamil),
                ],
              ),
            ),
            
            // Floating mic button
            Positioned(
              right: 18,
              bottom: 20,
              child: _buildMicButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isTamil) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTamil ? 'ஹார்வெஸ்ட்லிங்க்' : 'HarvestLink',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 2,
                  color: AppColors.sub,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isTamil ? 'காலை வணக்கம்,\nவிவசாயி' : 'Good morning,\nfarmer',
                style: GoogleFonts.fraunces(
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  height: 1.05,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        
        // Language toggle
        _buildLangToggle(ref, isTamil),
      ],
    );
  }

  Widget _buildLangToggle(WidgetRef ref, bool isTamil) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langBtn('EN', !isTamil, () {
            ref.read(languageProvider.notifier).setLanguage('en');
          }),
          _langBtn('த', isTamil, () {
            ref.read(languageProvider.notifier).setLanguage('ta');
          }),
        ],
      ),
    );
  }

  Widget _langBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        color: active ? AppColors.ink : AppColors.card,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: active ? AppColors.paper : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isTamil) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 2.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(5, 5)),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/farmer_sowing.jpeg'),
          fit: BoxFit.cover,
          alignment: Alignment(0.3, 0),
        ),
      ),
      child: Stack(
        children: [
          // Stamp overlay at bottom-left
          Positioned(
            left: 10,
            bottom: 10,
            right: 60,
            child: Transform.rotate(
              angle: -1.2 * pi / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTamil ? 'விதைக்க நல்ல நாள்' : 'Good day to sow',
                      style: GoogleFonts.fraunces(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      isTamil ? 'நாளை லேசான மழை · 29°C' : 'Light rain tomorrow · 29°C',
                      style: const TextStyle(fontSize: 13, color: AppColors.sub),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotDivider() {
    return Container(
      height: 10,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: CustomPaint(
        painter: _DotPainter(),
        size: const Size(double.infinity, 10),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        letterSpacing: 2,
        fontWeight: FontWeight.w800,
        color: AppColors.sub,
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, bool isTamil) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      children: [
        _FeatureTile(
          color: AppColors.tileGreen,
          textColor: AppColors.ink,
          icon: Icons.eco,
          title: isTamil ? 'பயிர் மருத்துவர்' : 'Crop Doctor',
          subtitle: isTamil ? 'நோய் இலையை ஸ்கேன் செய்' : 'Scan a sick leaf',
          tiltDeg: -0.8,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DiseaseScanScreen()),
          ),
        ),
        _FeatureTile(
          color: AppColors.tileGold,
          textColor: AppColors.ink,
          icon: Icons.wb_sunny,
          title: isTamil ? 'வானிலை' : 'Weather',
          subtitle: isTamil ? 'வரும் வாரம்' : 'Week ahead',
          tiltDeg: 0.8,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WeatherScreen()),
          ),
        ),
        _FeatureTile(
          color: AppColors.tileIndigo,
          textColor: AppColors.textLight,
          icon: Icons.water,
          title: isTamil ? 'அணை நிலவரம்' : 'Dam Levels',
          subtitle: isTamil ? 'நீர்மட்டம்' : 'Water & release',
          tiltDeg: -0.8,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DamsScreen()),
          ),
        ),
        _FeatureTile(
          color: AppColors.tileTerra,
          textColor: AppColors.textLight,
          icon: Icons.mic,
          title: isTamil ? 'குரலில் கேள்' : 'Ask by Voice',
          subtitle: isTamil ? 'தமிழ் / ஆங்கிலம்' : 'Tamil or English',
          tiltDeg: 0.8,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AssistantScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(BuildContext context, bool isTamil) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: AppColors.ink, width: 2.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.turmeric, offset: Offset(5, 5)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: Image.asset(
              'assets/images/farmer_planting.jpeg',
              width: 112,
              height: 112,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTamil ? 'மழைக்குப் பின் நடவு' : 'Transplant after rain',
                    style: GoogleFonts.fraunces(
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                      height: 1.15,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTamil 
                        ? 'ஈர மண்ணில் நாற்று நன்றாக பிடிக்கும்.' 
                        : 'Wet soil holds seedlings better.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AssistantScreen()),
      ),
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: AppColors.turmeric,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: const [
            BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
          ],
        ),
        child: const Icon(Icons.mic, size: 32, color: AppColors.ink),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final double tiltDeg;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tiltDeg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: tiltDeg * pi / 180,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.ink, width: 2.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 44, color: textColor),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fraunces(
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                      height: 1.1,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    
    const spacing = 14.0;
    const radius = 1.6;
    final count = (size.width / spacing).floor();
    
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(i * spacing + spacing / 2, size.height / 2),
        radius,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
