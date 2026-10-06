import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/presentation/providers/language_provider.dart';
import 'providers/disease_provider.dart';

class DiseaseScanScreen extends ConsumerWidget {
  const DiseaseScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final state = ref.watch(diseaseProvider);

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
          isTamil ? 'பயிர் மருத்துவர்' : 'Crop Doctor',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Viewfinder / Image preview
            _buildViewfinder(context, ref, state),
            const SizedBox(height: 16),
            
            // Action buttons
            _buildActionButtons(context, ref, state, isTamil),
            const SizedBox(height: 16),
            
            // Analysis button
            if (state.selectedImage != null && !state.isAnalyzing && state.result == null)
              _buildAnalyzeButton(ref, isTamil),
            
            // Loading
            if (state.isAnalyzing)
              _buildAnalyzing(isTamil),
            
            // Results
            if (state.result != null)
              _buildResults(context, state, isTamil),
            
            // Error
            if (state.error != null)
              _buildError(state.error!),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder(BuildContext context, WidgetRef ref, DiseaseState state) {
    return Container(
      height: 270,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: AppColors.ink, width: 2.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: state.selectedImage != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: kIsWeb
                      ? Image.network(
                          state.selectedImage!.path,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(state.selectedImage!.path),
                          fit: BoxFit.cover,
                        ),
                ),
                // Corner brackets
                ..._buildCornerBrackets(),
              ],
            )
          : Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.eco, size: 64, color: AppColors.turmeric.withValues(alpha: 0.6)),
                      const SizedBox(height: 12),
                      Text(
                        'Scan a leaf',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                      ),
                    ],
                  ),
                ),
                ..._buildCornerBrackets(),
              ],
            ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const bracketSize = 34.0;
    const bracketWidth = 4.0;
    const color = AppColors.turmeric;
    const offset = 14.0;
    
    return [
      // Top-left
      Positioned(
        top: offset, left: offset,
        child: Container(
          width: bracketSize, height: bracketSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: bracketWidth),
              left: BorderSide(color: color, width: bracketWidth),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: offset, right: offset,
        child: Container(
          width: bracketSize, height: bracketSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: bracketWidth),
              right: BorderSide(color: color, width: bracketWidth),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: offset, left: offset,
        child: Container(
          width: bracketSize, height: bracketSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: bracketWidth),
              left: BorderSide(color: color, width: bracketWidth),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: offset, right: offset,
        child: Container(
          width: bracketSize, height: bracketSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: bracketWidth),
              right: BorderSide(color: color, width: bracketWidth),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, DiseaseState state, bool isTamil) {
    return Row(
      children: [
        Expanded(
          child: _ArtisanButton(
            icon: Icons.camera_alt,
            label: isTamil ? 'கேமரா' : 'Camera',
            color: AppColors.tileGreen,
            onTap: () => ref.read(diseaseProvider.notifier).pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ArtisanButton(
            icon: Icons.photo_library,
            label: isTamil ? 'கேலரி' : 'Gallery',
            color: AppColors.tileGold,
            onTap: () => ref.read(diseaseProvider.notifier).pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton(WidgetRef ref, bool isTamil) {
    return GestureDetector(
      onTap: () => ref.read(diseaseProvider.notifier).analyzeImage(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.leaf,
          border: Border.all(color: AppColors.ink, width: 2.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
          ],
        ),
        child: Text(
          isTamil ? '🔬 பகுப்பாய்வு செய்' : '🔬 Analyze Leaf',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzing(bool isTamil) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.ink, width: 2.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.turmeric),
          const SizedBox(height: 12),
          Text(
            isTamil ? 'பகுப்பாய்வு செய்கிறது...' : 'Analyzing...',
            style: GoogleFonts.fraunces(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, DiseaseState state, bool isTamil) {
    final result = state.result!;
    
    final crop = result['crop'] ?? 'Unknown';
    final disease = result['disease'] ?? 'Unknown';
    final isHealthy = disease.toString().toLowerCase().contains('healthy');
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
    final confPercent = (confidence * 100).toStringAsFixed(1);
    
    final symptoms = result['symptoms'] ?? '';
    
    final recsRaw = result['recommendations'];
    String recommendations = '';
    if (recsRaw is List) {
      recommendations = recsRaw.join('\n• ');
      if (recommendations.isNotEmpty) recommendations = '• $recommendations';
    } else {
      recommendations = recsRaw?.toString() ?? '';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHealthy ? AppColors.tileGreen : AppColors.card,
        border: Border.all(color: AppColors.ink, width: 2.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isHealthy ? Icons.check_circle : Icons.warning_amber_rounded, 
                  color: isHealthy ? Colors.green.shade800 : AppColors.terracotta, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTamil ? 'முடிவு' : 'Diagnosis',
                  style: GoogleFonts.fraunces(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$confPercent%',
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.ink, thickness: 1, height: 24),
          
          _buildResultRow(isTamil ? 'பயிர்' : 'Crop', crop.toString()),
          const SizedBox(height: 8),
          _buildResultRow(isTamil ? 'நிலை' : 'Status', disease.toString(), isHighlight: !isHealthy),
          
          if (symptoms.toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(isTamil ? 'அறிகுறிகள்:' : 'Symptoms:', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sub)),
            const SizedBox(height: 4),
            Text(symptoms.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
          
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(isTamil ? 'பரிந்துரைகள்:' : 'Treatment / Advice:', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sub)),
            const SizedBox(height: 4),
            Text(recommendations, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.sub)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isHighlight ? AppColors.terracotta : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.terracotta, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(error, style: const TextStyle(color: AppColors.terracotta)),
    );
  }
}

class _ArtisanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ArtisanButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppColors.ink, width: 2.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.ink),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
