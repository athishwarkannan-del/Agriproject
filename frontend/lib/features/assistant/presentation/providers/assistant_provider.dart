import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../onboarding/presentation/providers/language_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final String? audioPath; // for TTS playback state if needed

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.audioPath,
  });
}

class AssistantState {
  final List<ChatMessage> messages;
  final bool isListening;
  final bool isProcessing;
  final String? error;
  final String? recognizedText; // Temporary text while speaking

  AssistantState({
    this.messages = const [],
    this.isListening = false,
    this.isProcessing = false,
    this.error,
    this.recognizedText,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isListening,
    bool? isProcessing,
    String? error,
    String? recognizedText,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      recognizedText: recognizedText,
    );
  }
}

final assistantProvider = NotifierProvider<AssistantNotifier, AssistantState>(AssistantNotifier.new);

class AssistantNotifier extends Notifier<AssistantState> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _speechEnabled = false;
  String? _conversationId;

  @override
  AssistantState build() {
    _initSpeech();
    _initTts();
    
    // Add initial greeting based on language
    final isTamil = ref.read(languageProvider) == 'ta';
    return AssistantState(
      messages: [
        ChatMessage(
          text: isTamil 
              ? 'வணக்கம்! நான் ஹார்வெஸ்ட்லிங்க். நான் உங்களுக்கு எப்படி உதவ முடியும்?' 
              : 'Hello! I am HarvestLink. How can I help you today?',
          isUser: false,
        )
      ]
    );
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => _handleSpeechError(error.errorMsg),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _stopListening(manual: false);
        }
      },
    );
  }
  
  Future<void> _initTts() async {
    try {
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
    } catch (_) {}
    await _flutterTts.awaitSpeakCompletion(true);
  }

  void _handleSpeechError(String errorMsg) {
    if (state.isListening) {
      state = state.copyWith(
        isListening: false,
        error: errorMsg,
        recognizedText: null,
      );
    }
  }

  Future<void> toggleListening() async {
    if (state.isListening) {
      await _stopListening(manual: true);
    } else {
      // Explicitly request microphone permission
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        if (!_speechEnabled) {
          await _initSpeech();
        }
        await _startListening();
      } else {
        state = state.copyWith(error: 'Microphone permission denied');
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      state = state.copyWith(error: 'Speech recognition not available on this device');
      return;
    }

    final lang = ref.read(languageProvider);
    final localeId = lang == 'ta' ? 'ta-IN' : 'en-US';

    state = state.copyWith(
      isListening: true,
      error: null,
      recognizedText: '',
    );
    
    // Stop any ongoing TTS or audio playback
    await stopTts();

    await _speechToText.listen(
      onResult: (result) {
        state = state.copyWith(
          recognizedText: result.recognizedWords,
        );
      },
      localeId: localeId,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> _stopListening({required bool manual}) async {
    if (!state.isListening) return;

    if (manual) {
      await _speechToText.stop();
    }
    
    final words = state.recognizedText;
    state = state.copyWith(isListening: false, recognizedText: null);

    if (words != null && words.isNotEmpty) {
      await _processQuery(words);
    }
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _processQuery(text.trim());
  }

  Future<void> _processQuery(String text) async {
    // Add user message to UI
    final userMsg = ChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isProcessing: true,
      error: null,
    );

    try {
      final lang = ref.read(languageProvider);
      
      final response = await ref.read(apiClientProvider).post(
        ApiEndpoints.assistantQuery,
        data: {
          'message': text,
          'language': lang,
          'conversation_id': _conversationId,
        },
      );

      final data = response.data;
      _conversationId = data['conversation_id'];
      final answer = data['answer'];

      final botMsg = ChatMessage(text: answer, isUser: false);
      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isProcessing: false,
      );
      
      _speak(answer, lang);
      
    } catch (e) {
      String errMsg = 'Failed to get a response.';
      if (e is DioException) {
         errMsg = e.response?.data?['detail'] ?? errMsg;
      }
      
      final errorMsg = ChatMessage(text: errMsg, isUser: false, isError: true);
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isProcessing: false,
      );
    }
  }

  Future<void> _speak(String text, String language) async {
    // 1. Stop any currently playing audio
    await stopTts();

    try {
      // 2. Attempt high-quality ElevenLabs TTS from backend
      final response = await ref.read(apiClientProvider).post(
        ApiEndpoints.assistantTts,
        data: {'text': text, 'language': language},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(List<int>.from(response.data));
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/assistant_voice.mp3');
        await audioFile.writeAsBytes(bytes, flush: true);

        await _audioPlayer.stop();
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(DeviceFileSource(audioFile.path));
        return;
      }
    } catch (e) {
      debugPrint('[Assistant Voice] Backend TTS fallback: $e');
    }

    // 3. Fallback to on-device TTS engine
    try {
      await _flutterTts.setLanguage(language == 'ta' ? 'ta-IN' : 'en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('[Assistant Voice] FlutterTts error: $e');
    }
  }
  
  Future<void> playTts(String text) async {
      final lang = ref.read(languageProvider);
      await _speak(text, lang);
  }
  
  Future<void> stopTts() async {
      await _audioPlayer.stop();
      await _flutterTts.stop();
  }

  // Custom dispose functionality should be handled differently in Notifier
  // if needed, such as overriding onDispose in ref 
  // For now, these are not strictly necessary to cancel since they live for the app lifecycle.
}
