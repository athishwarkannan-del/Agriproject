import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harvestlink/core/constants/api_endpoints.dart';
import 'package:harvestlink/core/network/api_client.dart';
import 'package:harvestlink/core/theme/app_colors.dart';
import 'package:harvestlink/features/onboarding/presentation/providers/language_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/weather_scene.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? forecastData;
  final TextEditingController _locationController = TextEditingController(text: 'Salem');

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() { isLoading = true; error = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _fetchWeather('Salem');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _fetchWeather('Salem');
      }
      
      if (permission == LocationPermission.deniedForever) return _fetchWeather('Salem');

      Position position = await Geolocator.getCurrentPosition();
      await _fetchWeatherByCoords(position.latitude, position.longitude);
    } catch (e) {
      _fetchWeather('Salem');
    }
  }

  Future<void> _fetchWeatherByCoords(double lat, double lon) async {
    try {
      setState(() { isLoading = true; error = null; });
      final dio = ref.read(apiClientProvider);
      
      final weatherRes = await dio.get(ApiEndpoints.weather, queryParameters: {'lat': lat, 'lon': lon});
      final forecastRes = await dio.get(ApiEndpoints.weatherForecast, queryParameters: {'lat': lat, 'lon': lon, 'days': 5});
      
      setState(() {
        weatherData = weatherRes.data;
        forecastData = forecastRes.data;
        _locationController.text = weatherData?['location'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = "Failed to load weather data.";
      });
    }
  }

  Future<void> _fetchWeather(String location) async {
    try {
      setState(() { isLoading = true; error = null; });
      final dio = ref.read(apiClientProvider);
      
      // Fetch current weather and 5-day forecast for the given location
      final weatherRes = await dio.get(ApiEndpoints.weather, queryParameters: {'location': location});
      final forecastRes = await dio.get(ApiEndpoints.weatherForecast, queryParameters: {'location': location, 'days': 5});
      
      setState(() {
        weatherData = weatherRes.data;
        forecastData = forecastRes.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = "Failed to load weather data. Please check connection.";
      });
    }
  }

  WeatherSceneMode _determineMode(String? condition) {
    if (condition != null) {
      final condLower = condition.toLowerCase();
      if (condLower.contains('rain') || condLower.contains('drizzle') || condLower.contains('thunderstorm')) {
        return WeatherSceneMode.rain;
      }
    }
    
    // Fallback to time-based
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 8) return WeatherSceneMode.dawn;
    if (hour >= 8 && hour < 16) return WeatherSceneMode.day;
    if (hour >= 16 && hour < 19) return WeatherSceneMode.dusk;
    return WeatherSceneMode.night;
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(languageProvider) == 'ta';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(isTamil ? 'வானிலை' : 'Weather', style: const TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.turmeric,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : error != null 
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Search Bar
                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: isTamil ? 'உங்கள் ஊரை தேடுங்கள் (உம். Salem)' : 'Search your city (e.g. Salem)',
                          prefixIcon: const Icon(Icons.search, color: AppColors.ink),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.my_location, color: AppColors.leaf),
                                onPressed: _initLocation,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () => _fetchWeather(_locationController.text),
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.ink),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.turmeric, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.card,
                        ),
                        onSubmitted: (value) => _fetchWeather(value),
                      ),
                      const SizedBox(height: 16),
                      // Animated Weather Scene
                      WeatherScene(
                        mode: _determineMode(weatherData?['weather_condition']),
                        temperature: "${weatherData?['temperature_celsius'] ?? '--'}°C",
                        description: "${weatherData?['location'] ?? 'Unknown'} • ${weatherData?['weather_condition'] ?? 'Loading'}",
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isTamil ? "5 நாள் முன்னறிவிப்பு" : "5-Day Forecast", 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)
                      ),
                      const SizedBox(height: 12),
                      // Forecast List
                      ...((forecastData?['forecast'] as List?) ?? []).map((day) => Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${day['date']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text("${day['weather_condition']}", style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("${day['temperature_max']}° / ${day['temperature_min']}°", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.water_drop, size: 14, color: Colors.blue),
                                      Text(" ${day['rainfall_mm']}mm", style: const TextStyle(color: Colors.grey)),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
    );
  }
}

class _WeatherMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WeatherMetric({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.ink.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.ink.withOpacity(0.7))),
      ],
    );
  }
}
