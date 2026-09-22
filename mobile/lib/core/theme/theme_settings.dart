import 'package:flutter/material.dart';
import '../storage/local_storage.dart';

class ThemeSettings {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static Future<void> load() async {
    mode.value = await LocalStorage.getBool('dark_mode') == true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static bool get isDark => mode.value == ThemeMode.dark;

  static Future<void> setDark(bool value) async {
    mode.value = value ? ThemeMode.dark : ThemeMode.light;
    await LocalStorage.setBool('dark_mode', value);
  }
}
