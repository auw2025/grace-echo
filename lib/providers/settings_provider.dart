import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isHighContrast = false;

  bool get isHighContrast => _isHighContrast;

  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isHighContrast = prefs.getBool('highContrastMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleHighContrast(bool value) async {
    _isHighContrast = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrastMode', _isHighContrast);
    notifyListeners();
  }
}