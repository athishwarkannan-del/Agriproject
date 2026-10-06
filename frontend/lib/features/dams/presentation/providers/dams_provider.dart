import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../onboarding/presentation/providers/language_provider.dart';

class DamData {
  final String name;
  final String level;
  final String capacity;
  final String inflow;
  final String outflow;
  final double percentage;

  DamData({
    required this.name,
    required this.level,
    required this.capacity,
    required this.inflow,
    required this.outflow,
    required this.percentage,
  });

  factory DamData.fromJson(Map<String, dynamic> json) {
    return DamData(
      name: json['name'] ?? '',
      level: json['level'] ?? '',
      capacity: json['capacity'] ?? '',
      inflow: json['inflow'] ?? '',
      outflow: json['outflow'] ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class DamsState {
  final List<DamData> dams;
  final bool isLoading;
  final String? error;

  DamsState({
    this.dams = const [],
    this.isLoading = false,
    this.error,
  });

  DamsState copyWith({
    List<DamData>? dams,
    bool? isLoading,
    String? error,
  }) {
    return DamsState(
      dams: dams ?? this.dams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final damsProvider = NotifierProvider<DamsNotifier, DamsState>(DamsNotifier.new);

class DamsNotifier extends Notifier<DamsState> {
  @override
  DamsState build() {
    // Automatically fetch when initialized
    Future.microtask(() => fetchDamsData());
    return DamsState();
  }

  Future<void> fetchDamsData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final lang = ref.read(languageProvider);
      final response = await ref.read(apiClientProvider).get(
        ApiEndpoints.dams,
        queryParameters: {'language': lang},
      );
      
      final List<dynamic> rawData = response.data['data'] ?? [];
      final damsList = rawData.map((d) => DamData.fromJson(d)).toList();
      
      state = state.copyWith(
        dams: damsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dam data. Please check your connection.',
      );
    }
  }
}
