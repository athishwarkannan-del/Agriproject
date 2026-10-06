import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../onboarding/presentation/providers/language_provider.dart';

class DiseaseState {
  final XFile? selectedImage;
  final bool isAnalyzing;
  final String? error;
  final Map<String, dynamic>? result;

  DiseaseState({
    this.selectedImage,
    this.isAnalyzing = false,
    this.error,
    this.result,
  });

  DiseaseState copyWith({
    XFile? selectedImage,
    bool? isAnalyzing,
    String? error,
    Map<String, dynamic>? result,
    bool clearResult = false,
  }) {
    return DiseaseState(
      selectedImage: selectedImage ?? this.selectedImage,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

final diseaseProvider = NotifierProvider<DiseaseNotifier, DiseaseState>(DiseaseNotifier.new);

class DiseaseNotifier extends Notifier<DiseaseState> {
  final ImagePicker _picker = ImagePicker();

  @override
  DiseaseState build() {
    return DiseaseState();
  }

  Future<void> pickImage(ImageSource source) async {
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
    state = DiseaseState();
  }

  Future<void> analyzeImage() async {
    if (state.selectedImage == null) return;

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
