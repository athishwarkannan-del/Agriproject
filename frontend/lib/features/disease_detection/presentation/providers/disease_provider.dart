import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../onboarding/presentation/providers/language_provider.dart';

class DiseaseState {
  final XFile? selectedImage;
  final bool isAnalyzing;
  final bool isSpeaking;
  final String? error;
  final Map<String, dynamic>? result;

  DiseaseState({
    this.selectedImage,
    this.isAnalyzing = false,
    this.isSpeaking = false,
    this.error,
    this.result,
  });

  DiseaseState copyWith({
    XFile? selectedImage,
    bool? isAnalyzing,
    bool? isSpeaking,
    String? error,
    Map<String, dynamic>? result,
    bool clearResult = false,
  }) {
    return DiseaseState(
      selectedImage: selectedImage ?? this.selectedImage,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      error: error,
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

final diseaseProvider = NotifierProvider<DiseaseNotifier, DiseaseState>(DiseaseNotifier.new);

class DiseaseNotifier extends Notifier<DiseaseState> {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  DiseaseState build() {
    _initTts();
    ref.onDispose(() {
      stopSpeaking();
    });
    return DiseaseState();
  }

  Future<void> _initTts() async {
    _audioPlayer.onPlayerComplete.listen((_) {
      state = state.copyWith(isSpeaking: false);
    });
    await _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
  }

  Future<void> pickImage(ImageSource source) async {
    await stopSpeaking();
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(
          selectedImage: image, 
          error: null,
          clearResult: true,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick image: ${e.toString()}');
    }
  }

  void clearImage() {
    stopSpeaking();
    state = DiseaseState();
  }

  Future<void> stopSpeaking() async {
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
    } catch (_) {}
    if (state.isSpeaking) {
      state = state.copyWith(isSpeaking: false);
    }
  }

  String _buildDiagnosisSpeechText(Map<String, dynamic> result, bool isTamil) {
    final crop = result['crop']?.toString() ?? (isTamil ? 'பயிர்' : 'crop');
    final disease = result['disease']?.toString() ?? (isTamil ? 'ஆரோக்கியமானது' : 'Healthy');
    final isHealthy = disease.toLowerCase().contains('healthy') || disease.contains('ஆரோக்கிய');

    final recsRaw = result['recommendations'];
    List<String> recsList = [];
    if (recsRaw is List) {
      recsList = recsRaw.map((e) => e.toString().trim()).toList();
    } else if (recsRaw is String && recsRaw.trim().isNotEmpty) {
      recsList = [recsRaw.trim()];
    }

    final topRecs = recsList.take(2).join('. ');

    if (isTamil) {
      if (isHealthy) {
        return '$crop பயிர் ஆரோக்கியமாக உள்ளது. எந்த நோயும் கண்டறியப்படவில்லை.';
      } else {
        String text = '$crop பயிரில் $disease கண்டறியப்பட்டுள்ளது.';
        if (topRecs.isNotEmpty) {
          text += ' பரிந்துரை: $topRecs';
        }
        return text;
      }
    } else {
      if (isHealthy) {
        return 'Your $crop plant is healthy. No disease detected.';
      } else {
        String text = '$crop has been diagnosed with $disease.';
        if (topRecs.isNotEmpty) {
          text += ' Treatment advice: $topRecs';
        }
        return text;
      }
    }
  }

  Future<void> speakDiagnosis([String? customText]) async {
    final result = state.result;
    if (result == null && customText == null) return;

    if (state.isSpeaking) {
      await stopSpeaking();
      return;
    }

    final lang = ref.read(languageProvider);
    final isTamil = lang == 'ta';
    final textToSpeak = customText ?? _buildDiagnosisSpeechText(result!, isTamil);

    state = state.copyWith(isSpeaking: true);

    try {
      // 1. Try ElevenLabs TTS through backend API
      final response = await ref.read(apiClientProvider).post(
        ApiEndpoints.assistantTts,
        data: {'text': textToSpeak, 'language': lang},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(List<int>.from(response.data));
        await _audioPlayer.play(BytesSource(bytes));
        return;
      }
    } catch (_) {
      // Backend TTS failed or offline -> fallback to local on-device TTS
    }

    try {
      await _flutterTts.setLanguage(isTamil ? 'ta-IN' : 'en-US');
      await _flutterTts.setSpeechRate(0.9);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(textToSpeak);
    } catch (_) {
      state = state.copyWith(isSpeaking: false);
    }
  }

  Future<void> analyzeImage() async {
    if (state.selectedImage == null) return;

    await stopSpeaking();
    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      final lang = ref.read(languageProvider);
      final file = state.selectedImage!;
      
      final bytes = await file.readAsBytes();
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      });

      final response = await ref.read(apiClientProvider).post(
        ApiEndpoints.diseaseAnalyze,
        data: formData,
        queryParameters: {'language': lang},
      );

      state = state.copyWith(
        isAnalyzing: false,
        result: response.data,
      );

      // Automatically speak out the disease name and suggestions
      if (response.data != null) {
        speakDiagnosis();
      }
      
    } catch (e) {
      String errMsg = 'Analysis failed. Please try again.';
      if (e is DioException) {
         errMsg = e.response?.data?['detail'] ?? errMsg;
      }
      state = state.copyWith(
        isAnalyzing: false,
        error: errMsg,
      );
    }
  }
}
