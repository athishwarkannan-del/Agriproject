import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
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
  bool _initialized = false;

  @override
  DiseaseState build() {
    if (!_initialized) {
      _initAudio();
      _initialized = true;
    }
    ref.onDispose(() {
      stopSpeaking();
    });
    return DiseaseState();
  }

  void _initAudio() {
    try {
      // Configure audio routing: max speakerphone output with media audio focus
      final audioContext = AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      );
      AudioPlayer.global.setAudioContext(audioContext);
    } catch (e) {
      debugPrint('[CropDoctor Voice] AudioContext setup: $e');
    }

    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      debugPrint('[CropDoctor Voice] Player state: $playerState');
      if (playerState == PlayerState.completed || playerState == PlayerState.stopped) {
        if (state.isSpeaking) {
          state = state.copyWith(isSpeaking: false);
        }
      }
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('[CropDoctor Voice] FlutterTts completed');
      if (state.isSpeaking) {
        state = state.copyWith(isSpeaking: false);
      }
    });

    _flutterTts.setErrorHandler((err) {
      debugPrint('[CropDoctor Voice] FlutterTts error: $err');
      if (state.isSpeaking) {
        state = state.copyWith(isSpeaking: false);
      }
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
      recsList = recsRaw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else if (recsRaw is String && recsRaw.trim().isNotEmpty) {
      recsList = [recsRaw.trim()];
    }

    // Pick top recommendation item for concise, instant synthesis
    final firstRec = recsList.isNotEmpty ? recsList.first : '';

    if (isTamil) {
      if (isHealthy) {
        return '$crop பயிர் ஆரோக்கியமாக உள்ளது. எந்த நோயும் கண்டறியப்படவில்லை.';
      } else {
        String text = '$crop பயிரில் $disease கண்டறியப்பட்டுள்ளது.';
        if (firstRec.isNotEmpty) {
          text += ' முக்கிய பரிந்துரை: $firstRec.';
        }
        return text;
      }
    } else {
      if (isHealthy) {
        return 'Your $crop plant is healthy. No disease detected.';
      } else {
        String text = '$crop has been diagnosed with $disease.';
        if (firstRec.isNotEmpty) {
          text += ' Key advice: $firstRec.';
        }
        return text;
      }
    }
  }

  Future<void> _speakWithFlutterTts(String text, bool isTamil) async {
    debugPrint('[CropDoctor Voice] Attempting local FlutterTts speech: $text');
    try {
      await _flutterTts.stop();
      if (isTamil) {
        try {
          await _flutterTts.setLanguage('ta-IN');
        } catch (_) {
          await _flutterTts.setLanguage('ta');
        }
      } else {
        await _flutterTts.setLanguage('en-US');
      }
      await _flutterTts.setSpeechRate(0.5); // Standard 0.5 normal speed on Android
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      final res = await _flutterTts.speak(text);
      debugPrint('[CropDoctor Voice] FlutterTts result: $res');
    } catch (e) {
      debugPrint('[CropDoctor Voice] FlutterTts exception: $e');
      if (state.isSpeaking) {
        state = state.copyWith(isSpeaking: false);
      }
    }
  }

  Future<void> speakDiagnosis({
    Map<String, dynamic>? resultData,
    bool toggleIfSpeaking = false,
  }) async {
    // If user tapped listen/stop button while already speaking, stop playback
    if (toggleIfSpeaking && state.isSpeaking) {
      debugPrint('[CropDoctor Voice] Stopping speech on user toggle');
      await stopSpeaking();
      return;
    }

    // Stop any previous speech before starting
    await stopSpeaking();

    final result = resultData ?? state.result;
    if (result == null) {
      debugPrint('[CropDoctor Voice] No result data found to speak');
      return;
    }

    final lang = ref.read(languageProvider);
    final isTamil = lang == 'ta';
    final textToSpeak = _buildDiagnosisSpeechText(result, isTamil);

    debugPrint('[CropDoctor Voice] Speaking text: $textToSpeak');
    state = state.copyWith(isSpeaking: true);

    // ── Method 1: ElevenLabs Multilingual TTS via backend POST -> DeviceFileSource ──
    try {
      debugPrint('[CropDoctor Voice] Requesting ElevenLabs audio from backend: ${ApiEndpoints.assistantTts}');
      final response = await ref.read(apiClientProvider).post(
        ApiEndpoints.assistantTts,
        data: {'text': textToSpeak, 'language': lang},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(List<int>.from(response.data));
        debugPrint('[CropDoctor Voice] Received ${bytes.length} audio bytes from ElevenLabs');
        
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/crop_diagnosis_voice.mp3');
        await audioFile.writeAsBytes(bytes, flush: true);

        await _audioPlayer.stop();
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(DeviceFileSource(audioFile.path));
        debugPrint('[CropDoctor Voice] DeviceFileSource launched successfully');
        return;
      }
    } catch (downloadErr) {
      debugPrint('[CropDoctor Voice] ElevenLabs backend TTS failed: $downloadErr. Falling back to local TTS...');
    }

    // ── Method 2: Fallback to on-device TTS engine ────────────────
    await _speakWithFlutterTts(textToSpeak, isTamil);
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

      final Map<String, dynamic> resultData = Map<String, dynamic>.from(response.data);

      state = state.copyWith(
        isAnalyzing: false,
        result: resultData,
      );

      // Automatically speak out the disease name and suggestions immediately!
      await speakDiagnosis(resultData: resultData, toggleIfSpeaking: false);
      
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
