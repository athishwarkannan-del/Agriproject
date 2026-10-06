import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';

final languageProvider = NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    _loadLanguage();
    return AppConstants.defaultLanguage;
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(AppConstants.keyLanguage);
    if (lang != null) {
      state = lang;
    }
  }

  Future<void> setLanguage(String languageCode) async {
    state = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, languageCode);
  }
}
