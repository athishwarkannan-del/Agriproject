import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
  
  static String get apiVersion => '/api/v1';
  static String get baseApiUrl => '$baseUrl$apiVersion';

  // Auth
  static String get login => '$baseApiUrl/auth/login';
  static String get register => '$baseApiUrl/auth/register';
  
  // Assistant
  static String get assistantQuery => '$baseApiUrl/assistant/query';
  
  // Profile
  static String get profile => '$baseApiUrl/farmer/profile';
  
  // Data
  static String get dams => '$baseApiUrl/dams';
  static String get weather => '$baseApiUrl/weather';
  static String get weatherForecast => '$baseApiUrl/weather/forecast';
  static String get crops => '$baseApiUrl/crops';
  
  // Disease
  static String get diseaseAnalyze => '$baseApiUrl/disease/analyze';
}
