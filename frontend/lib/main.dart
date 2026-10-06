import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("dotenv load warning: $e");
  }

  // Initialize Supabase safely
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (supabaseUrl != null && 
        supabaseAnonKey != null && 
        supabaseUrl.isNotEmpty && 
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains("localhost:54321") &&
        supabaseAnonKey != "your_anon_key_here") {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } else {
      debugPrint("Warning: Supabase credentials bypassed for Dev Mode");
    }
  } catch (e) {
    debugPrint("Supabase init bypassed: $e");
  }

  // Initialize Hive for local storage/caching
  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint("Hive init warning: $e");
  }

  runApp(
    const ProviderScope(
      child: HarvestLinkApp(),
    ),
  );
}

class HarvestLinkApp extends StatelessWidget {
  const HarvestLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HarvestLink',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
