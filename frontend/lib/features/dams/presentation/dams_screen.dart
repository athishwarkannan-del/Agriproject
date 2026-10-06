import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import '../../onboarding/presentation/providers/language_provider.dart';
import 'providers/dams_provider.dart';

class DamsScreen extends ConsumerWidget {
  const DamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final state = ref.watch(damsProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isTamil ? 'அணை நிலவரம்' : 'Dam Levels',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.ink),
            onPressed: () => ref.read(damsProvider.notifier).fetchDamsData(),
          ),
        ],
      ),
      body: _buildBody(context, state, isTamil),
    );
  }

  Widget _buildBody(BuildContext context, DamsState state, bool isTamil) {
    if (state.isLoading && state.dams.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.turmeric),
      );
    }

    if (state.error != null && state.dams.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.ink, width: 2.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.terracotta),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ProviderScope.containerOf(context)
                    .read(damsProvider.notifier)
                    .fetchDamsData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turmeric,
                  foregroundColor: AppColors.ink,
                ),
                child: Text(isTamil ? 'மீண்டும் முயற்சிக்க' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.dams.isEmpty) {
      return Center(
        child: Text(
          isTamil ? 'தரவு கிடைக்கவில்லை' : 'No data available',
          style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.turmeric,
      onRefresh: () => ProviderScope.containerOf(context)
          .read(damsProvider.notifier)
          .fetchDamsData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(18.0),
        itemCount: state.dams.length,
        itemBuilder: (context, index) {
          final dam = state.dams[index];
          // Use the percentage directly from the API
          double percentage = dam.percentage.clamp(0.0, 1.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 20.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.ink, width: 2.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: AppColors.ink, offset: Offset(5, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dam.name,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Water tank visual
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _WaterTank(fillPercentage: percentage),
                          const SizedBox(height: 8),
                          Text(
                            isTamil ? 'நீர்மட்டம்' : 'Level',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.sub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildStatBox(
                            isTamil ? 'கொள்ளளவு' : 'Capacity',
                            dam.capacity,
                            Icons.height,
                          ),
                          const SizedBox(height: 12),
                          _buildStatBox(
                            isTamil ? 'உள்வரத்து' : 'Inflow',
                            dam.inflow,
                            Icons.arrow_downward,
                          ),
                          const SizedBox(height: 12),
                          _buildStatBox(
                            isTamil ? 'வெளியேற்றம்' : 'Outflow',
                            dam.outflow,
                            Icons.arrow_upward,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.sub),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.sub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterTank extends StatefulWidget {
  final double fillPercentage;
  
  const _WaterTank({required this.fillPercentage});

  @override
  State<_WaterTank> createState() => _WaterTankState();
}

class _WaterTankState extends State<_WaterTank> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.ink, width: 2.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Animated Water
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(13),
              bottomRight: Radius.circular(13),
            ),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(
                    animation: _waveController,
                    fillPercentage: widget.fillPercentage,
                  ),
                  child: Container(
                    height: 140,
                  ),
                );
              },
            ),
          ),
          // Percentage Text
          Center(
            child: Text(
              '${(widget.fillPercentage * 100).toInt()}%',
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: widget.fillPercentage > 0.4 ? AppColors.textLight : AppColors.ink,
                shadows: widget.fillPercentage > 0.4 ? [
                  const Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))
                ] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Animation<double> animation;
  final double fillPercentage;

  _WavePainter({required this.animation, required this.fillPercentage}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0.0) return;

    final paint = Paint()
      ..color = AppColors.indigo
      ..style = PaintingStyle.fill;

    final waveHeight = size.height * fillPercentage;
    final baseY = size.height - waveHeight;
    
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    for (double i = 0; i <= size.width; i++) {
      // Create a moving wave effect
      final wave = math.sin((i / size.width * 2 * math.pi) + (animation.value * 2 * math.pi)) * 4;
      path.lineTo(i, baseY + wave);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
